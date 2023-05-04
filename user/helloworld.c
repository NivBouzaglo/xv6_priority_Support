#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    char *message = "Hello World xv6";
    write(1, message, 16);
    write(1, "\n", 1);
    exit(0, "");
}