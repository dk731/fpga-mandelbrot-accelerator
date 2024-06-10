library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiply_block is
    generic (
        INPUT_RESOLUTION : natural := 32
    );
    port (
        clk : in std_logic;

        -- Inputs
        i_x : in signed(INPUT_RESOLUTION downto 0);
        i_y : in signed(INPUT_RESOLUTION downto 0);

        -- Outputs
        o_result : out signed(INPUT_RESOLUTION downto 0)
        o_valid : out std_logic
    );
end entity;

architecture RTL of multiply_block is
    constant MULT_SIZE : natural := INPUT_RESOLUTION * 2 + 1;

    signal mult_res : signed(MULT_SIZE downto 0);
    signal mult_reg, mult_next : signed(INPUT_RESOLUTION downto 0);

begin
    process (clk)
    begin
        if rising_edge(clk) then
            mult_reg <= mult_next;
        end if;
    end process;

    mult_res <= x * y;
    mult_next <= mult_res(MULT_SIZE downto MULT_SIZE - INPUT_RESOLUTION);

    result <= mult_reg;
end architecture;