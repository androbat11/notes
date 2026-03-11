# Event Loop & Concurrency

## What is the Event Loop?

The **event loop** is a programming construct that waits for and dispatches events or messages in a program. It continuously monitors a **call stack** and a **task queue**, executing tasks when the stack is empty.

```
┌─────────────────────────────────────────────┐
│                  Call Stack                  │
│  (executes synchronous code, one at a time) │
└───────────────────────┬─────────────────────┘
                        │ stack empty?
                        ▼
┌─────────────────────────────────────────────┐
│               Event Loop                    │
│   checks queues and pushes callbacks onto   │
│   the call stack when it's empty            │
└────────────┬──────────────────┬─────────────┘
             │                  │
             ▼                  ▼
┌────────────────┐   ┌──────────────────────┐
│  Microtask     │   │    Macrotask Queue   │
│  Queue         │   │  (setTimeout, I/O,  │
│ (Promises,     │   │   setInterval...)    │
│  queueMicro-   │   └──────────────────────┘
│  task)         │
└────────────────┘
  (higher priority — fully drained before macrotasks)
```

### Core Components

| Component | Description |
|---|---|
| **Call Stack** | LIFO structure; executes one frame at a time |
| **Heap** | Unstructured memory for object allocation |
| **Web APIs / OS** | Browser or Node.js APIs that handle async work (timers, I/O, network) |
| **Microtask Queue** | High-priority queue: Promise callbacks, `queueMicrotask()`, `MutationObserver` |
| **Macrotask Queue** | Lower-priority: `setTimeout`, `setInterval`, I/O callbacks, `setImmediate` (Node.js) |

---

## Event Loop Tick

Each iteration of the event loop (a "tick") follows this order:

1. Execute all synchronous code on the call stack until it's empty.
2. Drain the **microtask queue** completely (run all microtasks, including any new ones added during this step).
3. Render/paint (browser only, if applicable).
4. Pick **one** macrotask from the macrotask queue and execute it.
5. Go back to step 2.

```js
console.log("1");                           // sync

setTimeout(() => console.log("2"), 0);     // macrotask

Promise.resolve().then(() => console.log("3")); // microtask

console.log("4");                           // sync

// Output: 1, 4, 3, 2
```

---

## Concurrency vs Parallelism

| Concept | Definition |
|---|---|
| **Concurrency** | Multiple tasks make progress by interleaving — not necessarily at the same time |
| **Parallelism** | Multiple tasks literally execute at the same instant (requires multiple CPU cores) |

The event loop enables **concurrency without parallelism** — a single thread handles many tasks by never blocking; it delegates waiting work (I/O, timers) to the OS/runtime and picks up results when ready.

---

## How the Event Loop Achieves Concurrency

Languages like JavaScript (and other single-threaded runtimes) achieve concurrency via:

1. **Non-blocking I/O**: Instead of waiting for a file read or network request, the runtime delegates the work to the OS and registers a callback.
2. **Callbacks / Promises / async-await**: Mechanisms to resume execution when async work is done.
3. **Cooperative multitasking**: Tasks voluntarily yield control by returning from the call stack, allowing the event loop to run other work.

```js
// Without event loop (blocking, sequential)
const data = readFileSync("file.txt");   // blocks entire thread
process(data);

// With event loop (non-blocking, concurrent)
readFile("file.txt", (data) => {         // registers callback, returns immediately
  process(data);                         // runs later when file is ready
});
doOtherWork();                           // runs while file is being read
```

---

## Event Loop in Different Runtimes

### Browser (JavaScript)
- Single-threaded JS engine (V8, SpiderMonkey).
- Web Workers provide true parallelism via separate threads (no shared memory by default, communicate via `postMessage`).
- `requestAnimationFrame` is processed before rendering, after microtasks.

### Node.js
- Uses **libuv** as its event loop implementation.
- Has additional phases beyond browser: `timers → I/O callbacks → idle/prepare → poll → check (setImmediate) → close callbacks`.
- Worker Threads (`worker_threads` module) allow parallelism.

### Python (asyncio)
- `asyncio` event loop runs coroutines on a single thread.
- `async/await` syntax; coroutines yield at `await` points.
- True parallelism via `multiprocessing` (bypasses GIL) or `ThreadPoolExecutor` for I/O-bound work.

---

## async/await — Syntactic Sugar

`async/await` is syntax built on top of Promises/coroutines that makes async code look synchronous:

```js
// Promise chain
fetch(url)
  .then(res => res.json())
  .then(data => console.log(data))
  .catch(err => console.error(err));

// Equivalent with async/await
async function getData() {
  try {
    const res = await fetch(url);   // suspends here, yields to event loop
    const data = await res.json();
    console.log(data);
  } catch (err) {
    console.error(err);
  }
}
```

`await` does NOT block the thread — it suspends the current async function and returns control to the event loop.

---

## Common Pitfalls

- **Blocking the event loop**: Running CPU-intensive synchronous code (large loops, crypto, image processing) starves all other tasks. Offload to worker threads.
- **Microtask starvation**: Infinite chain of microtasks (Promise resolving a Promise) blocks macrotasks and rendering forever.
- **Callback hell**: Deeply nested callbacks; solved by Promises and async/await.
- **Race conditions**: Even in single-threaded environments, async code can produce race conditions if shared state is mutated across `await` points.

---

## Key Takeaways

- The event loop is what allows a **single thread** to handle **many concurrent operations**.
- It achieves this by never blocking — async work is delegated to the runtime/OS, results are picked up later via callbacks.
- **Microtasks** (Promises) always run before **macrotasks** (setTimeout, I/O).
- Concurrency ≠ Parallelism; the event loop gives you concurrency without needing multiple threads.
