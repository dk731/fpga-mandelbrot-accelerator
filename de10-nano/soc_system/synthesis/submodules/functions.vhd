--------------------------------------------------------------------------------
--! @file functions.vhd
-- Original: https://gitlab.com/rihards.novickis/rtu_rea712/-/raw/main/libs/rtu/pkg/functions.vhd?ref_type=heads
-- Author: Rihards Novickis
--------------------------------------------------------------------------------

-- libraries and packages
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- declarations of the package (types, prototypes of functions and procedures)
package functions is
    -- logarithmic functions
    function log2c (input : integer) return integer;
    function log2f (input : integer) return integer;
    function div_ceil(a : natural; b : natural) return natural;

    -- vector operations
    function reverse(input : std_logic_vector) return std_logic_vector;

    -- Mandelbrot specific functions
    function calculate_avalon_addr_width(cores_count : natural; fixed_size : natural; itterations_size : natural; flag_size : natural) return natural;
end package;

-- implementations of the package (functions, procedures)
package body functions is
    function log2c(input : integer) return integer is
        variable temp, log : integer;
    begin
        temp := input - 1;
        log := 0;
        while (temp > 0) loop
            temp := temp / 2;
            log := log + 1;
        end loop;
        return log;
    end function;

    function log2f(input : integer) return integer is
        variable temp, log : integer;
    begin
        temp := input;
        log := 0;
        while (temp > 1) loop
            temp := temp / 2;
            log := log + 1;
        end loop;
        return log;
    end function;

    function reverse(input : std_logic_vector) return std_logic_vector is
        variable output : std_logic_vector(input'range);
    begin
        for i in input'low to input'high loop
            output(output'high - i) := input(i);
        end loop;
        return output;
    end function;

    function div_ceil(a : natural; b : natural) return natural is
        variable result : natural;
    begin
        result := (a + b - 1) / b;
        return result;
    end function;

    function calculate_avalon_addr_width(cores_count : natural; fixed_size : natural; itterations_size : natural; flag_size : natural) return natural is
        variable result : natural;
        variable core_mm_size_bits : natural;
        variable core_mm_size_bytes : natural;
        variable cluster_mm_size_bytes : natural;

    begin

        core_mm_size_bits :=
            flag_size + --              - i_start
            flag_size + --              - o_done
            flag_size + --              - o_valid
            fixed_size + --             - i_x
            fixed_size + --             - i_y
            itterations_size + --       - i_iterations_max
            itterations_size; --        - o_iterations

        core_mm_size_bytes := div_ceil(core_mm_size_bits, 8);
        cluster_mm_size_bytes := core_mm_size_bytes * cores_count;

        result := log2c(cluster_mm_size_bytes);

        return result;
    end function;

end package body;