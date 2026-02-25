
## What is Concurrent Programming?

**Concurrent programming** is a way of structuring a program so that multiple tasks can be **in progress at the same time**.

> It does NOT necessarily mean they run at the exact same instant — it means the system is **dealing with many things at once**, switching between them or truly running them in parallel.

---

## The Coffee Shop Analogy

Imagine a coffee shop:

```
SEQUENTIAL (one barista, one customer at a time):

  Barista ──► Customer A (order + make + serve)
           ──► Customer B (order + make + serve)
           ──► Customer C (order + make + serve)

  Customers B and C wait the entire time. Very slow.


CONCURRENT (one barista, juggling multiple orders):

  Barista ──► takes order A ──► starts brewing A
           ──► takes order B ──► starts brewing B   (while A brews)
           ──► serves A ──► serves B

  The barista switches between tasks while waiting.
  Total time is much shorter.


PARALLEL (multiple baristas at the same time):

  Barista 1 ──► Customer A (order + make + serve)
  Barista 2 ──► Customer B (order + make + serve)   ← truly simultaneous
  Barista 3 ──► Customer C (order + make + serve)
```

**Concurrency** = dealing with many things at once (structure).
**Parallelism** = doing many things at the exact same instant (execution).

Concurrency enables parallelism, but they are not the same thing.

---

## Sequential vs Concurrent — Side by Side

```
SEQUENTIAL PROGRAM                  CONCURRENT PROGRAM
──────────────────                  ──────────────────

Task A: ██████████                  Task A: ████░░░░██
Task B:           ██████████        Task B: ░░░░████░░████
Task C:                     ██████  Task C: ██░░░░░░████░░██

Time ──────────────────────────►    Time ──────────────────────────►

█ = working   ░ = waiting/idle      Much shorter total wall-clock time
```

---

## Where Does Concurrency Happen?

```
┌─────────────────────────────────────────────────────────┐
│                    Your Program                          │
│                                                          │
│   Thread 1 ──► handles HTTP request from User A         │
│   Thread 2 ──► handles HTTP request from User B         │
│   Thread 3 ──► reads a file from disk                   │
│   Thread 4 ──► queries the database                     │
│                                                          │
│   All of these are "in flight" at the same time.        │
└─────────────────────────────────────────────────────────┘
```

Without concurrency, User B waits for User A's request to fully complete before the server even looks at them.

---

## Core Concepts

### 1. Thread

A **thread** is an independent sequence of execution inside a process. Multiple threads share the same memory.

```
Process
├── Thread 1 ──► runs function A
├── Thread 2 ──► runs function B     ← all share the same heap/globals
└── Thread 3 ──► runs function C
```

### 2. Process

A **process** is a fully isolated program instance. Processes do NOT share memory by default.

```
OS
├── Process A (your app)     ┐
│   ├── Thread 1             │ isolated memory space
│   └── Thread 2             ┘
│
└── Process B (another app)  ┐
    ├── Thread 1             │ isolated memory space
    └── Thread 2             ┘
```

### 3. Async / Non-blocking I/O

Instead of blocking a thread while waiting for slow I/O (disk, network), the thread registers a callback and moves on to other work.

```
BLOCKING (thread sits idle):

  Thread: ──► send request ──► [waiting............] ──► handle response


NON-BLOCKING (thread keeps working):

  Thread: ──► send request ──► do other work ──► do other work ──► handle response
                         ↑                                        ↑
                    registers callback                      callback fires
```

This is what `async/await` does in JavaScript, Python, Rust, etc.

---

## Real-World Examples

### Web Server handling multiple users

```
                    ┌────────────────────────┐
  User A ──────────►│                        │──► Thread/Task A ──► DB query
  User B ──────────►│   Concurrent Server    │──► Thread/Task B ──► file read
  User C ──────────►│                        │──► Thread/Task C ──► API call
                    └────────────────────────┘

  All 3 users get a response concurrently, not one after another.
```

### Downloading files simultaneously

```
SEQUENTIAL:                         CONCURRENT:

  File 1: ████████████              File 1: ████████████
  File 2:             ████████████  File 2: ████████████
  File 3:                         … File 3: ████████████
                                             ↑
  Total: 3x longer                    All download at the same time
```

### UI remaining responsive

```
Without concurrency:                With concurrency:

  UI Thread: ██████████████         UI Thread:  ████████████████  ← always responsive
  (frozen while computing)          Work Thread: ██████████████   ← heavy work here

  User clicks button → nothing      User clicks button → works immediately
```

---

## The Main Challenges

Concurrency introduces new categories of bugs that don't exist in sequential code.

### Race Condition

Two tasks read and write shared data at the same time, producing wrong results.

```
Shared variable: balance = 100

Thread A reads balance  → 100
Thread B reads balance  → 100         ← both read before either writes
Thread A writes balance → 100 + 50 = 150
Thread B writes balance → 100 + 30 = 130  ← overwrites A's result!

Final balance: 130  (should be 180)
```

### Deadlock

Two tasks each wait for the other to release a resource — both freeze forever.

```
Thread A holds Lock 1, waiting for Lock 2
Thread B holds Lock 2, waiting for Lock 1

    A ──► waiting for Lock 2 ──► held by B
    B ──► waiting for Lock 1 ──► held by A

    Neither can proceed. Program hangs.
```

### Solutions

```
┌──────────────────┬──────────────────────────────────────────┐
│ Problem          │ Common Solution                          │
├──────────────────┼──────────────────────────────────────────┤
│ Race condition   │ Mutex / lock — only one thread at a time │
│ Race condition   │ Atomic operations                        │
│ Race condition   │ Immutable data (no shared mutable state) │
│ Deadlock         │ Always acquire locks in the same order   │
│ Deadlock         │ Use timeouts on lock acquisition         │
│ Both             │ Message passing (share by communicating) │
└──────────────────┴──────────────────────────────────────────┘
```

---

## Concurrency Models

Different languages solve this differently:

```
┌──────────────────┬─────────────────────────────────────────────────────┐
│ Model            │ How it works                                         │
├──────────────────┼─────────────────────────────────────────────────────┤
│ OS Threads       │ True parallel threads, shared memory                 │
│ (Java, C++)      │ You manage locks manually                            │
│                  │                                                      │
│ Async / Await    │ Single thread, non-blocking I/O, event loop          │
│ (JS, Python)     │ Great for I/O-bound work, not CPU-bound              │
│                  │                                                      │
│ Goroutines       │ Lightweight threads managed by the runtime           │
│ (Go)             │ Communicate via channels, not shared memory          │
│                  │                                                      │
│ Actor Model      │ Each actor has its own state, communicates by msgs   │
│ (Erlang, Akka)   │ No shared memory at all                              │
│                  │                                                      │
│ Ownership System │ Compiler prevents data races at compile time         │
│ (Rust)           │ No runtime cost, no GC                               │
└──────────────────┴─────────────────────────────────────────────────────┘
```

---

## Deep Dive: Concurrency Through Timing (Not Threads)

This is the most important distinction to internalize.

### Two completely different mechanisms

```
PARALLELISM (CPU threads / cores)              CONCURRENCY (timing / scheduling)
──────────────────────────────────             ──────────────────────────────────

CPU Core 1: ██████████████████████             Single thread: ██░░░░██░░░░░░░████
CPU Core 2: ██████████████████████
                                               ░ = thread is idle, waiting for I/O
Truly simultaneous. Needs hardware.
                                               No extra CPU needed. Pure scheduling.
```

The user's insight: **concurrency is about timing** — who finishes waiting first gets to run next.

---

### What actually happens during I/O

When your program talks to a database, disk, or network — the CPU does almost nothing. It sends a request and then sits waiting for data to come back.

```
Thread handling Request A:

  t=0ms   ──► sends DB query
  t=1ms   ──► [waiting.............................................]
  t=100ms ──► DB responds, thread processes result and replies

  The thread is IDLE for 99ms out of 100ms.
  That idle time is what concurrency exploits.
```

---

### The Event Loop — Single Thread, Multiple Tasks

Instead of blocking the thread, the program registers tasks and lets a **scheduler** (event loop) decide who runs when, based on who is ready.

```
          ┌──────────────────────────────────────────┐
          │              EVENT LOOP                  │
          │                                          │
          │   Checks: "Who is ready to run?"         │
          │   Runs that task until it hits a wait.   │
          │   Repeats.                               │
          └──────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│  TIME ──────────────────────────────────────────────────────────►│
│                                                                  │
│  Request A: ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██                  │
│             ↑                               ↑                    │
│          starts DB query              DB responds (t=100ms)      │
│                                                                  │
│  Request B:    ██░░░░░░░░░░░░░░░░░░░░░░░░██                     │
│                ↑                        ↑                        │
│             starts DB query        DB responds (t=90ms)          │
│                                                                  │
│  Request C:       ██░░░░░░░░░░░░░░░░░░░░████                    │
│                   ↑                    ↑                         │
│                starts query      DB responds (t=80ms)            │
│                                                                  │
│  Thread:    ██  ██  ██  [idle.............] C finishes B  A      │
│                                             ↑   ↑       ↑  ↑    │
│                                      whoever finished first runs │
└──────────────────────────────────────────────────────────────────┘
```

**C finishes first (80ms), so C runs first. Then B (90ms). Then A (100ms).** The single thread processes them in order of completion, not order of arrival.

---

### Step by Step — Two Requests Racing

```
t=0ms    Request A arrives → sends DB query (will take 2000ms)
t=0ms    Thread is now free → immediately picks up Request B
t=0ms    Request B arrives → sends DB query (will take 1500ms)
t=0ms    Thread is now free → idles, waiting for whoever finishes first

                 [both queries running on the DB server simultaneously]

t=1500ms Request B's DB response arrives → thread wakes up → processes B → sends reply
t=1500ms Thread is free again → goes back to waiting

t=2000ms Request A's DB response arrives → thread wakes up → processes A → sends reply

Total wall-clock time: 2000ms  (not 3500ms like sequential would be)
```

The thread never ran two things at the same time. It just never wasted time sitting idle.

---

### Why This Works — CPU vs I/O Time

```
Breakdown of a typical web request:

  Parse request:     ~1ms   ← CPU work
  DB query:        ~100ms   ← waiting (network + DB)
  Format response:   ~1ms   ← CPU work
  Send response:     ~1ms   ← waiting (network)

  Total: 103ms, but only 3ms of actual CPU usage.
  The other 100ms the thread could be doing other things.
```

```
I/O-BOUND task (network, disk, DB):          CPU-BOUND task (image processing, crypto):

  CPU  ████░░░░░░░░░░░░░░░░░░░░░░░████         CPU  ████████████████████████████████
  I/O  ░░░░████████████████████████░░░░         I/O  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

  Mostly waiting → concurrency helps a lot     Mostly computing → concurrency helps little
  async/await is ideal here                    real parallel threads (CPU cores) needed here
```

---

### The Scheduler's Decision Loop

```
while program_is_running:

    for each task in waiting_tasks:
        if task.is_ready():       ← "did the I/O finish?"
            run(task)             ← give it the thread until next wait point
            break

    sleep_until_something_is_ready()
```

This is literally what Node.js's event loop, Python's asyncio, and most async runtimes do.

---

### async/await — Syntax That Expresses This

`await` is the keyword that says: *"I'm going to wait for this. Give the thread to someone else until I get a result."*

```
async function handleRequest(req) {
    const user = await db.query(...)   // ← releases thread here
    const data = await fetch(...)      // ← releases thread here again
    return format(user, data)          // ← CPU work, keeps thread
}
```

```
Timeline:

  handleRequest A: ██░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░██
                   ↑ await db         ↑ await fetch         ↑ format+return

  handleRequest B:    ██░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░██

  Thread:          ██  ██               ██  ██               ██  ██
                   A   B                A   B                A   B
```

Every `await` is a hand-off point. The scheduler picks whoever is ready next.

---

## Key Takeaways

- **Concurrent programming** = structuring a program to handle multiple tasks at once
- **Concurrency ≠ Parallelism** — concurrency is about structure, parallelism is about simultaneous execution
- A **thread** shares memory with others; a **process** is fully isolated
- **Async/await** achieves concurrency on a single thread by not blocking during I/O
- The main dangers are **race conditions** (corrupted data) and **deadlocks** (frozen program)
- The safest approach: avoid shared mutable state — use message passing or immutable data

---

## Review Questions

**Q1.** What is the difference between concurrency and parallelism? Give a real-world analogy.

**Q2.** A program downloads 5 files sequentially. Each file takes 2 seconds. How long does it take? What if it downloads them concurrently? What is the best-case time?

**Q3.** Two threads share a counter starting at 0. Both do `counter = counter + 1` at the same time. What can go wrong, and what is this bug called?

**Q4.** Thread A acquires Lock 1 then tries to acquire Lock 2. Thread B acquires Lock 2 then tries to acquire Lock 1. What happens, and what is this called?

**Q5.** What is the key difference between thread-based concurrency and async/await concurrency? In what scenario is each one better suited?

**Q6.** You're building a web server. A request comes in that needs to query a database (takes ~100ms). Should you block the thread while waiting for the DB response? What should you do instead and why?

**Q7.** Go's concurrency motto is: *"Do not communicate by sharing memory; share memory by communicating."* What does this mean in practice?
