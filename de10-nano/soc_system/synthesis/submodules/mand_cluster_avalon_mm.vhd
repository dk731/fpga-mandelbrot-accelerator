library ieee;
library mand;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use mand.functions.all;

entity mand_cluster_avalon_mm is
    generic (
        -- Cluster configuration
        CORES_COUNT : natural := 2; -- Number of cores to use

        -- Each Mandelbrot core configuration
        FIXED_SIZE : natural := 32; -- Size of the input i_x and i_y values
        FIXED_INTEGER_SIZE : natural := 5; -- Fixed point integer bits for the i_x and i_y inputs
        ITTERATIONS_SIZE : natural := 32; -- Size of the output iterations value (unsigned long by default)

        -- Avalon-MM configuration
        constant AVALON_DATA_WIDTH : natural := 8; -- For know I will use 8-bit data width

        constant NORMAL_REG_SIZE : natural := 32 -- Dont change this, or driver will have to be compiled
    );
    port (
        clk : in std_logic;
        reset : in std_logic;

        -- Avalon-MM slave interface
        avs_address : in std_logic_vector(10 - 1 downto 0);

        avs_read : in std_logic;
        avs_write : in std_logic;
        avs_writedata : in std_logic_vector(AVALON_DATA_WIDTH - 1 downto 0);
        avs_readdata : out std_logic_vector(AVALON_DATA_WIDTH - 1 downto 0)
        -- avs_byteenable : in std_logic_vector((AVALON_DATA_WIDTH / 8) - 1 downto 0)
    );
end entity;

-- Avalon-MM Control Commands:
-- 0x00 - No operation (NOP)
-- 0x01 - Load outputs from <core_address> core to output registers: <active_core_o_result>, <core_o_busy>, <core_o_valid>
-- 0x02 - Trigger start calculation on <core_address> core with <core_i_x>, <core_i_y>, <core_i_itterations_max> inputs
-- 0x03 - Trigger reset on <core_address> core

-- Command Statuses:
-- 0x00 - Success
-- 0x01 - Cluster is busy
-- 0x02 - Invalid command
-- 0x03 - Invalid core address
-- 0x04 - Attempt to start calculation on busy core (request ignored)
-- 0x05 - After cluster reset
-- 0xff - Unknown error

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
--   Command status will store status of last executed non-NOP command.
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

    -- Register addresses
    constant CORES_COUNT_REG_ADDRESS : natural := 0;
    constant FIXED_SIZE_REG_ADDRESS : natural := CORES_COUNT_REG_ADDRESS + NORMAL_REG_SIZE;
    constant FIXED_INTEGER_SIZE_REG_ADDRESS : natural := FIXED_SIZE_REG_ADDRESS + NORMAL_REG_SIZE;
    constant ITTERATIONS_SIZE_REG_ADDRESS : natural := FIXED_INTEGER_SIZE_REG_ADDRESS + NORMAL_REG_SIZE;
    constant CORES_STATUS_REG_SIZE_REG_ADDRESS : natural := ITTERATIONS_SIZE_REG_ADDRESS + NORMAL_REG_SIZE;

    constant COMMAND_REG_ADDRESS : natural := CORES_STATUS_REG_SIZE_REG_ADDRESS + NORMAL_REG_SIZE;
    constant COMMAND_STATUS_REG_ADDRESS : natural := COMMAND_REG_ADDRESS + NORMAL_REG_SIZE;
    constant CORE_ADDRESS_REG_ADDRESS : natural := COMMAND_STATUS_REG_ADDRESS + NORMAL_REG_SIZE;
    constant CORES_BUSY_FLAG_REG_ADDRESS : natural := CORE_ADDRESS_REG_ADDRESS + NORMAL_REG_SIZE;
    constant CORES_VALID_FLAG_REG_ADDRESS : natural := CORES_BUSY_FLAG_REG_ADDRESS + CORES_STATUS_REG_SIZE;

    constant CORE_X_REG_ADDRESS : natural := CORES_VALID_FLAG_REG_ADDRESS + CORES_STATUS_REG_SIZE;
    constant CORE_Y_REG_ADDRESS : natural := CORE_X_REG_ADDRESS + FIXED_SIZE;
    constant CORE_ITTERATIONS_MAX_REG_ADDRESS : natural := CORE_Y_REG_ADDRESS + FIXED_SIZE;

    constant CORE_RESULT_REG_ADDRESS : natural := CORE_ITTERATIONS_MAX_REG_ADDRESS + ITTERATIONS_SIZE;
    constant CORE_BUSY_REG_ADDRESS : natural := CORE_RESULT_REG_ADDRESS + ITTERATIONS_SIZE;
    constant CORE_VALID_REG_ADDRESS : natural := CORE_BUSY_REG_ADDRESS + NORMAL_REG_SIZE;

    -- Control constants
    -- Commands:
    constant COMMAND_NO_OPERATION : natural := 0;
    constant COMMAND_LOAD_OUTPUTS : natural := 1;
    constant COMMAND_START_CALCULATION : natural := 2;
    constant COMMAND_RESET : natural := 3;

    -- Command statuses:
    constant COMMAND_STATUS_SUCCESS : unsigned(NORMAL_REG_SIZE - 1 downto 0) := to_unsigned(0, NORMAL_REG_SIZE);
    constant COMMAND_STATUS_BUSY : unsigned(NORMAL_REG_SIZE - 1 downto 0) := to_unsigned(1, NORMAL_REG_SIZE);
    constant COMMAND_STATUS_INVALID_COMMAND : unsigned(NORMAL_REG_SIZE - 1 downto 0) := to_unsigned(2, NORMAL_REG_SIZE);
    constant COMMAND_STATUS_INVALID_CORE_ADDRESS : unsigned(NORMAL_REG_SIZE - 1 downto 0) := to_unsigned(3, NORMAL_REG_SIZE);
    constant COMMAND_STATUS_BUSY_CORE : unsigned(NORMAL_REG_SIZE - 1 downto 0) := to_unsigned(4, NORMAL_REG_SIZE);
    constant COMMAND_STATUS_AFTER_RESET : unsigned(NORMAL_REG_SIZE - 1 downto 0) := to_unsigned(5, NORMAL_REG_SIZE);
    constant COMMAND_STATUS_UNKNOWN_ERROR : unsigned(NORMAL_REG_SIZE - 1 downto 0) := to_unsigned(255, NORMAL_REG_SIZE);

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
    signal cores_start_reg, cores_start_next : unsigned(CORES_COUNT - 1 downto 0) := (others => '0');
    signal cores_reset_reg, cores_reset_next : unsigned(CORES_COUNT - 1 downto 0) := (others => '1');

    signal cores_results : array_of_unsigned(CORES_COUNT - 1 downto 0)(ITTERATIONS_SIZE - 1 downto 0) := (others => (others => '0'));
    signal cores_busy_flags : std_logic_vector(CORES_COUNT - 1 downto 0) := (others => '0');
    signal cores_valid_flags : std_logic_vector(CORES_COUNT - 1 downto 0) := (others => '0');

    signal avalon_read_mm : std_logic_vector(1024 - 1 downto 0) := (others => '0');
    signal avalon_write_mm : std_logic_vector(1024 - 1 downto 0) := (others => '0');
begin

    -- Registers
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- Reset registers
                cluster_command_status_reg <= COMMAND_STATUS_AFTER_RESET;

                core_result_reg <= (others => '0');
                core_busy_reg <= '0';
                core_valid_reg <= '0';

                cores_start_reg <= (others => '0');
                cores_reset_reg <= (others => '1');
            else
                -- Control registers
                cluster_command_status_reg <= cluster_command_status_next;

                -- Cores output registers
                core_result_reg <= core_result_next;
                core_busy_reg <= core_busy_next;
                core_valid_reg <= core_valid_next;

                -- Additional registers
                cores_start_reg <= cores_start_next;
                cores_reset_reg <= cores_reset_next;
            end if;
        end if;
    end process;

    -- Avalon-MM slave interface
    process (clk)
        variable avs_bit_address : integer;
    begin
        if rising_edge(clk) then
            avs_bit_address := to_integer(unsigned(avs_address)) * 8;

            if reset = '1' then
                -- Reset Registers
                avs_readdata <= (others => '0');

            elsif avs_write = '1' then
                -- Avalon-MM write operation

                avalon_write_mm(avs_bit_address + 8 - 1 downto avs_bit_address) <= avs_writedata;

                -- In case of write to command register, execute command
                if avs_bit_address = COMMAND_REG_ADDRESS then

                    -- By default, return success
                    cluster_command_status_next <= COMMAND_STATUS_SUCCESS;

                    case to_integer(unsigned(avs_writedata)) is
                        when COMMAND_NO_OPERATION =>
                            -- Do nothing

                        when COMMAND_LOAD_OUTPUTS =>
                            if core_address_reg >= CORES_COUNT then
                                cluster_command_status_next <= COMMAND_STATUS_INVALID_CORE_ADDRESS;
                            else
                                core_result_next <= cores_results(to_integer(core_address_reg));
                                core_busy_next <= cores_busy_flags(to_integer(core_address_reg));
                                core_valid_next <= cores_valid_flags(to_integer(core_address_reg));
                            end if;

                        when COMMAND_START_CALCULATION =>
                            if core_address_reg >= CORES_COUNT then
                                cluster_command_status_next <= COMMAND_STATUS_INVALID_CORE_ADDRESS;
                            elsif cores_busy_flags(to_integer(core_address_reg)) = '1' then
                                cluster_command_status_next <= COMMAND_STATUS_BUSY_CORE;
                            else
                                cores_start_next(to_integer(core_address_reg)) <= '1';
                            end if;

                        when COMMAND_RESET =>
                            if core_address_reg >= CORES_COUNT then
                                cluster_command_status_next <= COMMAND_STATUS_INVALID_CORE_ADDRESS;
                            else
                                cores_reset_next(to_integer(core_address_reg)) <= '1';
                            end if;

                        when others =>
                            cluster_command_status_next <= COMMAND_STATUS_INVALID_COMMAND;

                    end case;

                end if;
            elsif avs_read = '1' then
                -- Avalon-MM read operation

                avs_readdata <= avalon_read_mm(avs_bit_address + 8 - 1 downto avs_bit_address);
            else
                -- By default, return 0
                avs_readdata <= (others => '0');
                cores_start_next <= (others => '0');
                cores_reset_next <= (others => '0');
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
                sync_reset => cores_reset_reg(i),

                i_start => cores_start_reg(i),

                i_x => core_x_reg,
                i_y => core_y_reg,
                i_iterations_max => core_itterations_max_reg,

                o_result => cores_results(i),

                o_busy => cores_busy_flags(i),
                o_valid => cores_valid_flags(i)
            );
    end generate;

    -- Avalon-MM read interface
    avalon_read_mm(CORES_COUNT_REG_ADDRESS + NORMAL_REG_SIZE - 1 downto CORES_COUNT_REG_ADDRESS) <= std_logic_vector(to_unsigned(CORES_COUNT, NORMAL_REG_SIZE));
    avalon_read_mm(FIXED_SIZE_REG_ADDRESS + NORMAL_REG_SIZE - 1 downto FIXED_SIZE_REG_ADDRESS) <= std_logic_vector(to_unsigned(FIXED_SIZE, NORMAL_REG_SIZE));
    avalon_read_mm(FIXED_INTEGER_SIZE_REG_ADDRESS + NORMAL_REG_SIZE - 1 downto FIXED_INTEGER_SIZE_REG_ADDRESS) <= std_logic_vector(to_unsigned(FIXED_INTEGER_SIZE, NORMAL_REG_SIZE));
    avalon_read_mm(ITTERATIONS_SIZE_REG_ADDRESS + NORMAL_REG_SIZE - 1 downto ITTERATIONS_SIZE_REG_ADDRESS) <= std_logic_vector(to_unsigned(ITTERATIONS_SIZE, NORMAL_REG_SIZE));
    avalon_read_mm(CORES_STATUS_REG_SIZE_REG_ADDRESS + NORMAL_REG_SIZE - 1 downto CORES_STATUS_REG_SIZE_REG_ADDRESS) <= std_logic_vector(to_unsigned(CORES_STATUS_REG_SIZE, NORMAL_REG_SIZE));

    avalon_read_mm(COMMAND_REG_ADDRESS + NORMAL_REG_SIZE - 1 downto COMMAND_REG_ADDRESS) <= std_logic_vector(cluster_command_reg);
    avalon_read_mm(COMMAND_STATUS_REG_ADDRESS + NORMAL_REG_SIZE - 1 downto COMMAND_STATUS_REG_ADDRESS) <= std_logic_vector(cluster_command_status_reg);
    avalon_read_mm(CORE_ADDRESS_REG_ADDRESS + NORMAL_REG_SIZE - 1 downto CORE_ADDRESS_REG_ADDRESS) <= std_logic_vector(core_address_reg);
    avalon_read_mm(CORES_BUSY_FLAG_REG_ADDRESS + CORES_COUNT - 1 downto CORES_BUSY_FLAG_REG_ADDRESS) <= cores_busy_flags;
    avalon_read_mm(CORES_VALID_FLAG_REG_ADDRESS + CORES_COUNT - 1 downto CORES_VALID_FLAG_REG_ADDRESS) <= cores_valid_flags;

    avalon_read_mm(CORE_X_REG_ADDRESS + FIXED_SIZE - 1 downto CORE_X_REG_ADDRESS) <= std_logic_vector(core_x_reg);
    avalon_read_mm(CORE_Y_REG_ADDRESS + FIXED_SIZE - 1 downto CORE_Y_REG_ADDRESS) <= std_logic_vector(core_y_reg);
    avalon_read_mm(CORE_ITTERATIONS_MAX_REG_ADDRESS + ITTERATIONS_SIZE - 1 downto CORE_ITTERATIONS_MAX_REG_ADDRESS) <= std_logic_vector(core_itterations_max_reg);

    avalon_read_mm(CORE_RESULT_REG_ADDRESS + ITTERATIONS_SIZE - 1 downto CORE_RESULT_REG_ADDRESS) <= std_logic_vector(core_result_reg);
    avalon_read_mm(CORE_BUSY_REG_ADDRESS) <= core_busy_reg;
    avalon_read_mm(CORE_VALID_REG_ADDRESS) <= core_valid_reg;

    -- Avalon-MM write interface
    cluster_command_reg <= unsigned(avalon_write_mm(COMMAND_REG_ADDRESS + NORMAL_REG_SIZE - 1 downto COMMAND_REG_ADDRESS));
    core_address_reg <= unsigned(avalon_write_mm(CORE_ADDRESS_REG_ADDRESS + NORMAL_REG_SIZE - 1 downto CORE_ADDRESS_REG_ADDRESS));

    core_x_reg <= signed(avalon_write_mm(CORE_X_REG_ADDRESS + FIXED_SIZE - 1 downto CORE_X_REG_ADDRESS));
    core_y_reg <= signed(avalon_write_mm(CORE_Y_REG_ADDRESS + FIXED_SIZE - 1 downto CORE_Y_REG_ADDRESS));
    core_itterations_max_reg <= unsigned(avalon_write_mm(CORE_ITTERATIONS_MAX_REG_ADDRESS + ITTERATIONS_SIZE - 1 downto CORE_ITTERATIONS_MAX_REG_ADDRESS));

end architecture;