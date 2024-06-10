library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mandelbrot_cluser is
    generic (
        FIXED_INTEGER_BITS : natural := 4; -- Fixed floating point integer bits for the i_x and i_y inputs
        INPUT_RESOLUTION : natural := 32; -- Size of the input i_x and i_y values

        ITERATIONS_RESOLUTION : natural := 64 -- Size of the output iterations value (unsigned long by default)
        CORES_COUNT : natural := 1 -- Number of cores to use
    );
    port (
        clk : in std_logic;

    );
end entity;

architecture RTL of mandelbrot_cluser is

begin

end architecture;