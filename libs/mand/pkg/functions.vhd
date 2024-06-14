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

    -- vector operations
    function reverse(input : std_logic_vector) return std_logic_vector;
end package;

-- implementations of the package (functions, procedures)
package body functions is
    function log2c(input : integer) return integer is
        variable temp, log : integer;
    begin
        temp := input - 1;
        log := 0;
        while (temp > 0) loop
            temp := temp/2;
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
            temp := temp/2;
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

end package body;