# Thread

## What is a Thread?

A **thread** is the smallest unit of execution that a CPU can schedule and run. Understanding threads requires looking at them from two angles: **hardware** (how the CPU physically handles them) and **software** (how programs use them).

---

## Hardware Perspective

### The CPU Core — A Single Worker

Think of a CPU **core** as a **chef in a kitchen**:

```
┌─────────────────────────────────────────────┐
│                  CPU CORE                   │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │Registers │  │  ALU     │  │ Control  │  │
│  │(scratch  │  │(does the │  │  Unit    │  │
│  │  pad)    │  │  math)   │  │(the boss)│  │
│  └──────────┘  └──────────┘  └──────────┘  │
│                                             │
│        One instruction at a time...         │
└─────────────────────────────────────────────┘
```

A single core has **one set of registers** — one set of "hands". It can only work on **one stream of instructions** at a time.

> **Mnemonic:** CORE = **C**ooks **O**ne **R**ecipe at a tim**E**

---

### The Problem: The Core Gets Bored

When the CPU waits for memory (RAM is ~100x slower than the CPU), the core sits **idle**:

```
Timeline of a Single Thread:
─────────────────────────────────────────────────────────►
 [Work] [Work] [Wait for RAM...........] [Work] [Work]
                      ↑
               Core is doing nothing!
               Wasted cycles!
```

---

### Hardware Threading (SMT / Hyper-Threading)

The solution: give the core **two sets of registers** so it can hold the state of **two threads** simultaneously. When Thread A waits for memory, Thread B runs.

```
┌─────────────────────────────────────────────────────────┐
│                   CPU CORE (SMT)                        │
│                                                         │
│  ┌────────────────────┐  ┌────────────────────┐         │
│  │  THREAD SLOT A     │  │  THREAD SLOT B     │         │
│  │  ┌──────────────┐  │  │  ┌──────────────┐  │         │
│  │  │  Registers   │  │  │  │  Registers   │  │         │
│  │  │  (PC, SP,    │  │  │  │  (PC, SP,    │  │         │
│  │  │  flags, r0…) │  │  │  │  flags, r0…) │  │         │
│  │  └──────────────┘  │  │  └──────────────┘  │         │
│  └────────────────────┘  └────────────────────┘         │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │          SHARED EXECUTION UNITS                 │    │
│  │        ALU │ FPU │ Cache │ Branch Predictor     │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

Intel calls this **Hyper-Threading (HT)**. The generic term is **Simultaneous Multi-Threading (SMT)**.

> **Mnemonic:** SMT = **S**witch when **M**emory is **T**ardy

---

### What a Thread State IS in Hardware

The "state" of a hardware thread = everything the CPU needs to **resume** a computation:

```
THREAD STATE (the "bookmark")
┌────────────────────────────────────────┐
│  Program Counter (PC)  → next instruction address  │
│  Stack Pointer  (SP)   → top of the stack          │
│  General Registers     → r0, r1, r2… (scratch data)│
│  Flags Register        → zero? carry? overflow?    │
└────────────────────────────────────────────────────┘
```

> **Analogy:** The thread state is like a **bookmark + sticky note** in a book. The bookmark says where you are (PC). The sticky note has your math scribbles (registers). You can put it down and pick it up exactly where you left off.

---

### Physical Cores vs Logical Cores vs Threads

```
PHYSICAL CPU PACKAGE
┌──────────────────────────────────────────────────────┐
│                                                      │
│  Core 0 (Physical)          Core 1 (Physical)        │
│  ┌────────────────────┐    ┌────────────────────┐    │
│  │ Thread 0 │ Thread 1│    │ Thread 2 │ Thread 3│    │
│  │ (logical │ (logical│    │ (logical │ (logical│    │
│  │  core 0) │  core 1)│    │  core 2) │  core 3)│    │
│  └────────────────────┘    └────────────────────┘    │
│                                                      │
└──────────────────────────────────────────────────────┘

Result: 2 physical cores → 4 logical cores (OS sees 4 CPUs)
```

| Term | What it means |
|---|---|
| Physical Core | Actual silicon execution unit |
| Logical Core | A hardware thread slot (what the OS sees) |
| SMT / HT | Technology enabling multiple logical cores per physical core |

---

### Timeline: How SMT Fills the Gaps

```
WITHOUT SMT (1 thread per core):
Core ─────────────────────────────────────────────────────►
     [T1 work][T1 WAIT RAM.......][T1 work][T1 WAIT...]

WITH SMT (2 threads per core):
Core ─────────────────────────────────────────────────────►
     [T1 ][T2][T2][T2 WAIT.][T1][T1][T2][T1 WAIT.][T2]
          ↑ Thread 2 fills the gaps!
```

Performance gain is typically **15–30%**, not 100%, because the execution units are still shared.

---

## Memory Perspective

### Where Does a Thread Live in Memory?

Each thread gets its **own private stack**, but shares the **heap and code** with other threads in the same process:

```
PROCESS MEMORY LAYOUT (two threads)
┌─────────────────────────────────────────┐  High address
│           KERNEL SPACE                  │
├─────────────────────────────────────────┤
│         Stack — Thread 2                │  ← private to Thread 2
│             ↓ grows down                │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
│         (unmapped guard page)           │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
│         Stack — Thread 1 (main)         │  ← private to Thread 1
│             ↓ grows down                │
├─────────────────────────────────────────┤
│         Heap (shared by all threads)    │  ← shared, needs locks!
│             ↑ grows up                  │
├─────────────────────────────────────────┤
│  BSS  (uninitialized globals)           │  ← shared
│  Data (initialized globals)             │  ← shared
├─────────────────────────────────────────┤
│  Text (code / instructions)             │  ← shared (read-only)
└─────────────────────────────────────────┘  Low address
```

> **Mnemonic:** "Threads share the **house** (heap + code) but each has their own **room** (stack)."

---

## Software Perspective

### What a Thread is in Software

In software, a thread is an **independent sequence of instructions** managed by the OS scheduler. The OS gives each thread the **illusion** of its own CPU by rapidly switching between them (context switching).

```
OS SCHEDULER VIEW
                    Thread A ──────────►
                    Thread B ──────────►
                    Thread C ──────────►

Real CPU timeline (1 core, 3 threads):
─────────────────────────────────────────────────────────►
 [A][A][A][─switch─][B][B][─switch─][C][C][C][─switch─][A]
              ↑                ↑
        context save      context restore
        (save registers)  (load registers)
```

### Context Switch Cost

A **context switch** means:
1. Save current thread's registers to memory (Thread Control Block)
2. Load the next thread's registers from memory
3. (Sometimes) flush CPU caches — very expensive!

```
Thread Control Block (TCB) — stored in kernel memory
┌──────────────────────────────────┐
│  Thread ID                       │
│  State (running/waiting/ready)   │
│  Saved Registers (PC, SP, r0…)   │
│  Stack pointer                   │
│  Priority                        │
│  Pointer to parent process (PCB) │
└──────────────────────────────────┘
```

---

### Thread vs Process

```
PROCESS (heavy)                   THREAD (light)
┌─────────────────────┐           ┌──────────────────────┐
│ Own memory space     │           │ Shares memory space  │
│ Own file descriptors │           │ Shares file desc.    │
│ Own PCB              │           │ Own stack only       │
│ Expensive to create  │           │ Cheap to create      │
│ Expensive to switch  │           │ Cheap to switch      │
└─────────────────────┘           └──────────────────────┘

Switching process ≈ 1000–10000 ns
Switching thread  ≈ 100–1000  ns
```

---

### Thread States (Software Lifecycle)

```
              ┌──────────────────────────────────────┐
              │                                      │
            spawn                                  exit
              │                                      │
              ▼                                      │
          ┌───────┐   scheduler picks   ┌─────────┐  │
          │ READY │ ──────────────────► │ RUNNING │──┘
          └───────┘                     └─────────┘
              ▲                              │
              │     I/O done / lock free     │  waiting for I/O
              │                              │  or mutex lock
              │                              ▼
          ┌───────────────────────────────────────┐
          │                WAITING                │
          └───────────────────────────────────────┘
```

---

### Real Code Example (Rust)

```rust
use std::thread;

fn main() {
    // Spawn a new thread — OS creates a new TCB + allocates a stack
    let handle = thread::spawn(|| {
        println!("Hello from thread!");
    });

    // Main thread continues here (it's also a thread!)
    println!("Hello from main!");

    handle.join().unwrap(); // wait for the spawned thread to finish
}
```

---

### Why Threads Are Tricky: Shared Memory

Because threads share the heap, two threads can **race** to modify the same data:

```
Thread A:  read x (x=5) ──────────────────── write x=6
Thread B:              read x (x=5) ── write x=6
                                            ↑
                             Lost one increment! x should be 7.
```

This is a **data race** — the most common thread bug. Solutions: **Mutex**, **Atomic**, **Channels**.

---

## Summary — The Full Picture

```
Hardware:  Physical Core → SMT → Logical Cores (what OS sees)
OS:        Logical Core  → Scheduler → Thread slots
Software:  Thread        → Stack + TCB + shared heap

KEY INSIGHT:
  Hardware threads   = multiple register sets in one core
  Software threads   = independently scheduled code streams
  They map onto each other through the OS scheduler
```

---

## Questions for Review

Answer these to check your understanding. Think before expanding each one.

1. **A CPU is advertised as "8 cores / 16 threads." What does that mean in hardware terms? What technology makes this possible?**

2. **Why does SMT/Hyper-Threading give only ~15–30% speedup instead of 2× speedup?**

3. **What is the minimum information you need to "pause" a thread and "resume" it later? Where is this saved?**

4. **Two threads in the same process want to increment a shared counter. What can go wrong, and what is one way to fix it?**

5. **A thread is in the WAITING state. What event could move it to READY? Give two different examples.**

6. **What is the difference between a thread's stack and the process heap? Which is shared and which is private?**

7. **Why is switching between two threads in the same process faster than switching between two different processes?**

8. **If you `spawn` 1000 threads on a 4-core machine, how many can truly run at the exact same instant?**

9. **What is a context switch and why can it be expensive?**

10. **In hardware, what problem does SMT solve, and what is the root cause of that problem?**
