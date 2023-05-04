#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    int size = memsize();
    printf("memory size before allocate = %d \n", size);
    void *addr = malloc(sizeof(20000));
    size = memsize();
    printf("memory size after allocate = %d \n", size);
    free(addr);
    size = memsize();
    printf("memory size after free = %d \n", size);
    exit(0, "");
}