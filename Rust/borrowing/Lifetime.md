---
title: Lifetimes in Rust
description: ''
author: generic-claude-agent
created: 2026-04-12T14:38:33.668941+00:00
remargin_pending: 0
remargin_pending_for: []
remargin_last_activity: null
---

# Lifetimes in Rust

## What is a Lifetime?

==A **lifetime** is a compile-time annotation that tells the Rust borrow checker *how long a reference is valid*. Every reference in Rust has a lifetime, but most of the time the compiler infers it automatically (lifetime elision).== You only need to annotate explicitly when the compiler cannot figure it out on its own.

Lifetimes are **not** about how long data lives in memory — they are about *constraints on references* to ensure no reference ever outlives the data it points to.

Syntax: `'a`, `'b`, `'static` (tick + name)

---
```rust
// Lifetimes are annotated below with lines denoting the creation
// and destruction of each variable.
// `i` has the longest lifetime because its scope entirely encloses
// both `borrow1` and `borrow2`. The duration of `borrow1` compared
// to `borrow2` is irrelevant since they are disjoint.
fn main() {
    let i = 3; // Lifetime for `i` starts. ────────────────┐
    //                                                     │
    { //                                                   │
        let borrow1 = &i; // `borrow1` lifetime starts. ──┐│
        //                                                ││
        println!("borrow1: {}", borrow1); //              ││
    } // `borrow1` ends. ─────────────────────────────────┘│
    //                                                     │
    //                                                     │
    { //                                                   │
        let borrow2 = &i; // `borrow2` lifetime starts. ──┐│
        //                                                ││
        println!("borrow2: {}", borrow2); //              ││
    } // `borrow2` ends. ─────────────────────────────────┘│
    //                                                     │
}   // Lifetime ends. ─────────────────────────────────────┘
```

## The Problem Lifetimes Solve

```rust
fn longest(x: &str, y: &str) -> &str {   // ❌ won't compile
    if x.len() > y.len() { x } else { y }
}
```

The compiler asks: *how long is the returned reference valid?* It depends on `x` and `y`, but which one? Without an annotation it cannot know.

---

## Lifetime Annotation Syntax

Lifetime annotations go after `&` and before the type:

```rust
&i32          // a reference
&'a i32       // a reference with lifetime 'a
&'a mut i32   // a mutable reference with lifetime 'a
```

They are placed on **function signatures**, **structs**, and **impl blocks** — not on variables.

---

## Example 1 — Function Returning a Reference

```rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}
```

**Reading it:** "Given two string slices that both live *at least* as long as `'a`, return a string slice that lives *at least* as long as `'a`."

The concrete lifetime `'a` will be the *shorter* of the two input lifetimes — because the returned reference must be safe to use for as long as the caller keeps it.

```rust
fn main() {
    let s1 = String::from("long string");
    let result;
    {
        let s2 = String::from("xy");
        result = longest(s1.as_str(), s2.as_str());
        println!("{result}");  // ✅ s2 still alive here
    }
    // println!("{result}"); // ❌ s2 dropped, result would dangle
}
```

---

## Example 2 — Lifetime in a Struct

When a struct holds a reference, it needs a lifetime parameter so the compiler can guarantee the struct doesn't outlive the data it references.

```rust
struct Excerpt<'a> {
    part: &'a str,
}

fn main() {
    let novel = String::from("Call me Ishmael. Some years ago...");
    let first_sentence = novel.split('.').next().expect("no period");

    let excerpt = Excerpt { part: first_sentence };
    println!("{}", excerpt.part);
}
```

`Excerpt<'a>` says: "An `Excerpt` cannot outlive the string slice stored in `part`."

---

## Example 3 — `'static` Lifetime

`'static` means the reference is valid for the *entire duration of the program*. String literals are the most common example:

```rust
let s: &'static str = "I am baked into the binary";
```

> Tip: When the compiler suggests adding `'static`, think twice. It often signals a design issue — you may be trying to escape a borrow problem rather than fix it.

---

## Lifetime Elision Rules

The compiler applies three rules before requiring explicit annotations:

1. **Each reference parameter gets its own lifetime.**
   `fn foo(x: &str, y: &str)` → `fn foo<'a, 'b>(x: &'a str, y: &'b str)`

2. **If there is exactly one input lifetime, it is assigned to all output lifetimes.**
   `fn foo(x: &str) -> &str` → `fn foo<'a>(x: &'a str) -> &'a str`

3. **If one of the inputs is `&self` or `&mut self`, its lifetime is assigned to all output lifetimes.**
   Most method return values fall under this rule.

If none of the three rules fully determines the output lifetime, the compiler will ask you to annotate explicitly.

---

## Example 4 — Lifetimes in `impl` Blocks

```rust
impl<'a> Excerpt<'a> {
    fn level(&self) -> i32 {
        3
    }

    fn announce(&self, announcement: &str) -> &str {
        println!("Attention: {announcement}");
        self.part  // elision rule 3: output lifetime = 'self
    }
}
```

---

## Mental Model

Think of a lifetime as a **scope label**. The borrow checker draws a region on a timeline for each variable. A lifetime annotation says "these two references must overlap in time." The compiler verifies no reference outlives its region.

```
s1:  |===================|
s2:      |=======|
'a:      |=======|   ← the overlap (shortest of s1, s2)
result must be used within 'a
```

---

## Meta-Cognition Questions

Use these to check and deepen your understanding:

1. **Predict the error.** What happens if you move the `println!("{result}")` call outside the inner block in Example 1? Can you explain *why* before running the code?

2. **Elision or explicit?** Look at this signature:
   ```rust
   fn first_word(s: &str) -> &str
   ```
   Which elision rule(s) apply? Write the fully-annotated version yourself.

3. **Struct lifetime reasoning.** If you tried to return an `Excerpt` whose `part` points to a local `String` created inside the function, what would go wrong? What is the compiler actually protecting you from?

4. **`'static` trap.** A colleague adds `'static` to fix a lifetime error. Is that always correct? What question should you ask before accepting that fix?

5. **Contrast with ownership.** How does a lifetime differ from ownership? Can a value have multiple references with different lifetimes simultaneously?

6. **Design question.** If you find yourself needing many explicit lifetime annotations across multiple functions, what might that signal about the data design? What alternatives (owned data, `Arc`, restructuring) could eliminate the need?

---

## Further Reading

**Official**
- [The Rust Book — Chapter 10.3: Lifetime Syntax](https://doc.rust-lang.org/book/ch10-03-lifetime-syntax.html) — the canonical starting point, free online
- [The Rustonomicon](https://doc.rust-lang.org/nomicon/) — goes deep into lifetimes, variance, and unsafe memory. Read after you're comfortable with the basics.

**Focused deep dives**
- [The Rust Reference — Lifetime elision rules](https://doc.rust-lang.org/reference/lifetime-elision.html) — precise rules the compiler uses, useful when elision surprises you
- [Jon Gjengset — "Crust of Rust: Lifetime Annotations"](https://www.youtube.com/watch?v=rAl-9HwD858) — 90min live coding session, widely considered the best video explanation of lifetimes

**For the ownership/memory model**
- [The Rust Book — Chapter 4: Ownership](https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html) — read this before the Rustonomicon
- [Learn Rust With Entirely Too Many Linked Lists](https://rust-unofficial.github.io/too-many-lists/) — building linked lists forces hands-on wrestling with ownership and lifetimes

**Suggested order:**
1. Rust Book ch. 4 → ch. 10.3
2. Jon Gjengset video
3. Too Many Linked Lists
4. Rustonomicon (when ready)
