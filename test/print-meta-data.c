#include <error.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#include <time.h>

#define BRIDGE 0xC0000000
#define BRIDGE_SPAN 0x0080

// --      command,                        - RW, size: NORMAL_REG_SIZE
// --      command_status,                 - RO, size: NORMAL_REG_SIZE
// --      core_address,                   - RW, size: NORMAL_REG_SIZE
// --      cores_busy_flag,                - RO, size: CORES_STATUS_REG_SIZE
// --      cores_valid_flag                - RO, size: CORES_STATUS_REG_SIZE

struct __attribute__((__packed__)) mand_cluster
{
    uint64_t cores_count;
    uint64_t fixed_size;
    uint64_t fixed_integer_size;

    uint64_t command;
    uint64_t command_status;
    uint64_t core_address;
    uint8_t cores_busy_flag[128 / 8];
    uint8_t cores_valid_flag[128 / 8];

    uint64_t core_result;
    uint64_t core_busy;
    uint64_t core_valid;

    uint64_t core_max_itterations;
    uint64_t core_x;
    uint64_t core_y;
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

    printf("Cores Count: %" PRIu64 "\n", cluster->cores_count);
    printf("Fixed Size: %" PRIu64 "\n", cluster->fixed_size);
    printf("Fixed Integer Size: %" PRIu64 "\n", cluster->fixed_integer_size);

    printf("Command: %" PRIu64 "\n", cluster->command);
    printf("Command Status: %" PRIu64 "\n", cluster->command_status);
    printf("Core Address: %" PRIu64 "\n", cluster->core_address);
    printf("Cores Busy Flag: %s\n", cluster->cores_busy_flag);
    printf("Cores Valid Flag: %s\n", cluster->cores_valid_flag);

    printf("Core Result: %" PRIu64 "\n", cluster->core_result);
    printf("Core Busy: %" PRIu64 "\n", cluster->core_busy);
    printf("Core Valid: %" PRIu64 "\n", cluster->core_valid);

    printf("Core Itterations Size: %" PRIu64 "\n", cluster->core_max_itterations);
    printf("Core X: %" PRIu64 "\n", cluster->core_x);
    printf("Core Y: %" PRIu64 "\n\n", cluster->core_y);

    cluster->core_max_itterations = 10000000;

    cluster->core_x = 0;
    cluster->core_y = 0;

    printf("");

    // Start core
    cluster->command = 2;
    printf("Started core.\n");
    printf("Core X: %" PRIu64 "\n", cluster->core_x);
    printf("Core Y: %" PRIu64 "\n\n", cluster->core_y);
    printf("Command Status: %" PRIu64 "\n", cluster->command_status);

    printf("Cores Busy Flag: %s\n", cluster->cores_busy_flag);
    printf("Cores Valid Flag: %s\n\n", cluster->cores_valid_flag);

    time_t start = time(NULL);

    while (cluster->cores_busy_flag[0] == 1)
    {
        printf("Core is busy.\n");
    }

    time_t end = time(NULL);
    double elapsed = difftime(end, start);

    printf("Core is done.\n");

    // Load result
    cluster->command = 1;
    printf("Started load command.\n");
    printf("Command Status: %" PRIu64 "\n", cluster->command_status);

    printf("Core Result: %" PRIu64 "\n", cluster->core_result);
    printf("Core Busy: %" PRIu64 "\n", cluster->core_busy);
    printf("Core Valid: %" PRIu64 "\n", cluster->core_valid);
    printf("Finished in: %f seconds.\n", elapsed);
    printf("Itterations speed: %f Ms/s.\n", elapsed / cluster->core_max_itterations * 1000000);

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