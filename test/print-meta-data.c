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
    uint8_t core_x[128 / 8];
    uint8_t core_y[128 / 8];
};

void printf_bits(uint8_t *bits, int size)
{
    for (int i = size; i >= 0; i--)
    {
        printf("%d", (bits[i / 8] >> (i % 8)) & 1);
    }
    printf("\n");
}

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

    printf("\nCommand: %" PRIu64 "\n", cluster->command);
    printf("Command Status: %" PRIu64 "\n", cluster->command_status);
    printf("Core Address: %" PRIu64 "\n", cluster->core_address);
    printf("Core Busy Flags:");
    printf_bits(cluster->cores_busy_flag, 128);

    printf("Core Valid Flags:");
    printf_bits(cluster->cores_valid_flag, 128);

    printf("\nCore Result: %" PRIu64 "\n", cluster->core_result);
    printf("Core Busy: %" PRIu64 "\n", cluster->core_busy);
    printf("Core Valid: %" PRIu64 "\n", cluster->core_valid);

    printf("\nCore Max Itterations: %" PRIu64 "\n", cluster->core_max_itterations);
    printf("Core X:");
    printf_bits(cluster->core_x, 128);

    printf("Core Y:");
    printf_bits(cluster->core_y, 128);

    // printf("Starting cores reset.\n");
    // for (uint8_t i = 0; i < cluster->cores_count; i++)
    // {
    //     cluster->core_address = i;
    //     cluster->command = 0x03;

    //     if (cluster->command_status != 0x00)
    //     {
    //         printf("Core %d reset failed with status: %lld. Last executed command: %lld.\n", i, cluster->command_status, cluster->command);
    //     }
    // }

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