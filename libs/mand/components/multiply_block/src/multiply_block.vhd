library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiply_block is
    generic (
        FIXED_SIZE : natural := 32
    );
    port (
        clk : in std_logic;
        sync_reset : in std_logic; -- Synchronous reset, resets the block to idle state

        -- Inputs
        -- Start signal, loads x and y into the block and starts the multiplication
        i_start : in std_logic;

        i_x : in signed(FIXED_SIZE - 1 downto 0);
        i_y : in signed(FIXED_SIZE - 1 downto 0);

        -- Outputs
        o_result : out signed(FIXED_SIZE - 1 downto 0);
        o_busy : out std_logic;
        o_valid : out std_logic
    );
end entity;

architecture RTL of multiply_block is
    constant MULT_SIZE : natural := FIXED_SIZE * 2;
    type t_loop_state is (s_idle, s_mult_logic, s_done);

    signal loop_state_reg, loop_state_next : t_loop_state := s_idle;

    signal x_reg, x_next : signed(i_x'range);
    signal y_reg, y_next : signed(i_y'range);

    signal mult_res : signed(MULT_SIZE - 1 downto 0);
    signal result_reg, result_next : signed(o_result'range);
    signal busy_reg, busy_next : std_logic;
    signal valid_reg, valid_next : std_logic;
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if sync_reset = '1' then
                loop_state_reg <= s_idle;

                x_reg <= (others => '0');
                y_reg <= (others => '0');

                result_reg <= (others => '0');
                busy_reg <= '0';
                valid_reg <= '0';
            else
                loop_state_reg <= loop_state_next;

                x_reg <= x_next;
                y_reg <= y_next;

                result_reg <= result_next;
                busy_reg <= busy_next;
                valid_reg <= valid_next;
            end if;
        end if;
    end process;

    process (all)
    begin
        -- default
        loop_state_next <= loop_state_reg;
        x_next <= x_reg;
        y_next <= y_reg;
        result_next <= result_reg;
        busy_next <= busy_reg;
        valid_next <= valid_reg;

        case loop_state_reg is
            when s_idle =>

                if i_start = '1' then
                    -- Load input values
                    x_next <= i_x;
                    y_next <= i_y;

                    -- Reset result
                    result_next <= (others => '0');

                    -- Set status flags
                    busy_next <= '1';
                    valid_next <= '0';

                    loop_state_next <= s_mult_logic;
                end if;

            when s_mult_logic =>
                -- THIS CAN BE CHANGED TO OTHER MULTIPLICATION ALGORITHMS

                -- <Basic Multiplication>
                result_next <= mult_res(MULT_SIZE - 1 downto MULT_SIZE - FIXED_SIZE);
                loop_state_next <= s_done;
                -- </Basic Multiplication>

            when s_done =>
                busy_next <= '0';
                valid_next <= '1';

                loop_state_next <= s_idle;

            when others =>
                null;
        end case;

    end process;

    mult_res <= x_reg * y_reg;

    -- Output
    o_result <= result_reg;
    o_busy <= busy_reg;
    o_valid <= valid_reg;
end architecture;