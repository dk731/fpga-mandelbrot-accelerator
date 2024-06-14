#include <error.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>

#define BRIDGE 0xC0000000
#define BRIDGE_SPAN 0x03ff

// --      command,                        - RW, size: NORMAL_REG_SIZE
// --      command_status,                 - RO, size: NORMAL_REG_SIZE
// --      core_address,                   - RW, size: NORMAL_REG_SIZE
// --      cores_busy_flag,                - RO, size: CORES_STATUS_REG_SIZE
// --      cores_valid_flag                - RO, size: CORES_STATUS_REG_SIZE

struct __attribute__((__packed__)) mand_cluster
{
    uint32_t cores_count;
    uint32_t fixed_size;
    uint32_t fixed_integer_size;
    uint32_t itterations_size;
    uint32_t cores_status_reg_size;

    uint32_t command;
    uint32_t command_status;
    uint32_t core_address;
    uint8_t cores_busy_flag;
    uint8_t cores_valid_flag;

    uint32_t core_x;
    uint32_t core_y;
    uint32_t core_itterations_max;

    uint32_t core_result;
    uint32_t core_busy;
    uint32_t core_valid;
};

int main(int argc, char **argv)
{

    uint8_t *bridge_map = NULL;

    int fd = 0;
    int result = 0;

    fd = open("/dev/mem", O_RDWR | O_SYNC);

    if (fd < 0)
    {
        perror("Couldn't open /dev/mem\n");
        return -2;
    }

    bridge_map = (uint8_t *)mmap(NULL, sizeof(struct mand_cluster), PROT_READ | PROT_WRITE,
                                 MAP_SHARED, fd, BRIDGE);

    if (bridge_map == MAP_FAILED)
    {
        perror("mmap failed.");
        close(fd);
        return -3;
    }

    struct mand_cluster *cluster = (struct mand_cluster *)(bridge_map + 0);

    printf("Cores Count: %" PRIu32 "\n", cluster->cores_count);
    printf("Fixed Size: %" PRIu32 "\n", cluster->fixed_size);
    printf("Fixed Integer Size: %" PRIu32 "\n", cluster->fixed_integer_size);
    printf("Itterations Size: %" PRIu32 "\n", cluster->itterations_size);
    printf("Cores Status Size: %" PRIu32 "\n\n", cluster->cores_status_reg_size);

    cluster->command = 0x02;
    cluster->core_address = 0x01;

    printf("Command: %" PRIu32 "\n", cluster->command);
    printf("Command Status: %" PRIu32 "\n", cluster->command_status);
    printf("Core Address: %" PRIu32 "\n", cluster->core_address);
    printf("Cores Busy Flag: %" PRIu8 "\n", cluster->cores_busy_flag);
    printf("Cores Valid Flag: %" PRIu8 "\n\n", cluster->cores_valid_flag);

    // printf("Core X: %" PRIu32 "\n", cluster->core_x);
    // printf("Core Y: %" PRIu32 "\n", cluster->core_y);
    // printf("Core Itterations Max: %" PRIu32 "\n\n", cluster->core_itterations_max);

    printf("Core Result: %" PRIu32 "\n", cluster->core_result);
    printf("Core Busy: %" PRIu32 "\n", cluster->core_busy);
    printf("Core Valid: %" PRIu32 "\n", cluster->core_valid);

    result = munmap(bridge_map, BRIDGE_SPAN);

    if (result < 0)
    {
        perror("Couldnt unmap bridge.");
        close(fd);
        return -4;
    }

    close(fd);
    return 0;
}