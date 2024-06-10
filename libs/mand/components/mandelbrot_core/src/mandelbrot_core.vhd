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
        FIXED_INTEGER_BITS : natural := 4; -- Fixed floating point integer bits for the i_x and i_y inputs
        INPUT_RESOLUTION : natural := 512; -- Size of the input i_x and i_y values

        ITERATIONS_RESOLUTION : natural := 64 -- Size of the output iterations value (unsigned long by default)
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

        i_x : in signed(INPUT_RESOLUTION - 1 downto 0);
        i_y : in signed(INPUT_RESOLUTION - 1 downto 0);
        i_iterations_max : in unsigned(ITERATIONS_RESOLUTION - 1 downto 0);

        -- Outputs
        o_result : out unsigned(ITERATIONS_RESOLUTION - 1 downto 0);

        -- when calculation is done done_status is high and the result can be read
        o_valid : out std_logic
    );
end entity;

architecture RTL of mandelbrot_core is
    -- Loop state type
    type t_loop_state is (s_idle, while_check_start, square_x, square_y, while_check_end, loop_body, s_done);

    -- Constants
    constant BOUND_RANGE : signed(i_x'range) := to_signed(4, FIXED_INTEGER_BITS) & to_signed(0, INPUT_RESOLUTION - FIXED_INTEGER_BITS);

    -- Loop
    signal loop_state_reg, loop_state_next : t_loop_state := s_idle;
    signal max_iterations_reg, max_iterations_next : unsigned(i_iterations_max'range) := (others => '0');
    signal iterations_reg, iterations_next : unsigned(i_iterations_max'range) := (others => '0');

    -- Multiplier 
    signal mult_start_reg, mult_start_next : std_logic := '0';
    signal mult_x_reg, mult_x_next : signed(i_x'range) := (others => '0');
    signal mult_y_reg, mult_y_next : signed(i_y'range) := (others => '0');

    signal mult_out_reg : signed(i_x'range) := (others => '0');
    signal mult_valid_reg : std_logic := '0';

    -- Algorithm
    signal x0_reg, x0_next, y0_reg, y0_next : signed(i_x'range) := (others => '0');
    signal x_reg, x_next, y_reg, y_next : signed(i_x'range) := (others => '0');
    signal x_temp_reg, x_temp_next : signed(i_x'range) := (others => '0');
    signal x_squared_reg, x_squared_next : signed(i_y'range) := (others => '0');
    signal y_squared_reg, y_squared_next : signed(i_y'range) := (others => '0');

    -- Output buffers
    signal result_reg, result_next : unsigned(o_result'range) := (others => '0');
    signal valid_reg, valid_next : std_logic := '0';

begin
    MULT_BLOCK : entity mand.multiply_block
        generic map(
            INPUT_RESOLUTION => INPUT_RESOLUTION
        )
        port map(
            clk => clk,
            sync_reset => sync_reset,
            i_start => mult_start_reg,

            i_x => mult_x_reg,
            i_y => mult_y_reg,

            o_result => mult_out_reg,
            o_valid => mult_valid_reg
        );

    -- Registers
    process (clk)
    begin
        if rising_edge(clk) then
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

            -- Outputs
            result_reg <= result_next;
            valid_reg <= valid_next;
        end if;
    end process;

    -- Main loop state machine
    process (all)
    begin
        -- default
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
        mult_start_next <= mult_start_reg;
        mult_x_next <= mult_x_reg;
        mult_y_next <= mult_y_reg;
        result_next <= result_reg;
        valid_next <= valid_reg;

        if sync_reset = '1' then
            -- Reset state machine
            loop_state_next <= s_idle;

            -- Reset outputs
            result_next <= (others => '0');
            valid_next <= '0';

        else
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
                        valid_next <= '0';

                        -- Start calculation
                        loop_state_next <= while_check_start;
                    end if;

                when while_check_start =>
                    -- Load x^2 and start multiplication
                    mult_x_next <= x_reg;
                    mult_y_next <= x_reg;
                    mult_start_next <= '1';

                    loop_state_next <= square_x;

                when square_x =>

                    if mult_valid_reg = '1' then
                        -- Save x^2
                        x_squared_next <= mult_out_reg;

                        -- Load y^2 and start multiplication
                        mult_x_next <= y_reg;
                        mult_y_next <= y_reg;
                        mult_start_next <= '1';

                        loop_state_next <= square_y;
                    end if;

                    -- TODO: This can be merged to while_check_end
                when square_y =>

                    if mult_valid_reg = '1' then
                        -- Save y^2
                        y_squared_next <= mult_out_reg;

                        loop_state_next <= while_check_end;
                    end if;

                when while_check_end =>

                    if x_squared_reg + y_squared_reg <= BOUND_RANGE and iterations_reg < max_iterations_reg then
                        -- Save x_temp = x^2 - y^2 + x0
                        x_temp_next <= x_squared_reg - y_squared_reg + x0_reg;

                        -- Load x * y
                        mult_x_next <= x_reg;
                        mult_y_next <= y_reg;
                        mult_start_next <= '1';

                        loop_state_next <= loop_body;
                    else
                        loop_state_next <= s_done;
                    end if;

                when loop_body =>

                    -- Wait for x * y multiplication to finish
                    if mult_valid_reg = '1' then
                        -- Save y = 2 * x * y + y0
                        y_next <= (mult_out_reg(mult_out_reg'length - 1 downto 1) & "0") + y0_reg;
                        x_next <= x_temp_reg;
                        iterations_next <= iterations_reg + 1;

                        loop_state_next <= while_check_start;
                    end if;

                when s_done =>
                    -- Calculation is done
                    result_next <= iterations_reg;
                    valid_next <= '1';

                    loop_state_next <= s_idle;

                when others =>
                    null;
            end case;
        end if;
    end process;

    -- Output
    o_result <= result_reg;
    o_valid <= valid_reg;
end architecture;