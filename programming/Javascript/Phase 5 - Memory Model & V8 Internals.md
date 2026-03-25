# Phase 5 — Memory Model & V8 Internals

> How the engine allocates, optimizes, and garbage collects
> **Week:** 5 | **Status:** [ ] Complete

---

## Why This Phase Exists

You already know what garbage collection is — you came from Rust, where GC doesn't exist and you've felt the difference. This phase is about understanding what V8 specifically does: how it allocates, why it has two generations of GC, and — critically — how it optimizes your code using hidden classes and JIT compilation, and how you accidentally break those optimizations.

Performance bugs in JavaScript often come from code that looks correct but violates V8's assumptions. This phase makes you able to look at a hot function and predict whether V8 can optimize it.

---

## Core Concepts

### Stack vs Heap

**Stack:** Fast, fixed-size, LIFO. Each execution context (function call) pushes a stack frame. Primitives (numbers, booleans, strings — actually stored elsewhere but referenced cheaply) live in the frame. When the function returns, the frame is popped — instant deallocation.

**Heap:** Dynamic-size, garbage collected. Objects, arrays, functions, and closures live here. The GC decides when to reclaim them.

**Pass by value vs reference:**
```javascript
// Primitives: copied by value
let a = 42;
let b = a;
b = 99;
console.log(a); // 42 — b got a copy

// Objects: the reference is copied by value
let obj1 = { x: 1 };
let obj2 = obj1; // obj2 holds the SAME reference, not a copy
obj2.x = 999;
console.log(obj1.x); // 999 — same object

// Reassigning obj2 does NOT affect obj1:
obj2 = { x: 0 };
console.log(obj1.x); // 999 — obj1 still points to the original object
```

JavaScript does NOT have true pass-by-reference. Objects are passed by "reference copied by value" — the reference is copied, but both copies point to the same heap object.

### Generational Garbage Collection

V8 divides the heap into two generations based on object age:

**Young generation (new space / nursery):**
- New objects are allocated here first
- Collected frequently using the **Scavenge** algorithm (fast, stop-the-world but brief)
- Survivors of 2+ collections are promoted to old generation
- Small size (~1-8 MB) — minor GC is fast because there's little to scan

**Old generation (old space):**
- Long-lived objects live here
- Collected infrequently using **Mark-Sweep-Compact** (slower, but less frequent)
- Mark phase: trace from GC roots, mark all reachable objects
- Sweep phase: reclaim unmarked memory
- Compact phase: defragment memory (move live objects together)

**Why two generations?** Most objects die young (the "generational hypothesis"). Minor GC is cheap because it only scans the small new space. Major GC is expensive but rare.

**Incremental and concurrent GC:** Modern V8 spreads major GC work across multiple increments and uses background threads to minimize pauses. But major GC pauses are still noticeable compared to minor GC.

### GC Roots

An object is alive if it is **reachable** from a GC root:
- The global object (`window`, `global`, `globalThis`)
- The current call stack (all local variables in active functions)
- Active closures (their variable environment objects)
- References in the microtask/macrotask queues

If no root can reach an object — directly or transitively — it is garbage and will be collected.

### Memory Leak Patterns

**1. Forgotten event listeners:**
```javascript
function init() {
  const cache = buildLargeCache(); // 10MB
  window.addEventListener('resize', function handler() {
    recalculate(cache);
  });
  // handler is never removed — cache stays alive forever
}
```

**2. Closure holding unnecessary large environment:**
```javascript
function outer() {
  const bigData = loadGigabytes(); // stays alive
  const useful  = 'small string';
  return () => useful; // only uses `useful`, but entire environment lives
}
// Fix: null out bigData before returning, or refactor scope
```

**3. Timer reference not cleared:**
```javascript
class Poller {
  start() {
    this.timerId = setInterval(() => this.poll(), 1000);
  }
  stop() {
    // If stop() is never called, the interval keeps the Poller alive forever
    clearInterval(this.timerId);
  }
}
```

**4. Global accumulation:**
```javascript
// Accidentally writing to global scope
function processUser(user) {
  processedUsers = []; // missing `let/const` — creates a global!
  processedUsers.push(user);
}
```

**5. Detached DOM nodes:**
```javascript
const detached = document.getElementById('node');
document.body.removeChild(detached);
// `detached` variable still holds a reference — the node is not collected
// even though it's removed from the DOM
```

### WeakMap and WeakSet

**WeakMap:** Like Map, but keys must be objects, and the references to keys are **weak**. If the only reference to a key object is the WeakMap key, it can be garbage collected. The entry disappears automatically.

```javascript
const cache = new WeakMap();

function process(element) {
  if (cache.has(element)) return cache.get(element);
  const result = expensive(element);
  cache.set(element, result); // weak reference to element
  return result;
}
// When element is removed from DOM and no other references exist,
// the WeakMap entry is automatically collected — no manual cleanup needed
```

**Why WeakMap is not iterable:** You cannot iterate over a WeakMap because at any moment, GC might remove entries. Allowing iteration would require holding strong references to all entries, defeating the purpose.

**When to use WeakMap vs Map:**
- Use **WeakMap** when keys are objects whose lifetime you don't control and you don't want your cache to prevent GC
- Use **Map** when you need iteration, counting, or guaranteed retention

### Hidden Classes (V8 Shapes/Maps)

V8 assigns a **hidden class** (also called a "shape" or "map") to every object. The hidden class describes the object's property layout — which properties exist and where they are stored in memory (at what offset).

Objects with identical property layouts share the same hidden class. This allows V8 to treat property access like a struct field access — a fixed memory offset, as fast as C.

```javascript
// These two objects share a hidden class:
const p1 = { x: 1, y: 2 };
const p2 = { x: 3, y: 4 };

// p1 and p2: same hidden class → same memory layout → V8 can use the same compiled code
```

### Hidden Class Transitions

Every time you add a property to an object, V8 creates a new hidden class (a transition):

```javascript
const obj = {};       // hidden class C0 (empty)
obj.x = 1;           // transition: C0 → C1 (has x)
obj.y = 2;           // transition: C1 → C2 (has x, y)
```

If you always add properties in the same order, all objects share the same transition chain and the same hidden classes. If you add properties in different orders, you create DIFFERENT hidden classes:

```javascript
// SAME hidden class:
function makePoint(x, y) { return { x, y }; }
const p1 = makePoint(1, 2);
const p2 = makePoint(3, 4);

// DIFFERENT hidden classes (splits the transition chain):
function makeUnpredictable(x, y) {
  const obj = {};
  if (x > 0) obj.x = x; // sometimes has x, sometimes doesn't
  obj.y = y;
  return obj;
}
```

### Deoptimization Triggers

V8's TurboFan JIT compiler makes optimizations based on **observed types** (type feedback from the Ignition interpreter). If those assumptions are violated, V8 **deoptimizes** — abandons the machine code and falls back to the interpreter:

- **`delete obj.property`:** Removes a property, changing the hidden class. V8 assigns the object a new "dictionary mode" hidden class — no longer optimizable.
- **Changing property types:** `obj.x = 1` then `obj.x = 'string'` — V8 assumed x was always a number.
- **Adding properties after construction:** Any property added after the standard construction sequence creates hidden class transitions not seen during profiling.
- **Polymorphic/megamorphic call sites:** A function called with objects of many different hidden classes defeats inline caching.

**`delete` vs `null`:**
```javascript
// BAD — triggers deoptimization, creates dictionary mode object
delete obj.cache;

// GOOD — preserves hidden class, still GC-eligible
obj.cache = null;
```

### Inline Caches (ICs)

When V8 executes `obj.property`, it remembers (caches) the hidden class and the property's offset. On the next call:

| Cache state | Condition | Speed |
|---|---|---|
| **Monomorphic** | Always called with the same hidden class | Fastest — direct memory offset |
| **Polymorphic** | Called with 2–4 different hidden classes | Slower — small check, then offset |
| **Megamorphic** | Called with >4 different hidden classes | Slowest — no cache, generic lookup |

```javascript
// Keep call sites monomorphic:
function getX(point) {
  return point.x; // if point always has the same shape, this is monomorphic
}

// Megamorphic — many different shapes:
function getValue(obj) {
  return obj.value; // called with 10 different object shapes → megamorphic
}
```

### Typed Arrays

`Float64Array`, `Int32Array`, etc. store raw binary data without boxing. V8 can apply SIMD-level optimizations. Use these for large numeric workloads (audio, image processing, WASM interop).

```javascript
const buffer = new Float64Array(1_000_000);
for (let i = 0; i < buffer.length; i++) buffer[i] = i * 1.5;
// No GC pressure, no boxing — operates like a C array
```

---

## Go Deep On

### Why `delete` causes deoptimization

When you `delete obj.x`, V8 must create a new hidden class for the object without that property. But this new hidden class is NOT part of the original transition chain (which goes: C0 → add x → C1 → add y → C2). Creating an orphaned hidden class means V8 cannot share it with other objects, and it often puts the object into "dictionary mode" — a hash map–based layout with no inline caching. All subsequent property accesses on that object are slow.

### Why property initialization order matters

```javascript
// Scenario A: same hidden class chain
function makePoint(x, y) { return { x, y }; }
// Every call: C0 → (add x) → C1 → (add y) → C2
// p1 and p2 share C2

// Scenario B: same transitions, same chain
function makePoint(x, y) {
  const p = {};
  p.x = x;
  p.y = y;
  return p;
}
// Same chain as A — C0 → C1 → C2

// Scenario C: conditional initialization — SPLITS the chain
function makePoint(x, y) {
  const p = {};
  if (x > 0) p.x = x;  // sometimes C0 → C1, sometimes just C0
  p.y = y;              // C1 → C2 or C0 → C_different
  return p;             // two different final hidden classes!
}
```

### Minor GC (Scavenge) vs Major GC (Mark-Sweep-Compact)

| | Minor GC (Scavenge) | Major GC (Mark-Sweep-Compact) |
|---|---|---|
| Generation | Young generation | Old generation |
| Algorithm | Cheney's semi-space copying | Mark phase → Sweep phase → Compact |
| Frequency | Very frequent | Infrequent |
| Pause duration | Very short (few ms) | Longer (can be 10–100ms without incremental marking) |
| Cost source | Copies only live objects to the other semi-space | Must trace the entire reachable object graph |
| Promotion | Survivors of 2+ Scavenges → old generation | — |

Scavenge is cheap because: (1) young generation is small, (2) most objects die young, (3) it only copies LIVE objects — the fewer survivors, the cheaper the collection.

---

## Checkpoint

You must demonstrate ALL of the following before moving to Phase 6.

**Checkpoint 1 — Memory leak audit**
Given a code file with 5 memory leak patterns (event listener not removed, closure holding unnecessary large data, timer reference not cleared, global variable accumulation, WeakMap misuse as Map) — identify each leak, explain why it leaks at the GC level, and fix it.

**Checkpoint 2 — WeakMap vs Map**
Explain the difference between WeakMap and Map from a GC perspective. Write a concrete example where:
- WeakMap is the correct choice
- Using Map instead would cause a memory leak

**Checkpoint 3 — Hidden class benchmark**
Write two versions of a hot function called 1,000,000 times:
- Version A: consistent object shapes (all objects have same properties initialized in same order)
- Version B: inconsistent shapes (conditional property addition or varying order)

Benchmark with `performance.now()`. Explain the difference in terms of hidden classes and inline caches.

**Checkpoint 4 — `delete` vs `null`**
Explain what happens in V8 when you do `delete obj.property` vs `obj.property = null`. Why is `delete` a deoptimization trigger at the hidden class level? When is `delete` acceptable (hint: consider objects that are only ever accessed once and never in hot paths)?

**Checkpoint 5 — Generational GC explanation**
Answer: why does V8 have two generations? What determines when an object is promoted from young to old generation? Why is minor GC cheaper than major GC? What is the "generational hypothesis"?

---

## Connection to Your Background

- **Rust ownership vs GC:** In Rust, the compiler tracks ownership at compile time — memory is freed deterministically at end of scope. JavaScript's GC tracks reachability at runtime — memory is freed non-deterministically when the GC runs. The trade-off: Rust's zero-cost but inflexible; JS GC is convenient but adds latency and GC pauses.
- **Struct layout in systems programming:** Hidden classes are V8's runtime equivalent of C struct layout. `struct Point { float x; float y; }` has a fixed layout — `p.x` is always at offset 0. V8 creates hidden classes to achieve the same predictability for object property access. Consistent initialization order = consistent "struct layout."
- **MongoDB:** When you query MongoDB documents and create JavaScript objects from them, consistent document structure → consistent hidden classes → faster processing loops. Sparse documents (many optional fields) fragment hidden classes. This is why schema enforcement (even in MongoDB) has performance benefits beyond readability.

---

## After Completing This Phase

1. What was the hardest part of Phase 5, and what specifically made it hard?
2. How would you explain hidden classes and why `delete` is dangerous to a developer who has written JavaScript for two years?

Then move to [[Phase 6 - Creational Design Patterns]].
