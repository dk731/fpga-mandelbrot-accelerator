library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mand_cluster_avalon_mm_interface is
    generic (
        CORES_COUNT : natural := 16; -- Number of cores to use
        FIXED_INTEGER_SIZE : natural := 1; -- Fixed floating point integer bits for the i_x and i_y inputs
        FIXED_SIZE : natural := 2; -- Size of the input i_x and i_y values

        ITERATIONS_SIZE : natural := 2; -- Size of the output iterations value (unsigned long by default)
        NORMAL_REG_SIZE : natural := 32; -- Size of the normal registers
        CORES_STATUS_SIZE : natural := 512 -- Size of registers that hold the status of all cores (should be at least CORES_COUNT bits long)
    );
    port (
        clk : in std_logic;
        sync_reset : in std_logic;

        logic
    );
end entity;

architecture RTL of mand_cluster_avalon_mm_interface is
begin

end architecture;