library ieee;
library mand;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mandelbrot_cluser is
    generic (
        -- Free to change
        CORES_COUNT : natural := 2; -- Number of cores to use
        FIXED_INTEGER_SIZE : natural := 2; -- Fixed floating point integer bits for the i_x and i_y inputs
        FIXED_SIZE : natural := 4; -- Size of the input i_x and i_y values

        -- Not recommended to change, need to update driver code
        constant ITERATIONS_SIZE : natural := 2; -- Size of the output iterations value (unsigned long by default)
        constant NORMAL_REG_SIZE : natural := 32; -- Size of the normal registers
        constant CORES_STATUS_SIZE : natural := 512 -- Size of registers that hold the status of all cores (should be at least CORES_COUNT bits long)
    );
    port (
        clk : in std_logic;
        sync_reset : in std_logic;

        -- Input values
        i_enable : in std_logic; -- Enable the execution of the command
        i_command : in std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Command register input
        i_address : in std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Address of the mandelbrot core to use

        i_x : in signed(FIXED_SIZE - 1 downto 0); -- Real part of the input value to load into the core
        i_y : in signed(FIXED_SIZE - 1 downto 0); -- Imaginary part of the input value to load into the core
        i_iterations_max : in unsigned(ITERATIONS_SIZE - 1 downto 0); -- Maximum number of iterations to execute

        -- Output values
        o_command_status : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Status of the last executed command
        o_cluster_busy : out std_logic; -- If the cluster is busy its bit is set (if it is not possible to execute the command at the moment)

        -- Meta data about current FPGA configuration
        o_fixed_size : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Resolution of the input values
        o_fixed_integer_size : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Number of fixed bits in the output value
        o_iterations_size : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Resolution of the output iterations value
        o_cores_count : out std_logic_vector(NORMAL_REG_SIZE - 1 downto 0); -- Number of cores in the FPGA

        -- Cores status values
        o_core_busy : out std_logic_vector(CORES_STATUS_SIZE - 1 downto 0); -- If the core is busy its bit is set
        o_core_valid : out std_logic_vector(CORES_STATUS_SIZE - 1 downto 0); -- If the core has valid output its bit is set

        -- Mandelbrot core output values
        -- Read result command with the address of the core to read from will be stored here
        o_result : out std_logic_vector(ITERATIONS_SIZE - 1 downto 0) -- Output value of particular mandelbrot core
    );
end entity;

architecture RTL of mandelbrot_cluser is
    type array_of_unsigned is array(integer range <>) of unsigned;

    -- Input registers
    signal command_reg, command_next : std_logic_vector(i_command'range) := (others => '0');
    signal address_reg, address_next : std_logic_vector(i_address'range) := (others => '0');
    signal x_reg, x_next, y_reg, y_next : signed(i_x'range) := (others => '0');
    signal iterations_max_reg, iterations_max_next : unsigned(i_iterations_max'range) := (others => '0');

    -- Cores registers
    signal core_start_reg, core_start_next : std_logic_vector(CORES_COUNT - 1 downto 0) := (others => '0');

    -- Cores output registers
    signal core_busy_reg : std_logic_vector(CORES_STATUS_SIZE - 1 downto 0) := (others => '0');
    signal core_valid_reg : std_logic_vector(CORES_STATUS_SIZE - 1 downto 0) := (others => '0');
    signal core_result_reg, core_result_next : std_logic_vector(ITERATIONS_SIZE - 1 downto 0) := (others => '0');

    signal cores_results_reg : array_of_unsigned(CORES_COUNT - 1 downto 0)(o_result'range) := (others => (others => '0'));

    -- Cluster registers
    signal command_status_reg, command_status_next : std_logic_vector(NORMAL_REG_SIZE - 1 downto 0) := (others => '0');
    signal cluster_busy_reg, cluster_busy_next : std_logic := '0';

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
                iterations_max_reg <= (others => '0');
                core_start_reg <= (others => '0');
                core_result_reg <= (others => '0');
                command_status_reg <= (others => '0');
                cluster_busy_reg <= '0';
            else
                command_reg <= command_next;
                address_reg <= address_next;
                x_reg <= x_next;
                y_reg <= y_next;
                iterations_max_reg <= iterations_max_next;
                core_start_reg <= core_start_next;
                core_result_reg <= core_result_next;
                command_status_reg <= command_status_next;
                cluster_busy_reg <= cluster_busy_next;
            end if;
        end if;
    end process;

    MANDELBROT_CLUSTER : for i in 0 to CORES_COUNT - 1 generate
        MANDELBROT_CORE : entity mand.mandelbrot_core
            generic map(
                FIXED_SIZE => FIXED_SIZE,
                FIXED_INTEGER_SIZE => FIXED_INTEGER_SIZE,
                ITERATIONS_SIZE => ITERATIONS_SIZE
            )
            port map(
                clk => clk,
                sync_reset => sync_reset,

                i_start => core_start_reg(i),

                i_x => x_reg,
                i_y => y_reg,
                i_iterations_max => iterations_max_reg,

                o_result => cores_results_reg(i),

                o_busy => core_busy_reg(i),
                o_valid => core_valid_reg(i)
            );
    end generate;

    -- Outputs
    -- Cluster configuration
    o_fixed_integer_size <= std_logic_vector(to_unsigned(FIXED_INTEGER_SIZE, NORMAL_REG_SIZE));
    o_fixed_size <= std_logic_vector(to_unsigned(FIXED_SIZE, NORMAL_REG_SIZE));
    o_iterations_size <= std_logic_vector(to_unsigned(ITERATIONS_SIZE, NORMAL_REG_SIZE));
    o_cores_count <= std_logic_vector(to_unsigned(CORES_COUNT, NORMAL_REG_SIZE));

    -- Cores ouputs
    o_core_busy <= core_busy_reg;
    o_core_valid <= core_valid_reg;
    o_result <= core_result_reg;
end architecture;