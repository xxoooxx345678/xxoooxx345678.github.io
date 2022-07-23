---
title: 'OS organization and system calls'
description: None
date: 2022-07-18
menu:
    sidebar:
        name: 'OS organization and system calls'
        identifier: lec3
        parent: notes
---

## Chapter 2 : Operating system organization

An operating system must fulfill three requirements: `multiplexing`, `isolation`, and `interaction`

### 2.1 Abstracting physical resources

Why do we need operating system ? <br>
One could implement the system calls as a library, then each app could even have its own library tailored to its needs. <br>
Apps could directly interact with HW resources and use those resources int the best way for apps. (OS for `Embedded devices` or `real-time systems`) <br>
The downside of this approach is, `multiplexing` will be troublesome. <br>

To achieve strong isolation it’s helpful to forbid applications from directly accessing sensitive hardware resources, <br> and instead to abstract the resources into services.

### 2.2 User mode, supervisor mode, and system calls

Strong `isolation` requires a hard boundary between applications and the operating system, the operating system must arrange that applications cannot modify the OS's data structures and instructions and that applications cannot access other processes' memory.

RISC-V has three modes in which CPU can execute instructions: `machine mode`, `supervisor mode`, and `user mode` <br>
- `machine mode`
  - execute with full privilege
  - CPU starts in machine mode
  - mostly intended for configuring a computer
- `supervisor mode`
  - allowed to execute *privilege instructions* (***kernel space***)
    - enabling/disabling interrupt
    - reading/writing register that holds the address of page table
- `user mode`
  - an application can only execute only user-mode instructions (***user space***)

### 2.3 Kernel Organization

A key design question is what part of the operating system should run in supervisor mode
- `Monolithic kernel`
  - Implementation:
    - entire operating system resides in the kernel, so all the system calls run in supervisor mode
    - operating system runs with full privilege
  - Upsides:
    - convenient, OS designer doesn't have to decide which part of operating system need full hardware privilege
    - different parts of the operating system are easier to cooperate
  - Downsides:
    - interfaces between different parts of the operating system are often complex
    - easy to make mistake, and mistake is fatal in supervisor mode
- `Microkernel`
  - Implementation:
    - minimize the amount of operating system code that runs in supervisor mode
    - kernel provides inter-process communication mechanism to send messages from one user-mode process to another
    - kernel interface consists of few low-level function for starting application
      - sending messages, accessing device hardware, etc.
  - Upsides:
    - small and isolated
    - expansion of the system is easier
  - Downsides:
    - IPC takes time