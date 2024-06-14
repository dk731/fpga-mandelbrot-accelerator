library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mand_cluster_avalon_mm is
    generic (
        CORES_COUNT : natural := 16; -- Number of cores to use
        FIXED_INTEGER_SIZE : natural := 1; -- Fixed floating point integer bits for the i_x and i_y inputs
        FIXED_SIZE : natural := 2; -- Size of the input i_x and i_y values

        ITERATIONS_SIZE : natural := 2; -- Size of the output iterations value (unsigned long by default)
        NORMAL_REG_SIZE : natural := 32; -- Size of the normal registers
    );
    port (
        clk : in std_logic;
        sync_reset : in std_logic;

        logic
    );
end entity;

architecture RTL of mand_cluster_avalon_mm is
    constant CORE_MM_SIZE : natural :=
begin

end architecture;