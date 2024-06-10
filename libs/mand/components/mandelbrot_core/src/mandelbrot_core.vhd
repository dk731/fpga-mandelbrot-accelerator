library ieee;
library mand;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Algorithm:
-- https://en.wikipedia.org/wiki/Mandelbrot_set

entity mandelbrot_core is
    generic (
        INPUT_RESOLUTION : natural := 32;
        ITERATIONS_RESOLUTION : natural := 64 -- long unsigned
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
        o_done_status : out std_logic
    );
end entity;

architecture RTL of mandelbrot_core is
    type t_loop_state is (s_idle, s_done);

    -- Loop
    signal loop_state_reg, loop_state_next : t_loop_state := s_idle;
    signal result_reg, result_next : unsigned(o_result'range) := (others => '0');
    signal done_reg, done_next : std_logic := '0';

    signal max_iterations_reg, max_iterations_next : unsigned(i_iterations_max'range) := (others => '0');
    signal iterations_reg, iterations_next : unsigned(i_iterations_max'range) := (others => '0');

    -- Multiplier 
    signal mult_start_reg, mult_start_next : std_logic := '0';
    signal mult_x_reg, mult_x_next : signed(i_x'range) := (others => '0');
    signal mult_y_reg, mult_y_next : signed(i_y'range) := (others => '0');

    signal mult_out_reg : signed(i_x'range) := (others => '0');
    signal mult_valid_reg : std_logic := '0';

    -- Algorithm 
    signal x_reg, x_next, y_reg, y_next : signed(i_x'range) := (others => '0');
    signal x_temp_reg, x_temp_next : signed(i_x'range) := (others => '0');
    signal x_squared_reg, x_squared_next : signed(i_y'range) := (others => '0');
    signal y_squared_reg, y_squared_next : signed(i_y'range) := (others => '0');
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
            loop_state_reg <= loop_state_next;
            result_reg <= result_next;
            done_reg <= done_next;

            max_iterations_reg <= max_iterations_next;
            iterations_reg <= iterations_next;

            x_temp_reg <= x_temp_next;
            x_squared_reg <= x_squared_next;
            y_squared_reg <= y_squared_next;
        end if;
    end process;

    -- Main loop state machine
    process (all)
    begin
        -- default
        loop_state_next <= loop_state_reg;

        x_next <= x_reg;
        y_next <= y_reg;

        if sync_reset = '1' then
            -- Reset state machine
            loop_state_next <= s_idle;

            -- Reset outputs
            result_next <= (others => '0');
            done_next <= '0';

        else
            case loop_state_reg is
                when s_idle =>

                    if i_start = '1' then
                        x_next <= (others => '0');
                        y_next <= (others => '0');
                        max_iterations_next <= i_iterations_max;
                        iterations_next <= (others => '0');
                        loop_state_next <= s_done;
                    end if;

                when others =>
                    null;
            end case;
        end if;
    end process;

    -- Output
    o_result <= result_reg;
    o_done_status <= done_reg;
end architecture;