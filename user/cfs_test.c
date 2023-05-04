#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/stat.h"
#include "kernel/proc_info.h"
#include "kernel/syscall.h"

int main(int argc, char** argv) {
    int p = fork();
    if (p == 0) {
        //struct proc_info info;
        uint64 dst = (uint64)malloc(sizeof(struct proc_info));
         if (dst == 0) {
             printf("Error: Could not allocate user space buffer\n");
             exit(1, "");
         }
         //(uint64)&info
        set_cfs_priority(2);
        if (get_cfs_stats(getpid(), dst) != 0) {
            fprintf(1, "get_cfs_stats failed");
        } else {

            fprintf(1, "child: pid=%d\n, cfs_priority=%d\n, retime=%d\n, rtime=%d\n, stime=%d\n",
                p, ((struct proc_info*)dst)->cfs_priority, ((struct proc_info*)dst)->retime, ((struct proc_info*)dst)->rtime, ((struct proc_info*)dst)->stime);
        }
    } else {
        wait(0, 0);
    }
    exit(0, "");
}


















































// #include "kernel/types.h"
// #include "user/user.h"
// #include "kernel/fcntl.h"
// #include "kernel/stat.h"
// #include "kernel/proc_info.h"
// #include "kernel/syscall.h"




// int main(int argc , char** argv){
//     int p = fork();
//     if (p ==0){
//         sleep(10); 
//         struct proc_info info1; 
//         sleep(5);
//         write(1, "father ", 7);
//         fprintf(1,"%d\n",p);
//         sleep(10);
//         set_cfs_priority(2);
//         if(get_cfs_stats(p, (uint64)&info1) != 0 )
//         {
//             fprintf(1, "fail");
//         }
//         else{
//             fprintf(1, "success");
//         }
//         fprintf(1, " ans: %d\n", info1.cfs_priority);
//         wait(0, 0);
//     }
//     else
//     {
//         struct proc_info info; 
//         sleep(5);
//         write(1, "child 1 ", 8);
//         fprintf(1,"%d\n",p);
//         sleep(10);
//         set_cfs_priority(1);
//         if(get_cfs_stats(p, (uint64)&info) != 0 )
//         {
//             fprintf(1, "fail");
//         }
//         else{
//             fprintf(1, "success");
//         }
//         fprintf(1, " ans: %d\n", info.cfs_priority);
//         wait(0, 0); 
        
//     }
//     exit(1, "");
// }