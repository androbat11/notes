# Non-Lexical Lifetimes (NLL) — RFC 2094

> **Prerequisites**: You understand [[Lexical scope]], ownership, `&T` (shared borrow), and `&mut T` (exclusive mutable borrow).

---

## 1. The Problem NLL Solves

Before NLL, the borrow checker used a simple rule:

> A borrow's lifetime = the lexical scope it was created in.

This was *safe* but *conservative*. The compiler could not see that a reference was no longer used after line 3 — it only saw that the enclosing `}` was at line 10. So it kept the borrow "alive" through all 10 lines, blocking any other use of the value in between.

**The consequence**: code that was obviously safe to any human reader was rejected by the compiler.

```rust
// Every human can see r is done after line 4.
// Pre-NLL compiler cannot.

fn main() {
    let mut v = vec![1, 2, 3];
    let r = &mut v;   // borrow starts
    r.push(4);        // last real use ← human sees it ends here
                      // compiler sees: borrow alive until }
    println!("{:?}", v); // ❌ error: v still mutably borrowed
}
```

NLL fixes this by asking a different question:

> **Pre-NLL**: "Is this borrow inside the same lexical scope as the conflicting use?"
> **NLL**: "Is this borrow *live* — i.e., could it be used again — at the conflicting use point?"

---

## 2. What "Lifetime" Really Means Under NLL

In NLL, a lifetime is no longer a contiguous block of source code. It is the **set of program points** at which a reference is live — where "live" means: *there exists a path from this point to a future use of the reference*.

This is classic **backward liveness analysis** from compiler theory, applied to the MIR (Mid-level Intermediate Representation) control-flow graph.

```
Liveness definition:
  ref r is live at point P
  ⟺
  ∃ a path from P to some future use of r
    that does not pass through a reassignment of r
```

When no such path exists, `r` is **dead** — and its lifetime ends there.

---

## 3. How the Compiler Changes Under NLL

### Pre-NLL Pipeline

```
Source Code
    │
    ▼
HIR (High-level IR)
    │
    ▼
Borrow Checker (scope-based)  ← checks: "same { } block?"
    │
    ▼
LLVM → Binary
```

### NLL Pipeline

```
Source Code
    │
    ▼
HIR
    │
    ▼
MIR (Mid-level IR)  ← CFG of basic blocks + statements
    │
    ▼
Liveness Analysis   ← backward dataflow: "is r used on any future path?"
    │
    ▼
Borrow Checker      ← checks: "is any live borrow conflicting at this point?"
    │
    ▼
LLVM → Binary
```

The critical difference: the borrow checker now operates on the **MIR control-flow graph**, not on the nesting of curly braces. Each basic block is a linear sequence of statements; edges represent control flow (branches, loops, function returns). Liveness propagates *backwards* through these edges.

### What MIR Looks Like

For this function:
```rust
fn demo() {
    let mut v = vec![1];
    let r = &mut v;
    r.push(2);
    println!("{:?}", v);
}
```

The MIR basic block (simplified) looks like:
```
bb0:
  _1 = Vec::new()          // let mut v
  _2 = &mut _1             // let r = &mut v
  Vec::push(_2, 2)         // r.push(2)
  StorageDead(_2)          // ← NLL inserts this: r is dead
  _3 = &_1                 // borrow for println
  println(_3)
  return
```

`StorageDead(_2)` is the NLL compiler explicitly marking the end of `r`'s lifetime — inserted automatically based on liveness analysis, not on scope boundaries.

---

## 4. Before / After: The Same Code

### Without NLL (Rust ≤ 2015 edition, or pre-1.36)

```rust
fn main() {
    let mut data = String::from("hello");

    let r: &mut String = &mut data;  // ← borrow starts
    r.push_str(", world");           // ← last use of r

    // r never touched again — but compiler keeps borrow alive until }

    println!("{}", data);            // ❌ error[E0502]
}                                    // ← borrow ends here (lexical)
```

**Error**:
```
error[E0502]: cannot borrow `data` as immutable because it is also borrowed as mutable
 --> src/main.rs:7:20
  |
3 |     let r: &mut String = &mut data;
  |                          --------- mutable borrow occurs here
7 |     println!("{}", data);
  |                    ^^^^ immutable borrow occurs here
8 | }
  | - mutable borrow later used here   ← POINTS AT THE CLOSING BRACE
```

Notice: the error says the mutable borrow is "later used" at `}` — the compiler has no finer resolution than the scope boundary.

---

### With NLL (Rust 2018+ / 1.36+)

```rust
fn main() {
    let mut data = String::from("hello");

    let r: &mut String = &mut data;  // ← borrow starts
    r.push_str(", world");           // ← last use → NLL ends borrow HERE

    // NLL liveness: r is not used on any path from this point forward
    // Therefore: &mut data borrow is dead. No conflict.

    println!("{}", data);            // ✅ compiles fine
}
```

---

## 5. Visual: Lifetime Comparison

```
                    Pre-NLL                           NLL
                    ───────                           ───

 let mut data = ..  │                                 │
 let r = &mut data  ├── &mut borrow LIVE ─────────┐  ├── &mut borrow LIVE ─┐
 r.push_str(...)    │         ↑ last use           │  │     ↑ last use      │ ends
                    │                              │  │                     ▼
 println!(data)     │  ❌ conflict: still borrowed │  │  ✅ borrow is dead
 }                  └──────────────────────────────┘  │
                      borrow ends at }                 └─ (nothing)
```

```
Program points (numbered):

  1: let mut data = ...
  2: let r = &mut data    ← borrow created
  3: r.push_str(...)      ← last use of r
  4: println!(data)       ← uses data immutably
  5: }                    ← end of main

Pre-NLL liveness of r:  {2, 3, 4, 5}   ← r "alive" at point 4 → conflict
NLL liveness of r:      {2, 3}         ← r dead at point 4 → no conflict
```

---

## 6. NLL Handles Branches Correctly

NLL computes liveness **per control-flow path**, not just linearly.

```rust
fn process(v: &mut Vec<i32>, condition: bool) {
    let r = &mut *v;

    if condition {
        r.push(1);       // r used in this branch
    }
    // r is dead here on BOTH paths:
    //   - true path:  r was used in push, now dead
    //   - false path: r was never used, always dead

    println!("{:?}", v); // ✅ NLL knows r is dead on all outgoing paths
}
```

```
CFG:
                ┌───────────────┐
                │ let r = &mut v│
                └───────┬───────┘
                        │
               ┌────────▼────────┐
               │ if condition    │
               └──┬──────────┬───┘
          true    │          │  false
     ┌────────────▼──┐    ┌──▼────────────┐
     │  r.push(1)    │    │  (nothing)    │
     │  r is dead ✓  │    │  r is dead ✓ │
     └────────────┬──┘    └──┬────────────┘
                  └────┬─────┘
                       │
               ┌───────▼────────┐
               │ println!(v)    │  ← r is dead on ALL incoming paths → safe
               └────────────────┘
```

---

## 7. Two Sequential Mutable Borrows

A natural pattern that pre-NLL rejected entirely:

```rust
fn main() {
    let mut v = vec![1, 2, 3];

    let a = &mut v;
    a.push(4);          // ← last use of a → NLL ends a's borrow

    let b = &mut v;     // ✅ a is dead; this is a fresh borrow
    b.push(5);

    println!("{:?}", v); // [1, 2, 3, 4, 5]
}
```

```
Timeline:

  a borrow:  [─────────────┤
  b borrow:                [──────────────┤
  println:                               [──]

  No overlap → no conflict.
```

Pre-NLL would reject `let b = &mut v` because `a`'s borrow hadn't "ended" yet (the `}` hadn't been reached). You'd have to wrap `a` in its own `{ }` block.

---

## 8. Loop Example: NLL Precision

```rust
fn find_first_even(v: &mut Vec<i32>) -> Option<&mut i32> {
    for x in v.iter_mut() {
        if *x % 2 == 0 {
            return Some(x);  // borrow extends through return
        }
        // x is dead after this iteration — NLL knows it
    }
    None
}
```

NLL tracks that on the `return Some(x)` path the borrow outlives the function (caller gets it), but on the non-returning path through the loop body, `x` is dead at the start of the next iteration.

---

## 9. What NLL Does NOT Fix (Polonius)

NLL still has false positives. The classic example:

```rust
fn get_or_insert<'a>(map: &'a mut HashMap<&str, String>, key: &str) -> &'a String {
    if let Some(v) = map.get(key) {
        return v;                            // ← borrows map immutably
    }
    map.entry(key).or_insert_with(String::new) // ← borrows map mutably
}
```

**NLL rejects this** because it sees the `&map` borrow from `map.get(key)` as potentially overlapping with the `&mut map` from `map.entry(...)` — even though the `return v` on the true branch means they can never co-exist at runtime.

This is the **two-phase borrow** / **conditional return** problem. It requires **Polonius** — a relation-based borrow checker that reasons about lifetimes as logical facts, not intervals.

- Polonius tracks: "which loans are *live* at which *origins*" using Datalog rules.
- Available today with `RUSTFLAGS="-Z polonius"` on nightly.
- RFC: https://github.com/rust-lang/rust/issues/54186

---

## 10. Memory & CPU Perspective

### Borrows Are Zero-Cost at Runtime

A `&mut T` is a raw pointer at the machine level — 8 bytes on x86-64. The borrow checker's lifetime analysis produces **no instructions**. The CPU executes:

```asm
; let r = &mut data   →   lea rax, [rbp - 24]   (load address of data)
; r.push_str(...)     →   call String::push_str
; println!(data)      →   lea rax, [rbp - 24]   (same address, no difference)
```

The lifetime being "ended early" by NLL simply means: the compiler stops caring about aliasing rules at that point. It may freely reuse the stack slot, hoist loads/stores, or alias-optimize LLVM IR.

### `noalias` and Optimizer Impact

Because `&mut T` guarantees exclusive access, Rust tags its LLVM IR with `noalias`:

```llvm
define void @process(%String* noalias %r, ...) {
```

`noalias` tells LLVM: "no other pointer aliases this one during this function's execution." LLVM can then:
- Cache values in registers instead of reloading from memory.
- Reorder loads/stores freely.
- Eliminate redundant memory reads.

NLL makes `noalias` more precise: the annotated scope is tighter, enabling more optimization without relaxing safety.

### Stack Layout During Borrows

```
Stack frame for main():

High addr ┌─────────────────────────┐
          │  data: String           │  ← 24 bytes: (ptr, len, cap)
          │    .ptr ────────────────────────► heap: "hello, world\0"
          │    .len = 12            │
          │    .cap = 16            │
          ├─────────────────────────┤
          │  r: &mut String = 8B   │  ← just a pointer to data's slot above
          │    = 0x7fff_xxxx        │
          └─────────────────────────┘
Low addr

After NLL marks r as dead:
- The 8-byte slot for r may be reclaimed/reused by the compiler
- The heap allocation is untouched (owned by data, not r)
- The next borrow of data creates a new 8-byte pointer in the same or different slot
```

---

## 11. Meta-Cognition Framework

### Questions to Test Understanding

**Level 1 — Recall**
- [ ] What does NLL stand for and what RFC introduced it?
- [ ] What is the difference between a "lexical lifetime" and an NLL lifetime?
- [ ] On what IR does the NLL borrow checker operate — HIR, MIR, or LLVM IR?

**Level 2 — Comprehension**
- [ ] What is "liveness analysis"? Define it precisely.
- [ ] Why does liveness analysis run *backwards* through the CFG?
- [ ] What does `StorageDead` in MIR represent, and who inserts it?

**Level 3 — Application**
- [ ] Trace through this code and mark where NLL ends each borrow:
  ```rust
  let mut s = String::new();
  let r1 = &mut s;
  r1.push('a');
  let r2 = &s;
  println!("{}", r2);
  ```
- [ ] Will this compile under NLL? Why or why not?
  ```rust
  let mut v = vec![1];
  let r = &v[0];
  v.push(2);
  println!("{}", r);
  ```

**Level 4 — Analysis**
- [ ] The "two-phase borrow" example with `HashMap` compiles with Polonius but not NLL. Why is NLL too conservative here? What information would you need to prove it's safe?
- [ ] How does `noalias` in LLVM IR relate to Rust's `&mut` exclusivity? Give a concrete optimization it enables.
- [ ] Compare NLL's approach (intervals on a CFG) to Polonius's approach (Datalog relations). What is the fundamental difference in expressiveness?

**Level 5 — Synthesis**
- [ ] Write a function that cannot compile with NLL but would compile with Polonius. Explain the false positive.
- [ ] Explain: "Lifetime annotations in function signatures (`fn foo<'a>(x: &'a T) -> &'a T`) are not NLL — they are a separate system. NLL handles intra-function lifetimes. Annotations handle inter-function lifetimes."
- [ ] Why can't NLL be implemented as a source-level transformation (on HIR)? What property of MIR makes it necessary?

### Spaced Repetition Prompts

```
Q: At what granularity does NLL end a borrow?
A: At the last point of use in the control-flow graph — not at end of block.

Q: What analysis technique does NLL use?
A: Backward liveness analysis on the MIR control-flow graph.

Q: What is a false positive in the NLL borrow checker?
A: Code that is safe at runtime but rejected by NLL's conservative analysis.

Q: What is Polonius and how does it differ from NLL?
A: A relation-based (Datalog) borrow checker that reasons per-path about
   loan liveness, fixing NLL's remaining false positives.

Q: Does ending a borrow early (NLL) cost anything at runtime?
A: No. Borrows are purely compile-time. The CPU only sees pointers.
```

---

## 12. Code to Run

### Experiment 1 — NLL Basic Demo

```rust
// nll_basic.rs — run: rustc --edition 2021 nll_basic.rs && ./nll_basic
fn main() {
    let mut v = vec![1, 2, 3];

    let r = &mut v;
    r.push(4);
    // NLL: r is dead here

    println!("{:?}", v);  // ✅ [1, 2, 3, 4]
}
```

### Experiment 2 — Sequential Mutable Borrows

```rust
fn main() {
    let mut s = String::from("foo");

    let a = &mut s;
    a.push_str("bar");    // last use of a

    let b = &mut s;       // ✅ a is dead
    b.push_str("baz");

    println!("{}", s);    // foobarbaz
}
```

### Experiment 3 — View MIR to See StorageDead

```bash
# Emit MIR and look for StorageDead
rustc --edition 2021 --emit mir nll_basic.rs -o /tmp/nll
cat nll_basic.mir | grep -A2 -B2 "StorageDead"
```

You will see `StorageDead(_N)` inserted *before* the `println` — this is NLL marking the borrow as ended.

### Experiment 4 — See the Polonius False Positive

```rust
// This fails with NLL. Try compiling to observe the error.
use std::collections::HashMap;

fn get_or_default<'a>(map: &'a mut HashMap<String, String>, key: &str) -> &'a str {
    if let Some(v) = map.get(key) {
        return v;
    }
    map.entry(key.to_owned()).or_insert_with(String::new)
}
// rustc --edition 2021 polonius_demo.rs
// → error[E0502]: cannot borrow `*map` as mutable because it is also borrowed as immutable
```

```bash
# Now try with Polonius (nightly only):
RUSTFLAGS="-Z polonius" cargo +nightly build
# ✅ compiles
```

### Experiment 5 — Confirm Zero Runtime Cost

```bash
# Compile with and without the NLL pattern, compare assembly
rustc --edition 2021 --emit asm -C opt-level=2 nll_basic.rs
# Inspect: borrows produce no extra instructions vs. direct pointer use
```

---

## 13. Supporting Reference Material

| Resource | URL / Location |
|---|---|
| RFC 2094 — NLL | https://rust-lang.github.io/rfcs/2094-nll.html |
| Niko Matsakis — NLL Introduction | https://smallcultfollowing.com/babysteps/blog/2016/04/27/non-lexical-lifetimes-introduction/ |
| Niko Matsakis — NLL Deep Dive (series) | https://smallcultfollowing.com/babysteps/blog/2018/04/27/an-alias-based-formulation-of-the-borrow-checker/ |
| rustc Dev Guide — NLL | https://rustc-dev-guide.rust-lang.org/borrow_check/region_inference.html |
| rustc Dev Guide — MIR | https://rustc-dev-guide.rust-lang.org/mir/index.html |
| Polonius repo | https://github.com/rust-lang/polonius |
| Rust Reference — Destructors / Scopes | https://doc.rust-lang.org/reference/destructors.html |
| Jon Gjengset — Crust of Rust: Lifetimes | https://www.youtube.com/watch?v=rAl-9HwD858 |
| LLVM noalias semantics | https://llvm.org/docs/LangRef.html#noalias |
| Related note | [[Lexical scope]] |

---

## 14. Summary

```
Problem:    Pre-NLL borrow checker tied lifetimes to lexical scopes ({ }).
            Borrows lived until }, even if last used on line 2.

Solution:   NLL computes liveness on the MIR CFG.
            A borrow ends at its last use on any path through the program.

Mechanism:  Backward liveness analysis on basic blocks.
            StorageDead markers inserted automatically.
            Zero runtime cost — purely compile-time.

Result:     Sequential &mut borrows work naturally.
            No artificial scoping blocks needed.
            More idiomatic, ergonomic safe code.

Remaining:  Polonius (Datalog-based) fixes NLL's remaining false positives.
            Experimental on nightly; full stabilization in progress.
```

> **Core insight**: NLL didn't change what is *safe* — it changed what the compiler could *prove* was safe. The set of valid programs grew; the safety guarantees stayed identical.
