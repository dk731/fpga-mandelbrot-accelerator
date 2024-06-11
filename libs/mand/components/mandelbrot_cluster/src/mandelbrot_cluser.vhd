library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mandelbrot_cluser is
    generic (
        FIXED_INTEGER_SIZE : natural := 4; -- Fixed floating point integer bits for the i_x and i_y inputs
        FIXED_SIZE : natural := 32; -- Size of the input i_x and i_y values

        ITERATIONS_SIZE : natural := 64; -- Size of the output iterations value (unsigned long by default)

        NORMAL_REG_SIZE : natural := 64; -- Size of the normal registers
        CORES_COUNT : natural := 1 -- Number of cores to use
    );
    port (
        clk : in std_logic;

        -- Input values
        i_command : in std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Command register input
        i_address : in std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Address of the mandelbrot core to use

        i_x : in std_logic_vector(FIXED_SIZE - 1 downto 0); -- Real part of the input value to load into the core
        i_y : in std_logic_vector(FIXED_SIZE - 1 downto 0); -- Imaginary part of the input value to load into the core

        -- Output values
        -- Meta data about current FPGA configuration
        o_fixed_integer_size : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Number of fixed bits in the output value
        o_fixed_size : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Resolution of the input values
        o_iterations_size : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Resolution of the output iterations value
        o_cores_count : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Number of cores in the FPGA

        -- Cores status values
        o_core_busy : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- If the core is busy its bit is set
        o_core_valid : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- If the core has valid output its bit is set

        -- Mandelbrot core output values
        -- Read result command with the address of the core to read from will be stored here
        o_iterations : out std_logic_vector(ITERATIONS_SIZE - 1 downto 0) -- Output value of particular mandelbrot core
    );
end entity;

architecture RTL of mandelbrot_cluser is

begin

end architecture;