---
title: Chapter 1
date: 2022-07-04
menu:
    sidebar:
        name: Chapter 1
        identifier: os-exercise-ch1
        parent: os-exercise
---

## 1.

```c=
#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>
#include <sys/time.h>

#define PING_PONG_LENTH 100000
#define timelen(ST, ED) ((ED).tv_sec - (ST).tv_sec + (((ED).tv_usec - (ST).tv_usec) / 1000000.0))

int main()
{
    int p[2][2];
    struct timeval st, ed;

    pipe(p[0]);
    pipe(p[1]);

    if (fork() == 0) // child
    {
        close(p[1][0]);
        close(p[0][1]);

        char buf[1];

        gettimeofday(&st, 0);
        for (int i = 0; i < PING_PONG_LENTH; ++i)
        {
            read(p[0][0], buf, 1);
            write(p[1][1], buf, 1);
        }
        gettimeofday(&ed, 0);

        close(p[0][0]);
        close(p[1][1]);

        printf("Child time elapsed: %.3lf\n", timelen(st,ed));
    }
    else // parent
    {
        close(p[1][1]);
        close(p[0][0]);

        char buf[1] = "0";

        gettimeofday(&st, 0);
        for (int i = 0; i < PING_PONG_LENTH; ++i)
        {
            write(p[0][1], buf, 1);
            read(p[1][0], buf, 1);
        }
        gettimeofday(&ed, 0);

        close(p[0][1]);
        close(p[1][0]);

        wait(0);

        printf("Parent time elapsed: %.3lf\n", timelen(st,ed));
        double cps = (double)PING_PONG_LENTH / timelen(st,ed);
        printf("Changes Per Second: %.3lf\n", cps);
    }

    return 0;
}
```