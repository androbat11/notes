# Borrowing in Rust

## What is Borrowing?

**Borrowing** is Rust's mechanism for temporarily accessing data without taking ownership. When you borrow a value, the original owner retains ownership, and you get temporary access to read or modify the data.

Borrowing is a **concept**—the act of temporarily using someone else's data. It is enabled through **references**, which are the actual pointers (`&T` or `&mut T`) that provide this access.

## Borrowing vs References

| Term | Category | Description |
|------|----------|-------------|
| **Borrowing** | Concept/Action | The act of temporarily accessing data without ownership |
| **Reference** | Mechanism/Type | The pointer (`&T`, `&mut T`) that enables borrowing |

```rust
let s = String::from("hello");

// The ACTION is borrowing
// The MECHANISM is the reference (&s)
let r = &s;
//      ^^
//      Reference (type: &String)
//
// We say: "r borrows s" or "r is a reference to s"
```

### Analogy

- **Borrowing** = Taking a book from the library temporarily
- **Reference** = The library card that allows you to do it

You **borrow** data **by creating a reference** to it.

## Why Borrowing Exists

Without borrowing, you'd have to transfer ownership every time:

```rust
fn calculate_length(s: String) -> (String, usize) {
    let length = s.len();
    (s, length)  // Must return s to give ownership back!
}

fn main() {
    let s1 = String::from("hello");
    let (s1, len) = calculate_length(s1);  // Awkward!
    println!("{s1} has length {len}");
}
```

With borrowing:

```rust
fn calculate_length(s: &String) -> usize {
    s.len()
}  // s (the reference) goes out of scope, but the data it refers to is NOT dropped

fn main() {
    let s1 = String::from("hello");
    let len = calculate_length(&s1);  // Borrow s1
    println!("{s1} has length {len}"); // s1 still valid!
}
```

## Types of Borrowing

### 1. Immutable Borrowing (`&T`)

Read-only access. Multiple immutable borrows allowed simultaneously.

```rust
let s = String::from("hello");

let r1 = &s;  // First immutable borrow
let r2 = &s;  // Second immutable borrow - OK!
let r3 = &s;  // Third immutable borrow - OK!

println!("{r1}, {r2}, {r3}");  // All valid
```

### 2. Mutable Borrowing (`&mut T`)

Read and write access. Only ONE mutable borrow allowed at a time.

```rust
let mut s = String::from("hello");

let r = &mut s;       // Mutable borrow
r.push_str(" world"); // Can modify through the reference

println!("{r}");  // "hello world"
```

See [[mutableBorrowing]] for more details.

## The Borrowing Rules

Rust enforces these rules at compile time:

### Rule 1: Exclusive Access for Mutation

At any given time, you can have **either**:
- Any number of immutable references (`&T`), **OR**
- Exactly one mutable reference (`&mut T`)

**Never both at the same time.**

```rust
let mut s = String::from("hello");

// This is NOT allowed:
let r1 = &s;      // Immutable borrow
let r2 = &s;      // Immutable borrow
let r3 = &mut s;  // ERROR! Can't have mutable while immutable exist
println!("{r1}, {r2}, {r3}");

// This IS allowed (immutable borrows end before mutable begins):
let r1 = &s;
let r2 = &s;
println!("{r1}, {r2}");  // r1 and r2 last used here

let r3 = &mut s;  // OK! No immutable borrows active
println!("{r3}");
```

### Rule 2: References Must Be Valid

References must always point to valid data (no dangling references).

```rust
// This will NOT compile:
fn dangle() -> &String {
    let s = String::from("hello");
    &s  // ERROR! s is dropped when function ends
}       // Reference would point to freed memory

// Solution: Return the owned value instead
fn no_dangle() -> String {
    let s = String::from("hello");
    s  // Ownership moves to caller
}
```

## Common Use Cases

### 1. Passing Data to Functions Without Losing Ownership

```rust
fn print_info(name: &String, age: &u32) {
    println!("{name} is {age} years old");
}

fn main() {
    let name = String::from("Alice");
    let age = 30;

    print_info(&name, &age);  // Borrow both

    // Still can use name and age here
    println!("Name is still valid: {name}");
}
```

### 2. Reading Data in Loops

```rust
let numbers = vec![1, 2, 3, 4, 5];

// Borrow each element immutably
for n in &numbers {
    println!("{n}");
}

// numbers is still valid
println!("Sum: {}", numbers.iter().sum::<i32>());
```

### 3. Modifying Data In-Place

```rust
fn add_greeting(s: &mut String) {
    s.push_str(", welcome!");
}

fn main() {
    let mut message = String::from("Hello");
    add_greeting(&mut message);
    println!("{message}");  // "Hello, welcome!"
}
```

### 4. Returning References to Internal Data

```rust
fn first_word(s: &String) -> &str {
    let bytes = s.as_bytes();

    for (i, &byte) in bytes.iter().enumerate() {
        if byte == b' ' {
            return &s[0..i];
        }
    }

    &s[..]
}

fn main() {
    let sentence = String::from("hello world");
    let word = first_word(&sentence);  // Returns a slice (reference)
    println!("First word: {word}");
}
```

### 5. Struct Methods That Read Data

```rust
struct Rectangle {
    width: u32,
    height: u32,
}

impl Rectangle {
    fn area(&self) -> u32 {  // &self borrows the struct immutably
        self.width * self.height
    }

    fn set_width(&mut self, width: u32) {  // &mut self borrows mutably
        self.width = width;
    }
}

fn main() {
    let mut rect = Rectangle { width: 10, height: 20 };
    println!("Area: {}", rect.area());  // Immutable borrow

    rect.set_width(15);  // Mutable borrow
    println!("New area: {}", rect.area());
}
```

### 6. Working with Collections

```rust
let mut vec = vec![1, 2, 3];

// Immutable iteration
for item in &vec {
    println!("{item}");
}

// Mutable iteration
for item in &mut vec {
    *item *= 2;  // Double each element
}

println!("{:?}", vec);  // [2, 4, 6]
```

## Memory Visualization

```
OWNERSHIP (Move):
┌─────────┐
│   s1    │ ───────────────┐
└─────────┘                │
                           ▼
let s2 = s1;          ┌─────────────┐
                      │ Heap Data   │
┌─────────┐           │ "hello"     │
│   s2    │ ─────────▶└─────────────┘
└─────────┘
(s1 is now INVALID)


BORROWING (Reference):
┌─────────┐
│   s1    │ ──────────────────────────┐
└─────────┘                           │
     ▲                                ▼
     │                          ┌─────────────┐
let r = &s1;                    │ Heap Data   │
     │                          │ "hello"     │
┌─────────┐                     └─────────────┘
│    r    │ ─── points to s1 ───────▶ │
└─────────┘                           │
(s1 is still VALID)                   │
(r provides temporary access) ────────┘
```

## What Borrowing Prevents

| Problem | How Borrowing Prevents It |
|---------|---------------------------|
| **Data races** | Only one writer OR multiple readers, never both |
| **Dangling pointers** | Compiler ensures references don't outlive data |
| **Use-after-free** | Original owner can't free while borrows exist |
| **Iterator invalidation** | Can't modify collection while iterating |

## Summary

| Aspect | Description |
|--------|-------------|
| **What** | Temporarily accessing data without taking ownership |
| **How** | Creating references with `&` (immutable) or `&mut` (mutable) |
| **Why** | Allows multiple parts of code to use data without complex ownership transfers |
| **Rules** | Many readers OR one writer; references must always be valid |

## Related Concepts

- [[Move]] - Transferring ownership (alternative to borrowing)
- [[mutableBorrowing]] - Mutable references in detail
- [[Slice]] - A common type of borrowed reference to part of a collection
- [[Lifetimes]] - How Rust tracks how long references are valid
