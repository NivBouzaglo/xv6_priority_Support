#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/stat.h"
#include "kernel/proc_info.h"
#include "kernel/syscall.h"

int main(int argc, char **argv)
{
    if (argc < 1)
    {
        printf("Error: Could not allocate user space buffer\n");
        exit(1, "");
    }
    int set = -1;
    for (int i = 0; i < argc; i++)
    {
        set = atoi(*argv);
        argv++;
    }
    set = set_policy(set);
    if(set == 0)
        write(1,"success\n" , 8);
    else 
        write(1,"error\n",6);
    return 0;
}