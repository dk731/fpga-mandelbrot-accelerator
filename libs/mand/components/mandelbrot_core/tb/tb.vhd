library std;
library ieee;
library osvvm;
library vunit_lib;
library mand;

context vunit_lib.vunit_context;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use osvvm.RandomPkg.all;
use vunit_lib.com_pkg.all;

entity tb is
    generic (
        runner_cfg : string;

        FIXED_SIZE : natural := 16; -- Size of the input i_x and i_y values
        FIXED_INTEGER_SIZE : natural := 4; -- Fixed floating point integer bits for the i_x and i_y inputs
        ITERATIONS_SIZE : natural := 64; -- Size of the output iterations value (unsigned long by default)

        INPUT_X : natural := 1; -- X coordinate of the input
        INPUT_Y : natural := 1; -- Y coordinate of the input
        INPUT_ITERATIONS_MAX : natural := 100 -- Maximum number of iterations
    );
end entity;

architecture RTL of tb is
    -----------------------------------------------------------------------------
    -- Constants
    -----------------------------------------------------------------------------
    constant CLK_PERIOD : time := 10 ns;

    -----------------------------------------------------------------------------
    -- DUT interfacing
    -----------------------------------------------------------------------------
    signal clk : std_logic := '0';

    signal core_reset : std_logic := '0';
    signal core_start : std_logic := '0';

    -- Core Inputs
    signal core_x : signed(FIXED_SIZE - 1 downto 0) := (others => '0');
    signal core_y : signed(FIXED_SIZE - 1 downto 0) := (others => '0');
    signal core_iterations_max : unsigned(ITERATIONS_SIZE - 1 downto 0) := (others => '0');

    -- Core Outputs
    signal core_result : unsigned(ITERATIONS_SIZE - 1 downto 0) := (others => '0');
    signal core_busy : std_logic := '0';
    signal core_valid : std_logic := '0';

    constant ZEROS : unsigned(ITERATIONS_SIZE - 1 downto 0) := (others => '0');

begin
    clk <= not clk after CLK_PERIOD/2;

    MAND_CORE : entity mand.mandelbrot_core
        generic map(
            FIXED_SIZE => FIXED_SIZE,
            FIXED_INTEGER_SIZE => FIXED_INTEGER_SIZE,
            ITERATIONS_SIZE => ITERATIONS_SIZE
        )
        port map(
            clk => clk,
            sync_reset => core_reset,

            i_start => core_start,

            i_x => core_x,
            i_y => core_y,
            i_iterations_max => core_iterations_max,

            o_result => core_result,
            o_busy => core_busy,
            o_valid => core_valid
        );

    -----------------------------------------------------------------------------
    -- Test sequencer
    -----------------------------------------------------------------------------
    process
        constant TIMEOUT : time := 1000000000 ns;
        variable timeout_occurred : boolean := false;

        ---------------------------------------------------------------------------
        -- Procedures
        ---------------------------------------------------------------------------

    begin
        test_runner_setup(runner, runner_cfg);

        while test_suite loop
            if run("test_point_calculation") then
                -- Reset core
                core_reset <= '1';
                wait for 50 ns;
                core_reset <= '0';
                wait for 50 ns;

                check(core_result = ZEROS, "Result after reset: ("
                & "Expected: " & to_string(ZEROS) & "; "
                & "Got: " & to_string(core_result) & ")");

                check(core_busy = '0', "Busy after reset: ("
                & "Expected: '0'; "
                & "Got: " & to_string(core_busy) & ")");

                check(core_valid = '0', "Valid after reset: ("
                & "Expected: '0'; "
                & "Got: " & to_string(core_valid) & ")");

                core_x <= to_signed(INPUT_X, FIXED_SIZE);
                core_y <= to_signed(INPUT_Y, FIXED_SIZE);
                core_iterations_max <= to_unsigned(INPUT_ITERATIONS_MAX, ITERATIONS_SIZE);

                wait for 50 ns;

                -- Start core
                core_start <= '1';

                wait for 10 ns;

                check(core_busy = '1', "Busy after start: ("
                & "Expected: '1'; "
                & "Got: " & to_string(core_busy) & ")");

                check(core_valid = '0', "Valid after start: ("
                & "Expected: '0'; "
                & "Got: " & to_string(core_valid) & ")");

                core_start <= '0';

                -- Wait for the core to finish
                wait until (core_busy = '0' and core_valid = '1') or now >= TIMEOUT;
                timeout_occurred := now >= TIMEOUT;

                check(not timeout_occurred, "Timeout occurred during calculation");

                log("%MAND_CORE_RESULT_START%" & to_string(core_result) & "%MAND_CORE_RESULT_END%" & LF);

            end if;
        end loop;

        test_runner_cleanup(runner);
    end process;

end architecture;