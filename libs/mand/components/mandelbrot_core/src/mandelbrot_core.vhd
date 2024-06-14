library ieee;
library mand;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Algorithm:
-- https://en.wikipedia.org/wiki/Mandelbrot_set
--
--   x0 - real part of the initial value
--   y0 - imaginary part of the initial value
--
--     x := 0.0
--     y := 0.0
--     iteration := 0
--     max_iteration := 1000
--
--     while (                                                                  # while_check_start
--              x^2 +                                                           # square_x
--              y^2 ≤                                                           # square_y
--              2^2 AND iteration < max_iteration)                              # while_check_end
--     do                 
--
--         xtemp := x^2 - y^2 + x0                                              # loop_body
--         y := 2*x*y + y0
--         x := xtemp                                            
--         iteration := iteration + 1

entity mandelbrot_core is
    generic (
        FIXED_SIZE : natural := 128; -- Size of the input i_x and i_y values
        FIXED_INTEGER_SIZE : natural := 4; -- Fixed floating point integer bits for the i_x and i_y inputs

        ITTERATIONS_SIZE : natural := 64 -- Size of the output iterations value (unsigned long by default)
    );
    port (
        clk : in std_logic;
        sync_reset : in std_logic;

        -- Inputs

        -- start new calculation:
        -- - reset the state machine
        -- - loads the x, y and max_iterations values
        -- - starts the calculation
        i_start : in std_logic;

        i_x : in signed(FIXED_SIZE - 1 downto 0);
        i_y : in signed(FIXED_SIZE - 1 downto 0);
        i_iterations_max : in unsigned(ITTERATIONS_SIZE - 1 downto 0);

        -- Outputs
        o_result : out unsigned(ITTERATIONS_SIZE - 1 downto 0);

        -- Core is busy when calculation is in progress
        o_busy : out std_logic;
        -- when calculation is done done_status is high and the result can be read
        o_valid : out std_logic
    );
end entity;

architecture RTL of mandelbrot_core is
    -- Loop state type
    type t_loop_state is (s_idle, s_idle_load, s_while_check_start, s_start_mult_x, s_wait_mult_x_load_mult_y, s_start_mult_y, s_wait_mult_y, s_wait_square_y, s_while_check_end, s_start_mult_x_y, s_wait_mult_x_y, s_wait_x_y_load, s_done, s_done_wait);

    -- Constants
    constant BOUND_RANGE : signed(i_x'range) := to_signed(4, FIXED_INTEGER_SIZE) & to_signed(0, FIXED_SIZE - FIXED_INTEGER_SIZE);

    -- Loop
    signal loop_state_reg, loop_state_next : t_loop_state := s_idle;
    signal max_iterations_reg, max_iterations_next : unsigned(i_iterations_max'range) := (others => '0');
    signal iterations_reg, iterations_next : unsigned(i_iterations_max'range) := (others => '0');

    -- Multiplier 
    signal mult_start_reg, mult_start_next : std_logic := '0';
    signal mult_x_reg, mult_x_next : signed(i_x'range) := (others => '0');
    signal mult_y_reg, mult_y_next : signed(i_y'range) := (others => '0');
    signal mult_overflow_reg : std_logic := '0';

    signal mult_out_reg : signed(i_x'range) := (others => '0');
    signal mult_busy_reg : std_logic := '0';
    signal mult_valid_reg : std_logic := '0';

    -- Algorithm
    signal x0_reg, x0_next, y0_reg, y0_next : signed(i_x'range) := (others => '0');
    signal x_reg, x_next, y_reg, y_next : signed(i_x'range) := (others => '0');
    signal x_temp_reg, x_temp_next : signed(i_x'range) := (others => '0');
    signal x_squared_reg, x_squared_next : signed(i_y'range) := (others => '0');
    signal y_squared_reg, y_squared_next : signed(i_y'range) := (others => '0');
    signal mult_overflow_flag_reg, mult_overflow_flag_next : std_logic := '0';

    -- Output buffers
    signal result_reg, result_next : unsigned(o_result'range) := (others => '0');
    signal busy_reg, busy_next : std_logic := '0';
    signal valid_reg, valid_next : std_logic := '0';

begin
    -- Registers
    process (clk)
    begin
        if rising_edge(clk) then
            if sync_reset = '1' then
                -- Reset
                loop_state_reg <= s_idle;
                max_iterations_reg <= (others => '0');
                iterations_reg <= (others => '0');

                mult_start_reg <= '0';
                mult_x_reg <= (others => '0');
                mult_y_reg <= (others => '0');

                x0_reg <= (others => '0');
                y0_reg <= (others => '0');
                x_reg <= (others => '0');
                y_reg <= (others => '0');
                x_temp_reg <= (others => '0');
                x_squared_reg <= (others => '0');
                y_squared_reg <= (others => '0');
                mult_overflow_flag_reg <= '0';

                result_reg <= (others => '0');
                busy_reg <= '0';
                valid_reg <= '0';
            else
                -- Loop
                loop_state_reg <= loop_state_next;
                max_iterations_reg <= max_iterations_next;
                iterations_reg <= iterations_next;

                -- Multiplier buffers
                mult_start_reg <= mult_start_next;
                mult_x_reg <= mult_x_next;
                mult_y_reg <= mult_y_next;

                -- Algorithm
                x0_reg <= x0_next;
                y0_reg <= y0_next;
                x_reg <= x_next;
                y_reg <= y_next;
                x_temp_reg <= x_temp_next;
                x_squared_reg <= x_squared_next;
                y_squared_reg <= y_squared_next;
                mult_overflow_flag_reg <= mult_overflow_flag_next;

                -- Outputs
                result_reg <= result_next;
                busy_reg <= busy_next;
                valid_reg <= valid_next;
            end if;
        end if;
    end process;

    MULT_BLOCK : entity mand.multiply_block
        generic map(
            FIXED_SIZE => FIXED_SIZE,
            FIXED_INTEGER_SIZE => FIXED_INTEGER_SIZE
        )
        port map(
            clk => clk,
            sync_reset => sync_reset,
            i_start => mult_start_reg,

            i_x => mult_x_reg,
            i_y => mult_y_reg,

            o_result => mult_out_reg,
            o_busy => mult_busy_reg,
            o_valid => mult_valid_reg,
            o_int_overflow => mult_overflow_reg
        );

    -- Main loop state machine
    process (clk, sync_reset, i_start, i_x, i_y, i_iterations_max, mult_start_reg, mult_valid_reg, mult_busy_reg, mult_out_reg, mult_overflow_flag_reg, x_squared_reg, y_squared_reg, x0_reg, y0_reg, x_reg, y_reg, iterations_reg, x_temp_reg, result_reg, busy_reg, valid_reg)
    begin
        -- default
        mult_start_next <= '0';
        mult_x_next <= mult_x_reg;
        mult_y_next <= mult_y_reg;

        loop_state_next <= loop_state_reg;
        x0_next <= x0_reg;
        y0_next <= y0_reg;
        max_iterations_next <= max_iterations_reg;
        x_next <= x_reg;
        y_next <= y_reg;
        iterations_next <= iterations_reg;
        x_temp_next <= x_temp_reg;
        x_squared_next <= x_squared_reg;
        y_squared_next <= y_squared_reg;
        mult_overflow_flag_next <= mult_overflow_flag_reg;

        result_next <= result_reg;
        busy_next <= busy_reg;
        valid_next <= valid_reg;

        case loop_state_reg is
            when s_idle =>

                if i_start = '1' then
                    -- Load inputs
                    x0_next <= i_x;
                    y0_next <= i_y;

                    max_iterations_next <= i_iterations_max;

                    -- Load initial values
                    x_next <= (others => '0');
                    y_next <= (others => '0');
                    iterations_next <= (others => '0');

                    -- Reset outputs
                    result_next <= (others => '0');

                    -- Set status flags
                    busy_next <= '1';
                    valid_next <= '0';
                    mult_overflow_flag_next <= '0';

                    -- Start calculation
                    loop_state_next <= s_idle_load;
                end if;

            when s_idle_load =>
                -- Wait for inputs to load
                loop_state_next <= s_while_check_start;

            when s_while_check_start =>
                -- Load x^2 multiplication
                mult_x_next <= x_reg;
                mult_y_next <= x_reg;

                loop_state_next <= s_start_mult_x;

            when s_start_mult_x =>
                -- Start current multiplication
                mult_start_next <= '1';

                loop_state_next <= s_wait_mult_x_load_mult_y;

            when s_wait_mult_x_load_mult_y =>
                -- Wait for multiplication to start and finish
                if mult_start_reg = '0' and mult_valid_reg = '1' and mult_busy_reg = '0' then
                    -- Save x^2
                    x_squared_next <= mult_out_reg;

                    -- Update multiplication overflow flag
                    mult_overflow_flag_next <= mult_overflow_flag_reg or mult_overflow_reg;

                    -- Load y^2 multiplication
                    mult_x_next <= y_reg;
                    mult_y_next <= y_reg;

                    loop_state_next <= s_start_mult_y;
                end if;

            when s_start_mult_y =>
                -- Start current multiplication
                mult_start_next <= '1';

                loop_state_next <= s_wait_mult_y;

            when s_wait_mult_y =>
                -- Wait for multiplication to start and finish
                if mult_start_reg = '0' and mult_valid_reg = '1' and mult_busy_reg = '0' then
                    -- Save y^2
                    y_squared_next <= mult_out_reg;

                    -- Update multiplication overflow flag
                    mult_overflow_flag_next <= mult_overflow_flag_reg or mult_overflow_reg;

                    loop_state_next <= s_wait_square_y;
                end if;

            when s_wait_square_y =>
                -- Wait for y_squared to load
                loop_state_next <= s_while_check_end;

            when s_while_check_end =>

                -- Check if the current point is inbounds and the iteration limit is not reached
                if (x_squared_reg + y_squared_reg <= BOUND_RANGE) and
                    (iterations_reg < max_iterations_reg) and
                    (mult_overflow_flag_reg = '0')
                    then
                    -- Save x_temp = x^2 - y^2 + x0
                    x_temp_next <= x_squared_reg - y_squared_reg + x0_reg;

                    -- Load x * y
                    mult_x_next <= x_reg;
                    mult_y_next <= y_reg;

                    loop_state_next <= s_start_mult_x_y;
                else
                    loop_state_next <= s_done;
                end if;

            when s_start_mult_x_y =>
                -- Start current multiplication
                mult_start_next <= '1';

                loop_state_next <= s_wait_mult_x_y;

            when s_wait_mult_x_y =>

                -- Wait for multiplication to finish multiplication
                if mult_start_reg = '0' and mult_valid_reg = '1' and mult_busy_reg = '0' then
                    y_next <= (mult_out_reg sll 1) + y0_reg;
                    x_next <= x_temp_reg;

                    iterations_next <= iterations_reg + 1;

                    -- Update multiplication overflow flag
                    mult_overflow_flag_next <= mult_overflow_flag_reg or mult_overflow_reg;

                    loop_state_next <= s_wait_x_y_load;
                end if;

            when s_wait_x_y_load =>
                -- Wait for x and y to load
                loop_state_next <= s_while_check_start;

            when s_done =>
                -- Calculation is done, save the result and set the status flags
                result_next <= iterations_reg;

                loop_state_next <= s_done_wait;

            when s_done_wait =>
                busy_next <= '0';
                valid_next <= '1';

                loop_state_next <= s_idle;
        end case;

    end process;

    -- Output
    o_result <= result_reg;
    o_busy <= busy_reg;
    o_valid <= valid_reg;
end architecture;