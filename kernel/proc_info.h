#ifndef PROC_INFO_H
#define PROC_INFO_H

struct proc_info {
    int cfs_priority;
    int retime;
    int rtime;
    int stime;
};

#endif