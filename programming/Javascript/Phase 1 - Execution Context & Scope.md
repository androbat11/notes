# Phase 1 — Execution Context & Scope

> The engine's setup work before your code runs
> **Week:** 1 | **Status:** [ ] Complete

---

## Why This Phase Exists

Before a single line of your code executes, V8 does a significant amount of work: it allocates memory for variables, sets up the scope chain, and establishes which names will be accessible where. Developers who skip this phase write code with "inexplicable" bugs — variables that are `undefined` when they "should" be set, functions that work before they are declared, and `let` declarations that throw errors at positions that look valid. None of these are mysterious once you understand what the engine does in the creation phase.

This is the foundation. Everything — closures, `this`, the event loop, module loading — builds on having a precise mental model of execution contexts and scope.

---

## Core Concepts

### Execution Context Lifecycle

Every time JavaScript executes code, it creates an **execution context**. There are two phases:

**Creation phase** (before any line runs):
- Scans the code for variable declarations, function declarations, and class declarations
- Allocates memory for each
- `var` declarations: hoisted and initialized to `undefined`
- `function` declarations: fully hoisted — name AND body are available immediately
- `let`/`const` declarations: hoisted but placed in the **Temporal Dead Zone** — inaccessible until the declaration line
- `class` declarations: hoisted but placed in the TDZ (same as `let`)

**Execution phase** (line by line):
- Assigns actual values to variables
- Executes statements in order

### The Call Stack

Each function call pushes a new execution context onto the call stack. When the function returns, its context is popped. The global execution context is always at the bottom.

```
Global EC
  └── foo() EC
        └── bar() EC   ← currently executing
```

Stack overflow: too many nested calls push too many contexts, exceeding the stack size limit. Recursive functions without a base case are the most common cause.

### Hoisting in Full Detail

```javascript
// What you write:
console.log(a);     // undefined — var is hoisted + initialized to undefined
console.log(b);     // ReferenceError — let is in TDZ
console.log(fn);    // [Function: fn] — function declaration fully hoisted

var a = 1;
let b = 2;
function fn() {}
```

**Function declarations vs function expressions:**
```javascript
greet();              // works — function declaration is fully hoisted
sayHi();              // TypeError: sayHi is not a function — it's var (undefined) at this point

function greet() { return 'hello'; }
var sayHi = function() { return 'hi'; };
```

### The Temporal Dead Zone (TDZ)

The TDZ is the period between when a `let`/`const` binding is hoisted (creation phase) and when control flow reaches the declaration line (execution phase). The binding EXISTS in the environment but is not initialized. Any access during this window throws `ReferenceError`.

This is NOT the same as a variable not existing:
- `var x` → hoisted + initialized to `undefined` → access before declaration returns `undefined`
- `let x` → hoisted + placed in TDZ → access before declaration throws `ReferenceError`

**Why does TDZ exist?** It's an intentional design to catch bugs. `var`'s behavior (returning `undefined` before declaration) has caused many real bugs. `let`/`const` make the error explicit and loud.

### Lexical Scope

Scope is determined by **where code is written** in the source file, not where it is called. A function can access variables from its enclosing scopes regardless of where it is called from.

```javascript
const x = 'outer';

function inner() {
  console.log(x); // 'outer' — found via lexical scope chain
}

function callInner() {
  const x = 'callsite'; // different x — doesn't affect inner()
  inner();              // still logs 'outer'
}
```

### The Scope Chain

When the engine cannot find a variable in the current scope, it walks up the **scope chain** — the linked list of enclosing lexical environments — until it finds the variable or reaches the global scope (where it throws `ReferenceError`).

### Block Scope vs Function Scope

```javascript
// var: function-scoped
function example() {
  if (true) {
    var x = 1;   // scoped to the function, not the block
  }
  console.log(x); // 1 — accessible outside the if block
}

// let/const: block-scoped
function example2() {
  if (true) {
    let y = 1;   // scoped to the if block
  }
  console.log(y); // ReferenceError — y doesn't exist here
}
```

### The Classic `var`-in-Loop Bug

```javascript
// Bug: all callbacks share the same var i
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 0); // logs 3, 3, 3
}

// Fix 1: use let (block-scoped — each iteration gets its own binding)
for (let i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 0); // logs 0, 1, 2
}

// Fix 2: IIFE (immediately-invoked function creates a new scope with a copy of i)
for (var i = 0; i < 3; i++) {
  (function(j) {
    setTimeout(() => console.log(j), 0); // logs 0, 1, 2
  })(i);
}

// Fix 3: .bind() (pre-applies i as the first argument)
for (var i = 0; i < 3; i++) {
  setTimeout(console.log.bind(null, i), 0); // logs 0, 1, 2
}
```

**Why does the bug happen?** `var` is function-scoped, so there is ONE `i` for the entire loop. All three closures close over the same binding. By the time the callbacks run (after the loop completes), `i === 3`.

---

## Go Deep On

### The creation phase for a module with mixed declarations

```javascript
// Module: what does the engine do BEFORE line 1 runs?
var count = 0;
let name = 'app';
const MAX = 100;

function setup() { /* ... */ }
const teardown = function() { /* ... */ };
class Logger { /* ... */ }
```

During creation phase:
- `count` → hoisted, initialized to `undefined`
- `name` → hoisted, placed in TDZ
- `MAX` → hoisted, placed in TDZ
- `setup` → fully hoisted (name + body available immediately)
- `teardown` → hoisted as `var`-like would be, but it's a `const` — in TDZ; the function expression is NOT hoisted
- `Logger` → hoisted, placed in TDZ

### Why `let` throws but `var` returns `undefined`

They are both hoisted. The difference is initialization:
- `var` bindings are hoisted AND immediately initialized to `undefined`
- `let`/`const` bindings are hoisted but NOT initialized — they sit in TDZ

The TDZ check is an explicit runtime check: before accessing a TDZ binding, the engine checks if it has been initialized and throws `ReferenceError` if not.

### Why function declarations can be called before they appear

The engine processes function declarations in the creation phase, before the execution phase begins. The name AND body are registered in the scope. By the time any line of code executes, all function declarations in that scope are fully available.

---

## Checkpoint

You must demonstrate ALL of the following before moving to Phase 2.

**Checkpoint 1 — Output prediction**
Given a 20-line snippet mixing `var`, `let`, `const`, function declarations, function expressions, and class declarations — predict the exact output including all errors, line by line, before running it.

**Checkpoint 2 — Creation phase narration**
For a given module, explain what the engine does during the creation phase and the execution phase. Name every variable, its initial value after the creation phase, and exactly when it becomes accessible.

**Checkpoint 3 — Fix the loop bug three ways**
Write the classic `var`-in-loop bug, then fix it three ways:
1. Using `let`
2. Using an IIFE
3. Using `.bind()`

Explain why each fix works at the scope level — not just "it works."

**Checkpoint 4 — Explain the TDZ**
Answer: why does `let` throw `ReferenceError` while `var` returns `undefined` when accessed before declaration? What is the engine doing differently? What is the TDZ and why was it introduced?

---

## Connection to Your Background

- **Rust analogy:** The creation phase is like Rust's borrow checker running before execution — it establishes what names exist and where. The TDZ is analogous to Rust's "use before initialization" compile error, except JavaScript catches it at runtime, not compile time.
- **TypeScript analogy:** `let` in the TDZ throws the same kind of error TypeScript catches statically with `'variable' is used before being assigned`. JS does it at runtime; TypeScript does it at compile time.
- **Node.js:** Module loading in Node.js (CommonJS) triggers the creation phase for that module's code before any of the module's exports are available. This is why circular requires can produce `undefined` exports — you're accessing a binding before its execution phase has run.

---

## After Completing This Phase

Ask yourself:
1. What was the hardest part of Phase 1, and what specifically made it hard?
2. How would you explain execution contexts and hoisting to a developer who has written JavaScript for two years but never thought about the engine?

Then move to [[Phase 2 - Closures]].
