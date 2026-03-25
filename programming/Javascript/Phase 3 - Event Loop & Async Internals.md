# Phase 3 — Event Loop & Async Internals

> How a single-threaded runtime handles concurrency
> **Week:** 3 | **Status:** [ ] Complete

---

## Why This Phase Exists

You write async Node.js code every day. But there is a difference between knowing that `await` suspends execution and knowing *where the continuation goes and when it runs*. Misunderstanding this produces subtle ordering bugs: callbacks that fire in the wrong order, UI freezes, race conditions, and `Promise.all` misuse. For a backend engineer, the Node.js-specific event loop phases (and why `setImmediate` exists) are particularly important.

This phase removes the mystery from async JavaScript by making the scheduling rules explicit and mechanical.

---

## Core Concepts

### The JavaScript Concurrency Model

JavaScript is single-threaded: only one piece of code runs at a time. Concurrency is achieved by deferring work:

```
┌─────────────────────────────────────────────────────┐
│                   Call Stack                         │
│  (synchronous execution — one frame at a time)       │
└─────────────────────────────────────────────────────┘
         ↑ dequeues when stack is empty
┌──────────────────────┐   ┌───────────────────────┐
│   Microtask Queue    │   │   Macrotask Queue      │
│  (Promise .then,     │   │  (setTimeout,          │
│   queueMicrotask,    │   │   setInterval,         │
│   async continuations│   │   I/O callbacks,       │
│   MutationObserver)  │   │   setImmediate)        │
└──────────────────────┘   └───────────────────────┘
         ↑ callbacks registered by
┌──────────────────────────────────────────────────────┐
│           Web APIs / Node.js C++ Thread Pool         │
│   (timers, network, filesystem — NOT in JS thread)   │
└──────────────────────────────────────────────────────┘
```

### The Event Loop Algorithm

The event loop runs forever. Each iteration (tick):

1. Execute all synchronous code until the call stack is empty
2. **Drain the entire microtask queue** — run every microtask, including any microtasks added during this drain
3. Pick exactly **one** macrotask from the macrotask queue and run it
4. Drain the entire microtask queue again
5. (Browser only: render if needed)
6. Repeat

**Critical rule:** Microtasks drain completely before ANY macrotask runs — even microtasks added by other microtasks.

### Microtask Sources

- `Promise.then()` / `.catch()` / `.finally()`
- `queueMicrotask(fn)`
- `async/await` continuations (everything after an `await` is a microtask)
- `MutationObserver` callbacks (browser)

### Macrotask Sources

- `setTimeout(fn, delay)`
- `setInterval(fn, delay)`
- `setImmediate(fn)` (Node.js only)
- I/O callbacks (file read complete, network response received)
- UI event listeners (browser)
- `MessageChannel` messages

### Execution Order Example

```javascript
console.log('1 — sync');

setTimeout(() => console.log('5 — macrotask'), 0);

Promise.resolve()
  .then(() => console.log('3 — microtask 1'))
  .then(() => console.log('4 — microtask 2'));

queueMicrotask(() => console.log('2.5 — microtask queued directly'));

console.log('2 — sync');

// Output order:
// 1 — sync
// 2 — sync
// 2.5 — microtask queued directly
// 3 — microtask 1
// 4 — microtask 2
// 5 — macrotask
```

Why `4` before `5`: when microtask 1 runs, it schedules microtask 2. The drain continues — microtask 2 runs before any macrotask.

### Promise State Machine

A Promise has three states: `pending`, `fulfilled`, `rejected`. State transitions are irreversible.

```
pending ─── resolve(value) ──→ fulfilled
        ─── reject(reason) ──→ rejected
```

Even for an already-resolved Promise, `.then()` is always asynchronous — the callback is placed in the microtask queue, not called synchronously:

```javascript
const p = Promise.resolve(42);
p.then(v => console.log(v)); // queued as a microtask
console.log('this runs first'); // sync code runs first
// Output: "this runs first", then 42
```

### async/await Desugaring

`async` functions return a Promise. `await` suspends the function and schedules the continuation as a microtask when the awaited Promise settles.

```javascript
async function fetchData() {
  console.log('A');            // sync
  const data = await getUser(); // suspends — continuation is a microtask
  console.log('B');            // microtask — runs after getUser() resolves
  return data;
}

fetchData();
console.log('C');              // runs while fetchData is suspended

// Output: A, C, B
```

**Mental model:** `await expr` is equivalent to `return Promise.resolve(expr).then(continuation)`. Every line after `await` is a microtask continuation.

### Generators and async/await

`async/await` is implemented using generators. A generator is a coroutine — a function that can be paused and resumed:

```javascript
// async/await is syntactic sugar over this generator machinery:
function* fetchDataGen() {
  const data = yield getUser(); // yield = pause point
  return data;
}

// The async runtime calls gen.next() when the yielded Promise resolves
```

Understanding this explains why `async` functions always return Promises and why `await` can only be used inside `async` functions.

### Node.js Event Loop Phases

Node.js has a more structured event loop with distinct phases (using libuv):

```
   ┌───────────────────────────┐
┌─>│        timers             │  setTimeout, setInterval callbacks
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
│  │     pending callbacks     │  I/O callbacks deferred from previous tick
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
│  │     idle, prepare         │  internal use only
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
│  │           poll            │  retrieve new I/O events; execute I/O callbacks
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
│  │           check           │  setImmediate callbacks
│  └─────────────┬─────────────┘
│  ┌─────────────┴─────────────┐
└──┤      close callbacks      │  socket.on('close', ...)
   └───────────────────────────┘
   ↑ microtasks run between each phase transition
```

**Key insight:** `setImmediate` runs in the **check** phase, which comes AFTER the **poll** phase (where I/O callbacks execute). So inside an I/O callback, `setImmediate` ALWAYS fires before `setTimeout(fn, 0)` (which waits for the **timers** phase on the next iteration).

At the top level (not inside I/O): `setTimeout(fn, 0)` vs `setImmediate` order is **non-deterministic** — depends on the state of the event loop at startup time.

### Common Async Pitfalls

**Sequential awaits that should be parallel:**
```javascript
// SLOW: sequential — waits for each before starting the next
const user    = await getUser(id);
const orders  = await getOrders(id);
const profile = await getProfile(id);

// FAST: parallel — all three start simultaneously
const [user, orders, profile] = await Promise.all([
  getUser(id), getOrders(id), getProfile(id)
]);
```

**`await` inside `forEach` — does NOT work as expected:**
```javascript
// BUG: forEach does not await the async callbacks
const ids = [1, 2, 3];
ids.forEach(async (id) => {
  await processId(id); // the forEach callback is async, but forEach ignores the returned Promise
});
console.log('done'); // prints immediately — processing hasn't finished

// FIX: use Promise.all with map
await Promise.all(ids.map(async (id) => processId(id)));
console.log('done'); // prints after all are processed
```

**Promise.all vs Promise.allSettled vs Promise.race vs Promise.any:**

| Method | Resolves when | Rejects when |
|---|---|---|
| `Promise.all` | ALL fulfill | ANY rejects (fast-fail) |
| `Promise.allSettled` | ALL settle (either way) | Never |
| `Promise.race` | FIRST settles (either) | FIRST rejects (if first to settle rejects) |
| `Promise.any` | FIRST fulfills | ALL reject (AggregateError) |

---

## Go Deep On

### Why `Promise.resolve().then(fn)` is always async

Even though the Promise is already resolved, `.then(fn)` never calls `fn` synchronously. The spec requires that Promise callbacks are always scheduled as microtasks. This is a design choice to ensure consistent behavior — a Promise returned from an API should always behave the same whether it's resolved synchronously or asynchronously.

```javascript
let x = false;
Promise.resolve().then(() => { x = true; });
console.log(x); // false — the .then callback hasn't run yet
// After current sync code finishes: x becomes true
```

### Nested Promise output order

```javascript
Promise.resolve()
  .then(() => {
    console.log('A');
    return Promise.resolve('inner');
  })
  .then(v => console.log('B', v));

Promise.resolve()
  .then(() => console.log('C'));

// Output: A, C, B inner
```

**Why?** When `.then` returns a Promise (not a plain value), the next `.then` is NOT immediately queued. The engine must wait for the returned Promise to settle, which involves two extra microtask steps. `C` is queued in the same microtask batch as `A`, so it runs before `B`.

### `setImmediate` vs `setTimeout(fn, 0)` inside I/O

```javascript
const fs = require('fs');
fs.readFile('/etc/hosts', () => {
  setTimeout(() => console.log('timeout'), 0);
  setImmediate(() => console.log('immediate'));
});
// Always: immediate, timeout
// Because inside I/O callback: we're in poll phase → check phase comes next → setImmediate fires first
```

---

## Checkpoint

You must demonstrate ALL of the following before moving to Phase 4.

**Checkpoint 1 — Output prediction**
Given a 30-line snippet mixing synchronous code, `Promise.resolve().then()`, `setTimeout(fn,0)`, `setImmediate()`, `queueMicrotask()`, and nested `.then()` chains — predict the exact output order before running it. Explain each step by naming which queue the callback is in and when it drains.

**Checkpoint 2 — `promisePool(tasks, concurrency)`**
Implement `promisePool(tasks, concurrency)`: runs an array of async task functions with at most N running concurrently at any time. As soon as one completes, the next starts. Returns a Promise that resolves when all tasks complete.

Acceptance criteria:
- Exactly N tasks run simultaneously (no more, no less until the queue is exhausted)
- Tasks are started in order
- If any task rejects, the error propagates (you decide whether to fail-fast or collect errors)

**Checkpoint 3 — `withTimeout(promise, ms)`**
Implement `withTimeout(promise, ms)`: returns a Promise that:
- Resolves/rejects with the original result if it settles within `ms`
- Rejects with a `TimeoutError` if it does not
- Does NOT leave dangling Promises (the original promise is still awaited/settled)

**Checkpoint 4 — `retry(fn, maxAttempts, delayMs)`**
Implement `retry(fn, maxAttempts, delayMs)`:
- Retries a failing async function with exponential backoff (`delayMs * 2^attempt`)
- Does NOT retry if the error has a `nonRetryable: true` property
- Rejects with the last error after maxAttempts

**Checkpoint 5 — Node.js vs browser event loop**
Explain the difference between Node.js's event loop phases and the browser's event loop. Specifically: where does `setImmediate` fit, why doesn't it exist in the browser, and why does `setImmediate` fire before `setTimeout(fn,0)` inside an I/O callback?

---

## Connection to Your Background

- **Node.js:** You know the event loop exists. This phase gives you the exact phases and guarantees. When you use `setImmediate` vs `process.nextTick` vs `setTimeout(fn,0)` — now you know exactly what each means.
- **Rust async:** Rust's `async/await` uses a similar model — futures are polled when their waker signals readiness. The difference: Rust's executor is explicit (Tokio), JavaScript's is built into the runtime. Both suspend at `await` points; both schedule continuations.
- **Backend concurrency:** `Promise.all` is your parallel fan-out. `promisePool` is your rate-limited fan-out. These patterns map directly to controlling concurrency in backend services — exactly what you do with MongoDB bulk operations or SISALRIL API calls.

---

## After Completing This Phase

1. What was the hardest part of Phase 3, and what specifically made it hard?
2. How would you explain the difference between the microtask queue and the macrotask queue to a developer who has been writing JavaScript for two years but never thought about the engine?

Then move to [[Phase 4 - Prototypes & Object Model]].
