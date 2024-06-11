library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Commands list:
-- 0x0000 - Reset the core with the address `i_address`
-- 0x0001 - Load `i_x`, `i_y` values into the core with the address `i_address` and start core execution
-- 0x0002 - Load result from the core with the address `i_address` into the `o_result` register

-- Status list:
-- 0x0000 - Command executed successfully
-- 0x0001 - Unknown command
-- 0x0002 - No such core with the address `i_address`
-- 0x0003 - Core is busy
-- 0xffff - Command is not executed yet

entity mandelbrot_cluser is
    generic (
        FIXED_INTEGER_SIZE : natural := 4; -- Fixed floating point integer bits for the i_x and i_y inputs
        FIXED_SIZE : natural := 32; -- Size of the input i_x and i_y values

        ITERATIONS_SIZE : natural := 64; -- Size of the output iterations value (unsigned long by default)

        constant NORMAL_REG_SIZE : natural := 64; -- Size of the normal registers
        CORES_COUNT : natural := 1 -- Number of cores to use
    );
    port (
        clk : in std_logic;
        sync_reset : in std_logic;

        -- Input values
        i_enable : in std_logic; -- Enable the execution of the command
        i_command : in std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Command register input
        i_address : in std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Address of the mandelbrot core to use

        i_x : in std_logic_vector(FIXED_SIZE - 1 downto 0); -- Real part of the input value to load into the core
        i_y : in std_logic_vector(FIXED_SIZE - 1 downto 0); -- Imaginary part of the input value to load into the core

        -- Output values
        o_command_status : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Status of the last executed command
        o_cluster_busy : out std_logic; -- If the cluster is busy its bit is set (if it is not possible to execute the command at the moment)

        -- Meta data about current FPGA configuration
        o_fixed_size : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Resolution of the input values
        o_fixed_integer_size : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Number of fixed bits in the output value
        o_iterations_size : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Resolution of the output iterations value
        o_cores_count : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Number of cores in the FPGA

        -- Cores status values
        o_core_busy : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- If the core is busy its bit is set
        o_core_valid : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- If the core has valid output its bit is set

        -- Mandelbrot core output values
        -- Read result command with the address of the core to read from will be stored here
        o_result : out std_logic_vector(ITERATIONS_SIZE - 1 downto 0) -- Output value of particular mandelbrot core
    );
end entity;

architecture RTL of mandelbrot_cluser is

    signal command_status_reg, command_status_next : std_logic_vector(NORMAL_REG_SIZE - 1 downto 0);
    signal cluster_busy_reg, cluster_busy_next : std_logic;

    signal command_reg, command_next : std_logic_vector(i_command'range);
    signal address_reg, address_next : std_logic_vector(i_address'range);
    signal x_reg, x_next, y_reg, y_next : std_logic_vector(i_x'range);

    signal core_busy_reg, core_busy_next : std_logic_vector(NORMAL_REG_SIZE - 1 downto 0);
    signal core_valid_reg, core_valid_next : std_logic_vector(NORMAL_REG_SIZE - 1 downto 0);

    signal result_reg, result_next : std_logic_vector(ITERATIONS_SIZE - 1 downto 0);
begin
    -- Registers
    process (clk)
    begin
        if rising_edge(clk) then
            if sync_reset = '1' then
                command_reg <= (others => '0');
                address_reg <= (others => '0');
                x_reg <= (others => '0');
                y_reg <= (others => '0');

                command_status_reg <= (others => '1');
                cluster_busy_reg <= '0';

                core_busy_reg <= (others => '0');
                core_valid_reg <= (others => '0');
                result_reg <= (others => '0');
            else
                command_reg <= command_next;
                address_reg <= address_next;
                x_reg <= x_next;
                y_reg <= y_next;

                command_status_reg <= command_status_next;
                cluster_busy_reg <= cluster_busy_next;

                core_busy_reg <= core_busy_next;
                core_valid_reg <= core_valid_next;
                result_reg <= result_next;
            end if;
        end if;
    end process;

    -- Outputs
    o_fixed_integer_size <= std_logic_vector(to_unsigned(FIXED_INTEGER_SIZE, NORMAL_REG_SIZE));
    o_fixed_size <= std_logic_vector(to_unsigned(FIXED_SIZE, NORMAL_REG_SIZE));
    o_iterations_size <= std_logic_vector(to_unsigned(ITERATIONS_SIZE, NORMAL_REG_SIZE));
    o_cores_count <= std_logic_vector(to_unsigned(CORES_COUNT, NORMAL_REG_SIZE));

    o_core_busy <= core_busy_reg;
    o_core_valid <= core_valid_reg;
    o_result <= result_reg;
end architecture;