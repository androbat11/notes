#### [Variables and Data Interacting with Move](https://doc.rust-lang.org/book/ch04-01-what-is-ownership.html#variables-and-data-interacting-with-move)

## What is Move?

A **move** is Rust's mechanism for transferring ownership of a resource from one variable to another. When a move occurs:

1. The new variable takes ownership of the data
2. The original variable is **invalidated** and can no longer be used
3. No data is copied on the heap—only the stack pointer/metadata is transferred

This prevents [[DoubleFreeBug|double-free bugs]] by ensuring exactly one owner exists at any time.

## When Does Move Happen?

Moves occur by default for types that **don't** implement the `Copy` trait:

```rust
// 1. Assignment
let s1 = String::from("hello");
let s2 = s1;  // s1 is moved to s2, s1 is now invalid

// 2. Passing to functions
fn take_ownership(s: String) {
    println!("{s}");
} // s is dropped here

let s = String::from("hello");
take_ownership(s);  // s is moved into the function
// println!("{s}");  // Error! s was moved

// 3. Returning from functions
fn give_ownership() -> String {
    let s = String::from("hello");
    s  // ownership moves to the caller
}

let s = give_ownership();  // s now owns the String
```

## Move vs Copy

Not all types move. Simple stack-only types implement `Copy` and are duplicated instead:

```rust
// Integers implement Copy - no move occurs
let x = 5;
let y = x;
println!("{x}");  // Fine! x is still valid

// String does NOT implement Copy - move occurs
let s1 = String::from("hello");
let s2 = s1;
// println!("{s1}");  // Error! s1 was moved
```

| Move (ownership transfers) | Copy (bitwise duplicate) |
|---------------------------|--------------------------|
| `String`, `Vec<T>`, `Box<T>` | `i32`, `f64`, `bool`, `char` |
| Types with heap allocations | Stack-only, fixed-size types |

## Memory Visualization

```
Before move (let s2 = s1):
Stack                    Heap
s1: [ptr|len|cap]  --->  "hello"

After move:
Stack                    Heap
s1: (invalid)
s2: [ptr|len|cap]  --->  "hello"
```

Only the stack data (pointer, length, capacity) is copied. The heap data stays in place, and `s1` is marked invalid.

## Avoiding Move

If you need to keep the original variable valid:

```rust
// Option 1: Clone (deep copy)
let s1 = String::from("hello");
let s2 = s1.clone();
println!("{s1} {s2}");  // Both valid

// Option 2: Borrow (reference without taking ownership)
let s1 = String::from("hello");
let s2 = &s1;
println!("{s1} {s2}");  // Both valid
```
