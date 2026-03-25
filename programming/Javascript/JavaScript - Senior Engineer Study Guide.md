# JavaScript — Senior Engineer Study Guide

> **Student profile:** Mid-level backend engineer (Node.js, TypeScript, Rust, MongoDB). Thinks in typed systems, functional pipelines, and backend architecture. NOT learning syntax — learning how JavaScript actually works underneath, and how to design systems at a senior level.
> **Goal:** Think and reason like a senior JavaScript engineer. Predict what the engine does. Design systems that are correct, performant, and maintainable.
> **Rule:** Complete every checkpoint item before advancing. Partial credit is not a pass.

---

## How to Use This Guide

This guide is designed for Socratic self-study and AI-assisted sessions. For each phase:

1. Read the phase file to understand the concepts
2. Ask your AI tutor: `"I'm on Phase N — teach me [concept]"` → get the full Tutor explanation
3. Ask: `"Give me an exercise for Phase N"` → build the exercise
4. Ask: `"Review my Phase N checkpoint solution"` → go through Socratic review
5. Only mark a phase complete when all checkpoint criteria are met AND you can answer the follow-up questions

**Three modes:**
- **LEARN** — concept explanation (WHY → MECHANISM → CODE → GOTCHAS → CONNECTION)
- **BUILD** — exercise generation tied to the checkpoint
- **REVIEW** — Socratic review, never the answer on the first ask

---

## Curriculum Overview

| Phase | Topic | Week | Status |
|-------|-------|------|--------|
| [[Phase 1 - Execution Context & Scope\|Phase 1]] | Execution Context & Scope | 1 | [ ] |
| [[Phase 2 - Closures\|Phase 2]] | Closures | 2 | [ ] |
| [[Phase 3 - Event Loop & Async Internals\|Phase 3]] | Event Loop & Async Internals | 3 | [ ] |
| [[Phase 4 - Prototypes & Object Model\|Phase 4]] | Prototypes & The Object Model | 4 | [ ] |
| [[Phase 5 - Memory Model & V8 Internals\|Phase 5]] | Memory Model & V8 Internals | 5 | [ ] |
| [[Phase 6 - Creational Design Patterns\|Phase 6]] | Creational Design Patterns | 6 | [ ] |
| [[Phase 7 - Structural Design Patterns\|Phase 7]] | Structural Design Patterns | 7 | [ ] |
| [[Phase 8 - Behavioral Design Patterns\|Phase 8]] | Behavioral Design Patterns | 8 | [ ] |
| [[Phase 9 - Functional Patterns\|Phase 9]] | Functional Patterns | 9 | [ ] |
| [[Phase 10 - Metaprogramming & Architecture\|Phase 10]] | Metaprogramming, Module Systems & Architecture | 10 | [ ] |

---

## The 10 Senior JavaScript Interview Questions

These are the questions you must answer from first principles — not surface-level — before considering yourself senior-ready.

### 1. Explain the event loop in full detail.
Expected depth: call stack, Web APIs, macrotask queue, microtask queue, the drain algorithm (all microtasks before any macrotask), Node.js event loop phases (timers → poll → check), the difference between `setImmediate` and `setTimeout(fn,0)`, why `Promise.resolve().then()` always runs after current sync code.

### 2. What is a closure and what does the engine actually do when one is created?
Expected depth: the variable environment object, why it is kept alive on the heap, the difference between capturing a reference vs a value, memory implications when environments are shared across multiple closures, practical applications (module pattern, memoization, currying), and closure-based memory leaks.

### 3. How does prototypal inheritance actually work at the engine level?
Expected depth: `[[Prototype]]` slot, property lookup chain, `Object.create()`, what `new` does in four steps, the difference between `.prototype` (on functions) and `[[Prototype]]` (on objects), why methods are on the prototype not the instance, class syntax as sugar, and why deep inheritance hierarchies are fragile.

### 4. What are the four this-binding rules and what is their priority order?
Expected depth: new binding (highest priority), explicit binding (`.call/.apply/.bind`), implicit binding (method call), default binding (lowest priority, `undefined` in strict mode); arrow functions have no own `this` — they inherit lexically; common `this`-loss bugs and fixes; cannot bind an arrow function.

### 5. What does V8 do to optimize your code and how do you accidentally break it?
Expected depth: Ignition interpreter collects type feedback, TurboFan JIT compiles hot functions to machine code based on feedback, deoptimization when assumptions are violated; hidden classes and how inconsistent property initialization breaks them; inline caches (monomorphic/polymorphic/megamorphic); `delete` as a deoptimization trigger; why consistent object shapes matter.

### 6. What is the difference between macrotasks and microtasks? Name sources of each.
Expected depth: microtasks (Promise `.then/.catch/.finally`, `queueMicrotask`, `async/await` continuations) drain completely before any macrotask runs; macrotasks (`setTimeout`, `setInterval`, `setImmediate`, I/O) run one at a time; a microtask that schedules another microtask runs before any macrotask; this is why long microtask chains can starve macrotasks.

### 7. What is the difference between WeakMap and Map from a memory perspective?
Expected depth: Map holds strong references — entries are not collected as long as the Map exists; WeakMap holds weak references to keys — if the only reference to an object is as a WeakMap key, it can be collected; WeakMap is not iterable by design; use cases: associating metadata with objects without preventing GC, private class field simulation pre-`#`, caching DOM node data.

### 8. What is the difference between CommonJS and ES modules? What are live bindings?
Expected depth: `require()` is synchronous, evaluated at runtime, copies exported values; ES module imports are static (resolved at parse time), live (changes to the exported binding are visible to importers), and cached (module evaluated once); dynamic `import()` is a function returning a Promise; live bindings mean the importer always sees the current value of the export, not a snapshot.

### 9. Explain the prototype chain for an instance created with a class. Name every link.
Expected depth: instance → `Class.prototype` → `ParentClass.prototype` (if extends) → `Object.prototype` → `null`; class methods are on `Class.prototype`; static methods are on the constructor itself; `hasOwnProperty` vs `in` operator to distinguish own vs inherited; `instanceof` walks the chain checking for `Constructor.prototype`.

### 10. What does `new` actually do? Implement it from scratch.
Expected depth: (1) create a new empty object; (2) set its `[[Prototype]]` to `Constructor.prototype`; (3) call `Constructor` with `this` set to the new object; (4) if `Constructor` returns an object, return that — otherwise return the new object; arrow functions cannot be constructors because they have no own `this` and no `.prototype` property.

---

## Background Connections

When a new concept is hard to internalize, map it to something you already know:

| JavaScript Concept | Your Rust/Backend Analogy |
|---|---|
| Event loop | Node.js I/O scheduler — you know this; the browser adds a render frame as a participant |
| Closures | Rust closures that capture their environment — same concept, different memory model (GC vs ownership) |
| Prototypes | Rust traits and TypeScript interfaces — but those are compile-time; prototypes are runtime lookup chains on live objects |
| Generational GC | The opposite of Rust's ownership model — GC exists because JS has no ownership tracking; it trades predictability for convenience |
| Hidden classes | Struct memory layout in systems programming — consistent field order = efficient access pattern |
| Factory pattern | Service instantiation in backend DI |
| Facade pattern | API gateway |
| Strategy pattern | Pluggable middleware |
| Command pattern | Event sourcing |
| Chain of Responsibility | Express/Koa middleware pipeline — you use this daily |
| Maybe monad | `Option<T>` in Rust |
| Either monad | `Result<T, E>` in Rust — you know this type deeply |
| Dependency Injection | Passing dependencies as parameters instead of importing inside functions |

---

## Closing Questions (Every Session)

Before ending any study session, answer these two:

1. **"What was the hardest part of what I covered today, and what specifically made it hard?"**
2. **"How would I explain today's core concept to a developer who has been writing JavaScript for two years but never thought about the engine?"**

These close the metacognitive loop and force consolidation. They are not optional.
