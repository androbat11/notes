# Phase 2 — Closures

> The mechanism behind modules, private state, and most JavaScript patterns
> **Week:** 2 | **Status:** [ ] Complete

---

## Why This Phase Exists

Closures are not a "nice trick" — they are the mechanism behind nearly every important JavaScript pattern: modules, private state, factory functions, memoization, currying, and event-driven callbacks. Every time you write a function inside another function, a closure is created. Most developers who use closures daily cannot explain what the engine actually does. That gap produces memory leaks, stale-state bugs, and code they cannot reason about under pressure.

This phase makes the implicit explicit: what the engine allocates, what keeps it alive, and what the cost is.

---

## Core Concepts

### Closure Definition

A closure is a function that retains a **live reference** to its outer lexical environment — the **variable environment object** of the function that created it — even after the outer function has returned and its execution context has been popped from the call stack.

```javascript
function outer() {
  let count = 0;           // lives in outer's variable environment object

  return function inner() {
    count++;               // inner retains a live reference to outer's environment
    return count;
  };
}

const increment = outer(); // outer() returns, its execution context is gone from the stack
increment(); // 1          // but outer's variable environment is still alive — inner holds a reference
increment(); // 2
increment(); // 3
```

### The Variable Environment Object

When a function is created, the engine allocates a **variable environment object** (also called an environment record or a closure object) on the heap. This object holds all the variables declared in that function's scope.

When `outer()` returns, its execution context is popped from the call stack. However, the **variable environment object** is NOT garbage collected — because `inner` still holds a reference to it. The environment object stays alive on the heap until no function references it.

This is the core insight: **closures keep environment objects alive on the heap**.

### Reference vs Value Capture

Closures capture **references** to variable bindings, not copies of values. This is why mutations are visible:

```javascript
function makeCounter() {
  let n = 0;
  return {
    increment: () => ++n,
    decrement: () => --n,
    value:     () => n,
  };
}

const c = makeCounter();
c.increment(); // 1
c.increment(); // 2
c.decrement(); // 1
c.value();     // 1 — all three functions share the SAME n binding
```

**Compare with Rust:** In Rust, closures explicitly declare whether they borrow (`&T`), mutably borrow (`&mut T`), or move (`T`). JavaScript closures always borrow — but with GC managing lifetime instead of the borrow checker.

### Private State via Closures

Before private class fields (`#field`), closures were the only way to achieve true privacy in JavaScript:

```javascript
function createAccount(initialBalance) {
  let balance = initialBalance; // truly private — no external access path

  return {
    deposit(amount)  { balance += amount; },
    withdraw(amount) {
      if (amount > balance) throw new Error('Insufficient funds');
      balance -= amount;
    },
    getBalance()     { return balance; },
  };
}

const account = createAccount(100);
account.deposit(50);
account.getBalance(); // 150
account.balance;      // undefined — no access to the closure variable
```

### The IIFE Module Pattern

Before ES modules, IIFEs (Immediately Invoked Function Expressions) were the standard way to create a module-like scope:

```javascript
const MyModule = (function() {
  let _privateState = 0; // private

  function _privateHelper() { /* ... */ }

  return {
    publicMethod() { _privateState++; _privateHelper(); },
    getState()     { return _privateState; },
  };
})();
```

**Why was this necessary?** Without ES modules, all scripts share the global scope. Any `var` at the top level pollutes `window`. The IIFE creates a new function scope — a private environment — and returns only the public API. This prevents name collisions between scripts.

### Factory Functions

A factory function is a function that returns an object with closure-held private state:

```javascript
function createLogger(prefix) {
  const history = [];  // private

  return {
    log(msg) {
      const entry = { msg, time: Date.now() };
      history.push(entry);
      console.log(`[${prefix}] ${msg}`);
    },
    getHistory() { return [...history]; }, // return a copy — defensive
  };
}
```

### Partial Application

Fixing some arguments ahead of time, returning a function waiting for the rest:

```javascript
function partial(fn, ...presetArgs) {
  return function(...laterArgs) {
    return fn(...presetArgs, ...laterArgs);
  };
}

const add = (a, b) => a + b;
const add5 = partial(add, 5);
add5(3); // 8
add5(10); // 15
```

### Currying

Transforming an N-arity function into a chain of unary functions:

```javascript
function curry(fn) {
  return function curried(...args) {
    if (args.length >= fn.length) {
      return fn(...args);
    }
    return function(...moreArgs) {
      return curried(...args, ...moreArgs);
    };
  };
}

const add = (a, b, c) => a + b + c;
const curriedAdd = curry(add);

curriedAdd(1)(2)(3);   // 6
curriedAdd(1, 2)(3);   // 6
curriedAdd(1)(2, 3);   // 6
curriedAdd(1, 2, 3);   // 6
```

### Memoization

Caching results using a closure-held Map:

```javascript
function memoize(fn) {
  const cache = new Map(); // private to this memoized instance

  return function(...args) {
    const key = JSON.stringify(args);
    if (cache.has(key)) return cache.get(key);
    const result = fn(...args);
    cache.set(key, result);
    return result;
  };
}
```

---

## Go Deep On

### Why closures keep the ENTIRE environment alive

```javascript
function outer() {
  const bigData = new Array(1000000).fill('x'); // 1MB
  const used    = 'I am used';

  return function inner() {
    return used; // only uses `used`, not `bigData`
  };
}

const fn = outer();
// bigData is still in memory — inner's reference to outer's environment
// keeps the ENTIRE environment object alive, including bigData
```

This is a common memory leak. The fix: set `bigData = null` before returning, or restructure so the large data is not in the same environment.

**Why?** The environment is a single object on the heap. The closure holds a reference to the entire object, not just the variables it uses. The GC cannot partially collect an object.

### IIFE vs ES modules

| | IIFE Module | ES Module |
|---|---|---|
| Mechanism | Closure | Language-level cache |
| Privacy | Variables in function scope | Module-level scope |
| Singleton | Explicit (IIFE runs once) | Implicit (module evaluated once, cached) |
| Dependencies | Manual (passed as IIFE args) | Static `import` declarations |
| Circular deps | Possible but fragile | Handled (with initialization order caveats) |
| Tree shaking | Impossible | Possible (static analysis) |

### Closure-based memory leaks

**Event listener leak:**
```javascript
function setup() {
  const largeData = loadMegabytes(); // holds a large dataset

  button.addEventListener('click', function handler() {
    process(largeData); // handler closes over largeData
  });
  // handler is never removed — largeData stays alive as long as button exists in DOM
}
```

**Fix:**
```javascript
function setup() {
  const largeData = loadMegabytes();

  function handler() {
    process(largeData);
    button.removeEventListener('click', handler); // or use { once: true }
  }
  button.addEventListener('click', handler);
}
```

**Timer leak:**
```javascript
function startPolling(userId) {
  const userCache = buildCache(userId); // large object

  const id = setInterval(() => {
    refresh(userCache); // closure keeps userCache alive
  }, 1000);

  // if clearInterval(id) is never called, userCache lives forever
}
```

---

## Checkpoint

You must demonstrate ALL of the following before moving to Phase 3.

**Checkpoint 1 — `once(fn)`**
Implement `once(fn)` — a function that ensures `fn` is called at most once. Subsequent calls return the first result without calling `fn` again. No libraries.

Acceptance criteria:
- `once(fn)(a, b)` calls `fn(a, b)` and returns the result
- All subsequent calls return the first result, regardless of arguments
- `fn` is never called more than once (verify with a call counter)

**Checkpoint 2 — `createPrivateStore()`**
Implement `createPrivateStore()` — returns `{ get(key), set(key, value), delete(key), keys() }`. The internal Map must be completely inaccessible from outside. Demonstrate that `store._map` or any similar property access returns `undefined`.

**Checkpoint 3 — `curry(fn)`**
Implement a `curry(fn)` that works for any arity and supports partial application at every step:
- `curry(f)(a)(b)(c)` — fully step-by-step
- `curry(f)(a,b)(c)` — mixed
- `curry(f)(a,b,c)` — all at once

**Checkpoint 4 — Memory leak diagnosis**
Given this code:
```javascript
button.addEventListener('click', function handler() {
  largeObject.process();
});
```
Explain: (1) what the memory leak is, (2) why it happens at the GC level, (3) how to fix it.

**Checkpoint 5 — IIFE vs ES modules**
Explain why the IIFE module pattern was necessary before ES modules. What specific problem did it solve that a plain function (not immediately invoked) did not?

---

## Connection to Your Background

- **Rust closures:** In Rust, `move` closures take ownership of captured variables; non-move closures borrow. JavaScript closures always borrow — but the GC handles lifetime. There is no concept of `move` in JS because ownership doesn't exist.
- **Rust `Option<T>` / `Result<T,E>`:** The memoization pattern is analogous to wrapping a computation in a lazy evaluated cache. You'll see this pattern again in Phase 9 (functional patterns).
- **Node.js modules:** CommonJS modules (`require()`) are effectively an IIFE — the module code is wrapped in a function by Node.js's module loader. `module.exports` is the returned public API. ES modules replace this with a language-level mechanism.

---

## After Completing This Phase

1. What was the hardest part of Phase 2, and what specifically made it hard?
2. How would you explain closures and the variable environment object to a developer who has written JavaScript for two years but never thought about the engine?

Then move to [[Phase 3 - Event Loop & Async Internals]].
