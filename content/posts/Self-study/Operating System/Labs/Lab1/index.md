---
title: 'Lab: Xv6 and Unix utilities'
description: None
date: 2022-07-01
menu:
    sidebar:
        name: 'Lab: Xv6 and Unix utilities'
        identifier: lab1
        parent: labs
---

## sleep
```c=
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        printf("[Error] missing operand\n");
        exit(-1);
    }

    int sleep_time = atoi(argv[1]);
    sleep(sleep_time);

    exit(0);
}
```

## pingpong
```c=
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main()
{
    int p[2][2];
    int child_pid, parent_pid;

    pipe(p[0]);
    pipe(p[1]);

    if ((child_pid = fork()) == 0) // child
    {
        close(p[0][1]);
        close(p[1][0]);

        char buf[1];

        read(p[0][0], buf, 1);
        write(p[1][1], buf, 1);

        child_pid = getpid();
        printf("%d: received ping\n", child_pid);
    }
    else // parent
    {
        close(p[0][0]);
        close(p[1][1]);

        char buf[1] = "0";

        write(p[0][1], buf, 1);
        read(p[1][0], buf, 1);

        wait(0);

        parent_pid = getpid();
        printf("%d: received pong\n", parent_pid);
    }
    exit(0);
}
```

## primes

Code could be cleaner !

```c=
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define NUMBER_UPPER_BOUND 35

int main()
{
    int ancestor = getpid(), a_idx = 2, g_p_idx = 0, pr, l_p_idx = 0;
    int p[256][2];
    int forked;

start:
    forked = 0;
    if (getpid() == ancestor)
        pr = a_idx++;
    else
    {
        close(p[l_p_idx-1][1]);
        read(p[l_p_idx-1][0], &pr, sizeof(pr));
    }
    printf("prime %d\n", pr);

    while (1)
    {
        int n;
        if (getpid() == ancestor)
        {
            n = a_idx++;
            if (n > NUMBER_UPPER_BOUND)
            {
                n = -1;
                write(p[l_p_idx][1], &n, sizeof(n));
                wait(0);
                exit(0);
            }
        }
        else
            read(p[l_p_idx-1][0], &n, sizeof(n));

        if (n == -1)
        {
            if (forked)
            {
                write(p[l_p_idx][1], &n, sizeof(n));
                wait(0);
            }
            exit(0);
        }

        if (n % pr)
        {
            if (!forked)
            {
                pipe(p[l_p_idx]);
                ++g_p_idx;
                if (fork() == 0)
                {
                    l_p_idx = g_p_idx;
                    goto start;
                }
                else
                {
                    l_p_idx = g_p_idx - 1;
                    close(p[l_p_idx][0]);
                }
                forked = 1;
            }
            write(p[l_p_idx][1], &n, sizeof(n));
        }
    }
}
```