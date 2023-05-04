
#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"
#include "kernel/stat.h"
#include "kernel/proc_info.h"
#include "kernel/syscall.h"

int main(int argc, char** argv) {
     int p1 = fork();
     if (p1 == 0){
        set_cfs_priority(2);
        for ( int i=0; i<1000000; i++)
        {
            if ( i % 100000 == 0 )
            {
                sleep(1); 
            }
        }
        uint64 dst = (uint64)malloc(sizeof(struct proc_info));
         if (dst == 0) {
             printf("Error: Could not allocate user space buffer\n");
             exit(1, "");
         }
         if (get_cfs_stats(getpid(), dst) != 0) {
            fprintf(1, "get_cfs_stats failed");
        } else {

            fprintf(1, "child: pid=%d  , cfs_priority=%d  , retime=%d  , rtime=%d  , stime=%d\n",
                getpid(), ((struct proc_info*)dst)->cfs_priority, ((struct proc_info*)dst)->retime, ((struct proc_info*)dst)->rtime, ((struct proc_info*)dst)->stime);
        }
     }
     else
     {
        sleep(1);
        int p2 = fork(); 
        if (p2 == 0){
            set_cfs_priority(1);
        for ( int z=0; z<1000000; z++)
        {
            if ( z % 100000 == 0 )
            {
                sleep(1); 
            }
        }
        uint64 dst2 = (uint64)malloc(sizeof(struct proc_info));
         if (dst2 == 0) {
             printf("Error: Could not allocate user space buffer\n");
             exit(1, "");
         }
         //sleep(3);
         if (get_cfs_stats(getpid(), dst2) != 0) {
            fprintf(1, "get_cfs_stats failed");
        } else {

            fprintf(1, "child: pid=%d  , cfs_priority=%d  , retime=%d  , rtime=%d  , stime=%d\n",
                getpid(), ((struct proc_info*)dst2)->cfs_priority, ((struct proc_info*)dst2)->retime, ((struct proc_info*)dst2)->rtime, ((struct proc_info*)dst2)->stime);
        }
            }
        else
        {
            sleep(2);
            int p3 = fork(); 
            if (p3 == 0){
                    set_cfs_priority(0);
        for ( int a=0; a<1000000; a++)
        {
            if ( a % 100000 == 0 )
            {
                sleep(1); 
            }
        }
        uint64 dst3 = (uint64)malloc(sizeof(struct proc_info));
         if (dst3 == 0) {
             printf("Error: Could not allocate user space buffer\n");
             exit(1, "");
         }
         if (get_cfs_stats(getpid(), dst3) != 0) {
            fprintf(1, "get_cfs_stats failed");
        } else {

            fprintf(1, "child: pid=%d  , cfs_priority=%d  , retime=%d  , rtime=%d  , stime=%d\n",
                getpid(), ((struct proc_info*)dst3)->cfs_priority, ((struct proc_info*)dst3)->retime, ((struct proc_info*)dst3)->rtime, ((struct proc_info*)dst3)->stime);
        }
            }
        }
     }
     sleep(15);
     
     exit(1, ""); 
}

