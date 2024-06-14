library ieee;
library mand;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use mand.functions.all;

entity mand_cluster_avalon_mm is
    generic (
        -- Cluster configuration
        CORES_COUNT : natural := 4; -- Number of cores to use

        -- Each Mandelbrot core configuration
        FIXED_SIZE : natural := 32; -- Size of the input i_x and i_y values
        FIXED_INTEGER_SIZE : natural := 5; -- Fixed point integer bits for the i_x and i_y inputs
        ITTERATIONS_SIZE : natural := 32; -- Size of the output iterations value (unsigned long by default)

        -- Avalon-MM configuration
        constant AVALON_DATA_WIDTH : natural := 64; -- Avalon-MM data width

        constant NORMAL_REG_SIZE : natural := 32 -- Dont change this, or driver will have to be compiled
    );
    port (
        clk : in std_logic;
        sync_reset : in std_logic;

        -- Avalon-MM slave interface
        avs_address : in std_logic_vector(10 - 1 downto 0);

        avs_read : in std_logic;
        avs_write : in std_logic;
        avs_writedata : in std_logic_vector(AVALON_DATA_WIDTH - 1 downto 0);
        avs_readdata : out std_logic_vector(AVALON_DATA_WIDTH - 1 downto 0);
        avs_byteenable : in std_logic_vector((AVALON_DATA_WIDTH / 8) - 1 downto 0)
    );
end entity;

-- Avalon-MM Control Commands:
-- 0x00 - No operation
-- 0x01 - Load outputs from <core_address> core to output registers: <active_core_o_result>, <core_o_busy>, <core_o_valid>
-- 0x02 - Trigger start calculation on <core_address> core with <core_i_x>, <core_i_y>, <core_i_itterations_max> inputs
-- 0x03 - Trigger reset on <core_address> core

-- Command Statuses:
-- 0x00 - Success
-- 0x01 - Busy
-- 0x02 - Invalid command
-- 0x03 - Invalid core address
-- 0x04 - Attempt to start calculation on busy core (request ignored)

-- HPC Memory-Mapped Mandelbrot Cluster
--  - Meta data registers: (
--      CORES_COUNT,                    - RO, size: NORMAL_REG_SIZE
--      FIXED_SIZE,                     - RO, size: NORMAL_REG_SIZE
--      FIXED_INTEGER_SIZE,             - RO, size: NORMAL_REG_SIZE
--      ITTERATIONS_SIZE,               - RO, size: NORMAL_REG_SIZE
--      CORES_STATUS_REG_SIZE           - RO, size: NORMAL_REG_SIZE, Describes size of <cores_busy_flag> and <cores_valid_flag> registers
--    )
--   each value is unsigned integer.
--
-- 
--  - Control registers: (
--      command,                        - RW, size: NORMAL_REG_SIZE
--      command_status,                 - RO, size: NORMAL_REG_SIZE
--      core_address,                   - RW, size: NORMAL_REG_SIZE
--      cores_busy_flag,                - RO, size: CORES_STATUS_REG_SIZE
--      cores_valid_flag                - RO, size: CORES_STATUS_REG_SIZE
--    )
--   Command register will store last executed command. Command will be executed on <command> register write.
--   Command status will store status of last executed command.
--
-- 
--  - Cores input registers: (
--      core_x,                         - RW, size: FIXED_SIZE
--      core_y,                         - RW, size: FIXED_SIZE
--      core_itterations_max            - RW, size: ITTERATIONS_SIZE
--    )
--   Here will be stored input values, which are currently connected to core with <core_address> address.
-- 
--
--  - Cores output registers: (
--      core_result,                    - RO, size: ITTERATIONS_SIZE
--      core_busy,                      - RO, size: NORMAL_REG_SIZE
--      core_valid                      - RO, size: NORMAL_REG_SIZE
--    )
--   Here will be stored output values from the last read command.

-- For register write operation violation (for example for RO registers), request will be ignored.
-- For register read operation violation (for example for WO registers), return value always will be 0.

architecture RTL of mand_cluster_avalon_mm is
    type array_of_unsigned is array(integer range <>) of unsigned;
    type array_of_signed is array(integer range <>) of signed;
    type array_of_std_logic is array(integer range <>) of std_logic;

    constant CORES_STATUS_REG_SIZE : natural := div_ceil(CORES_COUNT, 8) * 8;

    -- Control registers
    signal cluster_command_reg, cluster_command_next : unsigned(NORMAL_REG_SIZE - 1 downto 0) := (others => '0');
    signal cluster_command_status_reg, cluster_command_status_next : unsigned(NORMAL_REG_SIZE - 1 downto 0) := (others => '0');
    signal core_address_reg, core_address_next : unsigned(NORMAL_REG_SIZE - 1 downto 0) := (others => '0');

    -- Cores input registers
    signal core_x_reg, core_x_next : signed(FIXED_SIZE - 1 downto 0) := (others => '0');
    signal core_y_reg, core_y_next : signed(FIXED_SIZE - 1 downto 0) := (others => '0');
    signal core_itterations_max_reg, core_itterations_max_next : unsigned(ITTERATIONS_SIZE - 1 downto 0) := (others => '0');

    -- Cores output registers
    signal core_result_reg, core_result_next : unsigned(ITTERATIONS_SIZE - 1 downto 0) := (others => '0');
    signal core_busy_reg, core_busy_next : std_logic := '0';
    signal core_valid_reg, core_valid_next : std_logic := '0';

    -- Additonal registers
    signal cores_i_start_reg, cores_i_start_next : unsigned(CORES_COUNT - 1 downto 0) := (others => '0');

    signal cores_results : array_of_unsigned(CORES_COUNT - 1 downto 0)(ITTERATIONS_SIZE - 1 downto 0) := (others => (others => '0'));
    signal cores_busy_flags : std_logic_vector(CORES_COUNT - 1 downto 0) := (others => '0');
    signal cores_valid_flags : std_logic_vector(CORES_COUNT - 1 downto 0) := (others => '0');

begin

    -- Avalon-MM slave interface
    process (clk)
    begin
        if rising_edge(clk) then
            if sync_reset = '1' then
                -- Reset Registers
                avs_readdata <= (others => '0');

            elsif avs_write = '1' then
                -- Avalon-MM write operation

                -- TODO:
                -- Implement write operation

            elsif avs_read = '1' then
                -- Avalon-MM read operation

                -- TODO:
                -- Implement read operation
                avs_readdata <= (others => '0');
            else
                -- By default, return 0
                avs_readdata <= (others => '0');
            end if;

        end if;
    end process;

    -- Generate cluster of mandelbrot cores
    MANDELBROT_CLUSTER : for i in 0 to CORES_COUNT - 1 generate
        MANDELBROT_CORE : entity mand.mandelbrot_core
            generic map(
                FIXED_SIZE => FIXED_SIZE,
                FIXED_INTEGER_SIZE => FIXED_INTEGER_SIZE,
                ITTERATIONS_SIZE => ITTERATIONS_SIZE
            )
            port map(
                clk => clk,
                sync_reset => sync_reset,

                i_start => cores_i_start_reg(i),

                i_x => core_x_reg,
                i_y => core_y_reg,
                i_iterations_max => core_itterations_max_reg,

                o_result => cores_results(i),

                o_busy => cores_busy_flags(i),
                o_valid => cores_valid_flags(i)
            );
    end generate;

end architecture;