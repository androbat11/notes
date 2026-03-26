# Lexical Scope & Non-Lexical Lifetimes (NLL)

> **Prerequisites**: You understand ownership, `&T` (shared borrow), and `&mut T` (exclusive mutable borrow).

---

## 1. What Is a Lexical Scope?

A **lexical scope** is a region of source code delimited by curly braces `{ }`. Every variable (and every borrow) has a lexical scope — it comes into existence when declared and, in the old model, was considered *alive* until the closing `}` of the block where it was created.

```
fn main() {
    //  ┌─── outer scope begins
    let x = 5;
    {
        //  ┌─── inner scope begins
        let y = 10;
        println!("{}", y);
        //  └─── inner scope ends → y is dropped here
    }
    // y is gone; x is still alive
    println!("{}", x);
    //  └─── outer scope ends → x is dropped here
}
```

**Key mental model**: scopes are a *stack*. Entering `{` pushes a frame; hitting `}` pops it, running `Drop` for everything in that frame.

---

## 2. How Borrows Worked Under Lexical (Pre-NLL) Rules

Before NLL the compiler tied a borrow's lifetime directly to its lexical scope. A `&mut` borrow created anywhere inside a block was considered *live* all the way to the `}` that closed that block — even if you never touched the reference again after line 3.

### The Rule (Pre-NLL)
> A borrow `&'a mut T` is alive from its creation point to the **end of its enclosing lexical scope**.

### Visual Timeline

```
fn main() {
    let mut v = vec![1, 2, 3];

    let r = &mut v;          // ── borrow starts (line A)
    r.push(4);               // ── last actual use

    // ↓ borrow is STILL considered alive here (pre-NLL)
    // ↓ even though r is never touched again

    println!("{:?}", v);     // ❌ COMPILE ERROR: v is still mutably borrowed
}                            // ── borrow ends here (lexical end of block)
```

```
Timeline (pre-NLL):

line:  [A]──────────push──────────────────────────────[}]
borrow: |=============================================>|
use:                  ^^^
conflict:                           println!(v) ← BOOM
```

---

## 3. Concrete Example — Before NLL

```rust
fn main() {
    let mut data = String::from("hello");

    let r: &mut String = &mut data;  // mutable borrow starts
    r.push_str(", world");           // last real use of r

    // r is never used again — but pre-NLL says it's still alive

    println!("{}", data);            // ❌ error[E0502]: cannot borrow `data`
                                     //    as immutable because it is also
                                     //    borrowed as mutable
}
```

**Compiler error (pre-NLL / Rust ≤ 2018 edition without NLL flag)**:
```
error[E0502]: cannot borrow `data` as immutable because it is also borrowed as mutable
 --> src/main.rs:7:20
  |
3 |     let r: &mut String = &mut data;
  |                          --------- mutable borrow occurs here
7 |     println!("{}", data);
  |                    ^^^^ immutable borrow occurs here
8 | }
  | - mutable borrow later used here  ← points to closing brace
```

The phrase **"later used here"** pointing at `}` is the giveaway: the compiler treated the borrow as live until the scope closed.

---

## 4. Why This Was Overly Restrictive

A mutable borrow's *purpose* is to prevent aliasing during active mutation. Once you stop using `r`, there is no mutation happening — the memory is quiescent. Keeping the borrow alive past its last use served no safety purpose; it was purely an artifact of the compiler using `}` as a cheap conservative approximation.

This forced unnatural patterns:

```rust
// Workaround: use an extra block to force the borrow to end
fn main() {
    let mut data = String::from("hello");

    {
        let r = &mut data;
        r.push_str(", world");
    }   // ← forced end of borrow via artificial block

    println!("{}", data);  // ✅ works, but ugly
}
```

This boilerplate annoyed experienced Rustaceans and was a significant beginner stumbling block.

---

## 5. Non-Lexical Lifetimes (NLL) — RFC 2094

**RFC**: https://rust-lang.github.io/rfcs/2094-nll.html
**Stabilized**: Rust 2018 edition; fully enabled for all editions in Rust 1.36 (2019).

### Core Idea
> A borrow's lifetime ends at its **last use**, not at the end of its lexical scope.

NLL replaces the crude `}` approximation with a proper **liveness analysis** over the control-flow graph (CFG). The compiler asks: *"Is this reference reachable from any future use point?"* If not, the lifetime is considered ended.

### Same Code After NLL

```rust
fn main() {
    let mut data = String::from("hello");

    let r: &mut String = &mut data;  // mutable borrow starts
    r.push_str(", world");           // ← last use of r → borrow ends HERE

    // r is provably dead; no conflict
    println!("{}", data);            // ✅ compiles fine
}
```

```
Timeline (NLL):

line:  [A]──────────push──┤
borrow: |================>|  ends at last use
use:                  ^^^
no conflict:                  println!(data) ← fine
```

### NLL Timeline Comparison

```
                  Pre-NLL                         NLL
                  ───────                         ───
let r = &mut v;  ├── borrow live ──────────────┤  ├── borrow live ─┤
r.push(4);       │         ↑ last use           │  │    ↑ last use  │ ← ends here
                 │                              │  │               │
println!(v);     │ ❌ v still borrowed          │  │✅ borrow gone  │
}                └──────────────────────────────┘  └───────────────┘
```

---

## 6. Deeper Example: Conditional Branches

NLL's liveness analysis handles branches correctly:

```rust
fn first_or_push(v: &mut Vec<i32>) -> &i32 {
    if v.is_empty() {
        v.push(0);           // mutable use — borrow active here
    }
    &v[0]                    // shared borrow returned — mutable borrow must be done
}
```

Pre-NLL couldn't prove the mutable borrow was done in the `if` branch before the shared borrow in `&v[0]`. NLL's CFG analysis can.

---

## 7. Memory & CPU — What's Actually Happening

### Stack Frames and Drops

```
Stack (high address)
┌─────────────────────────────┐
│  main() frame               │
│  ┌───────────────────────┐  │
│  │ data: String          │  │  ← heap ptr + len + cap on stack
│  │   ptr ──────────────────────────────────► [h,e,l,l,o] on heap
│  │   len: 5              │  │
│  │   cap: 8              │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

A `&mut String` is just a **pointer** (8 bytes on x86-64) stored on the stack pointing at `data`'s stack slot. There is *no runtime cost* to starting or ending a borrow — it's purely a compile-time concept. The CPU never sees borrow information.

### What "Drop" Actually Does

When a variable goes out of scope and implements `Drop` (like `String`, `Vec`):
1. The compiler inserts a call to `drop(variable)` at the end of its live range.
2. `String::drop` calls `dealloc` on the heap buffer → the OS gets the memory back.
3. For types like `i32` with no heap allocation, drop is a no-op and the stack frame is simply decremented.

### Borrow Checker Is Purely Compile-Time

```
Source Code
    │
    ▼
Parsing / HIR
    │
    ▼
MIR (Mid-level Intermediate Representation)  ← NLL analysis happens here
    │  (CFG of basic blocks + assignments)
    ▼
Borrow Checker (Polonius in progress, NLL now)
    │  "Is any live borrow conflicting?"
    ▼
LLVM IR → Machine Code  ← zero borrow info here; pure pointers
```

NLL works on **MIR** — a CFG where each basic block is a list of statements. The liveness analysis is a standard dataflow problem (backward liveness analysis): a variable is live at point P if it is used on at least one path from P to program exit.

### Why Mutable Borrows Prevent Aliasing

At the CPU level, if two pointers alias the same memory and one writes while the other reads, you get a **data race** (on multiple threads) or **undefined behavior** (the compiler may cache the value in a register, making the read stale). Rust's `&mut` exclusivity guarantee allows the compiler to apply `noalias` on the LLVM pointer, enabling aggressive optimizations that C with unrestricted pointers cannot do.

---

## 8. Diagrams

### Borrow Lifecycle (NLL)

```
Source line:   1        2          3         4
               │        │          │         │
               let mut  let r =    r.push()  println!(v)
               v = ..   &mut v     ← last    ← safe
                        │          use of r  │
Ownership:    [v owned ─────────────────────────────────►]
Borrow r:              [r live ────┤
                                   ▲ NLL ends borrow here
```

### CFG for Branch Example

```
         ┌─────────────┐
         │ Entry       │
         └──────┬──────┘
                │
         ┌──────▼──────┐
         │ v.is_empty()│
         └──┬──────┬───┘
       true │      │ false
    ┌───────▼──┐   │
    │ v.push(0)│   │  ← &mut v used here (branch 1)
    └───────┬──┘   │
            └──────┘
         ┌──────▼──────┐
         │  &v[0]      │  ← &v used here; &mut must be dead on all paths
         └─────────────┘
```

NLL computes liveness per-path. On the `false` branch, `v.push` was never called, so `&mut v` was never live going into `&v[0]`. Both paths are safe.

---

## 9. Polonius — The Next Step (In Progress)

RFC 2094 (NLL) improved things enormously but still has edge cases where the analysis is too conservative. **Polonius** (named after Hamlet's advisor) is a next-generation borrow checker using **Datalog** (logical inference rules) to express lifetimes as relations rather than ranges.

- **Status**: Experimental, available with `-Z polonius` nightly flag.
- **Repo**: https://github.com/rust-lang/polonius
- **RFC tracking**: https://github.com/rust-lang/rust/issues/54186

A famous case Polonius fixes but NLL doesn't:

```rust
fn get_or_insert<'a>(map: &'a mut HashMap<&str, String>, key: &str) -> &'a String {
    if let Some(v) = map.get(key) {
        return v;  // NLL can't prove the mutable borrow ends on this path
    }
    map.entry(key).or_insert_with(|| key.to_owned())
}
// ❌ fails with NLL, ✅ passes with Polonius
```

---

## 10. Meta-Cognition Framework

### Questions to Test Understanding

**Level 1 — Recall**
- [ ] What does "lexical scope" mean in Rust? How do `{ }` define it?
- [ ] What rule did the pre-NLL borrow checker use to decide when a borrow ends?
- [ ] When was NLL stabilized and for which edition?

**Level 2 — Comprehension**
- [ ] Why is extending a borrow to the end of a block *safe but overly conservative*?
- [ ] What is "liveness analysis"? How does it differ from a simple scope check?
- [ ] If a `&mut` borrow is created in an `if` branch but not the `else` branch, when does each path's borrow end under NLL?

**Level 3 — Application**
- [ ] Take this snippet and draw the NLL borrow timeline:
  ```rust
  let mut s = String::new();
  let r1 = &mut s;
  r1.push('a');
  let r2 = &mut s;
  r2.push('b');
  println!("{}", s);
  ```
- [ ] Predict whether this compiles with NLL and explain why:
  ```rust
  fn foo(v: &mut Vec<i32>) -> Option<&i32> {
      if v.len() > 0 { Some(&v[0]) } else { v.push(1); None }
  }
  ```

**Level 4 — Analysis**
- [ ] The borrow checker operates on MIR, not source code. Why does this matter for analysis precision?
- [ ] How does Rust's `noalias` annotation (derived from `&mut` exclusivity) help the LLVM optimizer?
- [ ] What limitation of NLL does Polonius address? What is conceptually different about Polonius's approach?

**Level 5 — Synthesis**
- [ ] Design a function signature where pre-NLL would reject a clearly-safe pattern. Write the workaround code using artificial scoping blocks.
- [ ] Explain to someone else: "A Rust reference is a compile-time fiction — the CPU only sees pointers."
- [ ] Why can't garbage-collected languages like Go or Java give you the same aliasing guarantees Rust does?

### Spaced Repetition Prompts

```
Q: What RFC introduced NLL and what year was it stabilized?
A: RFC 2094; stabilized in Rust 1.36 (2019), enabled by default in 2018 edition.

Q: Under NLL, when exactly does a &mut borrow end?
A: At the last use of the reference in the control-flow graph.

Q: What is the pre-NLL borrow "last used here" error pointing at?
A: The closing `}` of the scope — the borrow was considered live until then.

Q: Does borrow checking have any runtime overhead?
A: No. It is purely compile-time analysis on MIR. The CPU sees only raw pointers.
```

---

## 11. Code to Run

### Experiment 1 — Observe NLL in Action

```rust
// Run with: rustc --edition 2021 -o nll_demo nll_demo.rs && ./nll_demo
fn main() {
    let mut data = vec![1, 2, 3];

    let r = &mut data;
    r.push(4);
    // r is dead here — NLL knows this

    println!("{:?}", data);  // ✅ prints [1, 2, 3, 4]
}
```

### Experiment 2 — Manually Observe Lifetimes with `drop`

```rust
fn main() {
    let mut s = String::from("hello");

    {
        let r = &mut s;
        r.push_str(", world");
        println!("via borrow: {}", r);
    } // r dropped here (explicit scope — same result as NLL for this case)

    println!("owned: {}", s);
}
```

### Experiment 3 — Two Sequential Mutable Borrows (NLL Required)

```rust
fn main() {
    let mut v = vec![1, 2, 3];

    let a = &mut v;
    a.push(4);          // last use of a

    let b = &mut v;     // ✅ NLL allows this; pre-NLL would reject
    b.push(5);

    println!("{:?}", v); // [1, 2, 3, 4, 5]
}
```

### Experiment 4 — Forcing a Compile Error to See the Message

```rust
// Save as error_demo.rs and compile to see the borrow error
fn main() {
    let mut v = vec![1];
    let r = &mut v;
    let _also = &v;     // ❌ shared borrow while mutable borrow still alive
    println!("{:?}", r);
}
// rustc --edition 2021 error_demo.rs
```

### Experiment 5 — Inspect MIR

```bash
# See the MIR that the borrow checker operates on
rustc --edition 2021 --emit mir -o /tmp/mir_out nll_demo.rs
cat /tmp/mir_out.mir
```

Look for `StorageLive`, `StorageDead` markers — these correspond to liveness boundaries the NLL analysis uses.

---

## 12. Supporting Reference Material

| Resource | Description |
|---|---|
| [RFC 2094 — NLL](https://rust-lang.github.io/rfcs/2094-nll.html) | The original RFC with full motivation and design |
| [Rustonomicon — Lifetimes](https://doc.rust-lang.org/nomicon/lifetimes.html) | Low-level lifetime semantics |
| [Rust Reference — Scopes](https://doc.rust-lang.org/reference/destructors.html) | Official spec for drop order and scope semantics |
| [Polonius repo](https://github.com/rust-lang/polonius) | Next-gen borrow checker using Datalog |
| [NLL stabilization blog post](https://blog.rust-lang.org/2019/07/04/Rust-1.36.0.html) | Rust 1.36 release notes |
| [Jon Gjengset — Crust of Rust: Lifetimes](https://www.youtube.com/watch?v=rAl-9HwD858) | Deep video walkthrough of lifetime mechanics |
| [Niko Matsakis — NLL blog series](https://smallcultfollowing.com/babysteps/blog/2016/04/27/non-lexical-lifetimes-introduction/) | Original design posts from the language team lead |
| [MIR internals](https://rustc-dev-guide.rust-lang.org/mir/index.html) | How rustc builds the CFG NLL analyzes |

---

## 13. Summary

```
Old (lexical):  borrow ends at }
                └── safe but overly conservative
                └── forces artificial scoping blocks
                └── confusing "used here" errors pointing at }

NLL (RFC 2094): borrow ends at last use in CFG
                └── same safety guarantees
                └── no runtime cost — compile-time only
                └── liveness analysis on MIR basic blocks
                └── enables natural, idiomatic code

Polonius (WIP): borrow ends per-path in CFG (relation-based)
                └── fixes remaining NLL false positives
                └── experimental nightly only
```

> **Core insight**: A borrow is a promise to the compiler, not a runtime object. Extending that promise beyond the last line that needs it is wasteful. NLL taught the compiler to notice when the promise is no longer needed.
