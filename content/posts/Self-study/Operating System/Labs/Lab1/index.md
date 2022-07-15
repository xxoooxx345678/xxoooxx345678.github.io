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
```c {linenos=table}
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
```c {linenos=table}
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

```c {linenos=table}
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

## find

```c {linenos=table}
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

char *get_file_name(char *path)
{
    static char buf[DIRSIZ + 1];
    char *p;

    // Find first character after last slash.
    for (p = path + strlen(path); p >= path && *p != '/'; p--)
        ;
    p++;

    strcpy(buf, p);
    return buf;
}

void _find(char *path, char *target)
{
    char buf[512], *p;
    int fd;
    struct dirent de;
    struct stat st;

    if ((fd = open(path, 0)) < 0)
    {
        fprintf(2, "find: cannot open %s\n", path);
        return;
    }

    if (fstat(fd, &st) < 0)
    {
        fprintf(2, "find: cannot stat %s\n", path);
        close(fd);
        return;
    }

    switch (st.type)
    {
        case T_FILE:
            fprintf(2, "find: starting-point is a file %s\n", path);
            break;
        
        case T_DIR:
            strcpy(buf, path);
            p = buf + strlen(buf);
            *p++ = '/';
            while (read(fd, &de, sizeof(de)) == sizeof(de))
            {
                if (de.inum == 0)
                    continue;
                memmove(p, de.name, DIRSIZ);
                p[DIRSIZ] = 0;
                if (stat(buf, &st) < 0)
                {
                    printf("find: cannot stat %s\n", buf);
                    continue;
                }
                char fname[512];
                strcpy(fname, get_file_name(buf));

                if (strcmp(fname, ".") == 0 || strcmp(fname, "..") == 0)
                    continue;

                if (strcmp(fname, target) == 0)
                    printf("%s/%s\n", path, target);
                else
                {
                    if (st.type == T_DIR)
                        _find(buf, target);
                }
            }
            break;
    }
    close(fd);
}

int main(int argc, char *argv[])
{
    _find(argv[1], argv[2]);
    exit(0);
}
```

## xargs

[Reference](https://github.com/PKUFlyingPig/MIT6.S081-2020fall/blob/util/user/xargs.c) of function `int readline(char *argv[MAXARG], int start)`

```c {linenos=table}
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/param.h"

void forkexec(char *cmd, char **argv)
{
    if (fork() == 0)
    {
        exec(cmd, argv);
        exit(1);
    }
    else
        wait(0);
}

int readline(char *argv[MAXARG], int start)
{
    char buf[1024];
    int n = 0;
    while (read(0, buf+n, 1))
    {
        if (buf[n] == '\n')
            break;
        ++n;
    }
    buf[n] = 0;
    if (n == 0)
        return 0;
    int x = 0;
    while (x < n)
    {
        argv[start++] = buf + x;
        while (buf[x] != ' ' && x < n)
            ++x;
        while (buf[x] == ' ' && x < n)
            buf[x++] = 0;
    }
    return start;
}

int main(int argc, char *argv[])
{
    char *cmd = (char *)malloc(512*sizeof(char));
    strcpy(cmd, argv[1]);

    char *new_argv[MAXARG];
    for (int i = 0; i < MAXARG; ++i)
        new_argv[i] = (char *)malloc(512*sizeof(char));
    
    int argv_start_idx = 0;
    for (int i = 1; i < argc; ++i)
        strcpy(new_argv[argv_start_idx++], argv[i]);


    int curr_argv_idx;
    while ((curr_argv_idx = readline(new_argv, argc-1)) != 0)
    {
        new_argv[curr_argv_idx] = 0;
        forkexec(cmd, new_argv);
    }

    exit(0);
}
```