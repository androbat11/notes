# Mutable Borrowing in Rust

## What Is Mutable Borrowing?

**Mutable borrowing** is the act of temporarily taking read-and-write access to a value without taking ownership. It is done by creating a **mutable reference** with the `&mut T` syntax.

Unlike immutable borrowing, which allows many simultaneous readers, mutable borrowing enforces **exclusive access**: while a mutable borrow is active, no other references — mutable or immutable — can exist for the same value.

```rust
let mut s = String::from("hello");

let r = &mut s;       // Mutable borrow: r has exclusive access
r.push_str(" world"); // Can read AND write through r

println!("{r}");      // "hello world"
// s is usable again after r's scope ends
```

---

## Syntax Requirements

Two things must be true before you can mutably borrow a value:

1. The **variable** holding the data must be declared `mut`
2. The **reference** must be written as `&mut`

```rust
// Both must be mut:
//   ┌── variable is mut
//   │          ┌── reference is &mut
let mut value = 5;
let r = &mut value;
```

```rust
// Missing `mut` on the variable → compile error
let value = 5;
let r = &mut value;  // ERROR: cannot borrow `value` as mutable, it is not declared mutable
```

```rust
// Missing `&mut` on the reference → immutable borrow (cannot write)
let mut value = 5;
let r = &value;
*r = 10;  // ERROR: cannot assign to `*r` which is behind a shared reference
```

---

## Memory Model

A mutable reference is a pointer to the original data. It adds no extra layer — it directly accesses the owner's memory location.

```
Stack                     Heap
─────────────────────     ──────────────────────────────
┌────────────────────┐    ┌──────────────────────────┐
│  s (String owner)  │    │                          │
│  ptr  ─────────────┼───▶│  "hello"                 │
│  len: 5            │    │                          │
│  cap: 5            │    └──────────────────────────┘
└────────────────────┘
         ▲
         │  r points to s (not to heap directly)
┌────────┴───────────┐
│  r (&mut String)   │
│  ptr ──────────────┘
└────────────────────┘

Writing through r (*r or r.method()) modifies the heap data.
The owner s "sees" the changes after r is dropped.
```

---

## The Exclusivity Rule

Rust's core guarantee: **at most one mutable reference can exist at a time**, and **no immutable references can coexist with a mutable one**.

```
VALID states for a single value:
─────────────────────────────────────────────────────────

  Many readers (immutable borrows):

  value ◀──── &value (r1)
        ◀──── &value (r2)   ✓  OK
        ◀──── &value (r3)


  One exclusive writer (mutable borrow):

  value ◀════ &mut value (r)   ✓  OK  (no other refs allowed)


INVALID states (compiler rejects these):
─────────────────────────────────────────────────────────

  Writer + Reader at same time:

  value ◀════ &mut value (rw)
        ◀──── &value    (r)   ✗  ERROR: cannot borrow as immutable
                                        because it is also borrowed as mutable


  Two writers at same time:

  value ◀════ &mut value (rw1)
        ◀════ &mut value (rw2)  ✗  ERROR: cannot borrow as mutable
                                           more than once at a time
```

### Why This Rule Exists

This rule eliminates **data races** at compile time. A data race occurs when:
- Two or more pointers access the same data at the same time
- At least one of them is writing
- There is no synchronization

By allowing only one writer with no concurrent readers, Rust makes data races impossible in safe code.

---

## Non-Lexical Lifetimes (NLL)

Since Rust 2018, the borrow checker uses **Non-Lexical Lifetimes**: a borrow ends at the last point it is **used**, not at the closing `}` of its scope. This makes the rules less restrictive.

```rust
let mut s = String::from("hello");

let r1 = &s;           // immutable borrow begins
let r2 = &s;           // second immutable borrow
println!("{r1}, {r2}");
// r1 and r2 are NOT used after this line → their borrows END here

let r3 = &mut s;       // mutable borrow: OK, r1 and r2 are gone
r3.push_str(" world");
println!("{r3}");
```

```
Timeline (NLL):

r1 ─────────────────┤  ends at last use (println)
r2 ─────────────────┤  ends at last use (println)
r3                  ├─────────────────────────────┤

                    ↑
            no overlap: valid!
```

Without NLL (old lexical scopes), this would have failed because `r1` and `r2` would stay alive until the `}` closing their scope.

---

## Passing Mutable References to Functions

Functions that need to modify data should take `&mut T` parameters:

```rust
fn append_exclamation(s: &mut String) {
    s.push_str("!");
    //  ↑ modifies the caller's String directly
}

fn main() {
    let mut greeting = String::from("Hello");
    append_exclamation(&mut greeting); // pass mutable borrow
    println!("{greeting}");            // "Hello!"
    // greeting is still owned by main — not moved
}
```

```
main's stack                  Heap
───────────────────           ──────────────────────
┌──────────────────┐          ┌────────────────────┐
│ greeting (owner) │──────── ▶│ "Hello"            │
└──────────────────┘          └────────────────────┘
         │
         │  &mut greeting passed to function
         ▼
───────────────────────────────────────
append_exclamation's stack
┌──────────────────┐
│ s (&mut String)  │──────── ▶ same heap memory
└──────────────────┘
         │
         │  s.push_str("!") writes to heap
         ▼
         Heap: "Hello!"
───────────────────────────────────────
Function returns. s (the reference) is dropped.
greeting still owns the now-modified heap data.
```

---

## Mutable References and Struct Methods

The `&mut self` receiver lets a method mutate its struct without taking ownership:

```rust
struct Counter {
    value: u32,
}

impl Counter {
    fn increment(&mut self) {   // &mut self = mutable borrow of Counter
        self.value += 1;
    }

    fn get(&self) -> u32 {      // &self = immutable borrow of Counter
        self.value
    }
}

fn main() {
    let mut c = Counter { value: 0 };
    c.increment();   // Rust auto-borrows: (&mut c).increment()
    c.increment();
    println!("{}", c.get()); // 2
}
```

---

## Reborrowing

A mutable reference can be **reborrowed** into a shorter-lived mutable reference. The original is temporarily "paused" while the reborrow is active.

```rust
let mut data = vec![1, 2, 3];
let r = &mut data;

let r2 = &mut *r;  // reborrow: r is suspended while r2 is alive
r2.push(4);        // only r2 is active here
// r2 ends here

r.push(5);         // r is active again
println!("{:?}", r); // [1, 2, 3, 4, 5]
```

```
Timeline:

data: ══════════════════════════════════════════
r:    ──────[paused]──────────────────────────── (mutable borrow)
r2:           ──────────────────┤               (reborrow from r)
              ↑                 ↑
            r2 starts        r2 ends, r resumes
```

This is how functions like `Vec::iter_mut()` work internally.

---

## Common Errors and How to Fix Them

### Error 1: Two simultaneous mutable borrows

```rust
let mut s = String::from("hello");

let r1 = &mut s;
let r2 = &mut s;  // ERROR: cannot borrow `s` as mutable more than once

println!("{r1}, {r2}");
```

**Fix:** Use each borrow in its own non-overlapping scope:

```rust
let mut s = String::from("hello");

{
    let r1 = &mut s;
    r1.push_str(" world");
}  // r1 dropped here

let r2 = &mut s;  // OK: r1 is gone
r2.push_str("!");
```

---

### Error 2: Mutable borrow while immutable borrow is active

```rust
let mut s = String::from("hello");

let r1 = &s;
let r2 = &mut s;   // ERROR: cannot borrow `s` as mutable
                   //        because it is also borrowed as immutable

println!("{r1}");
```

**Fix:** Ensure the immutable borrow ends before the mutable one starts:

```rust
let mut s = String::from("hello");

let r1 = &s;
println!("{r1}");  // r1's last use → borrow ends here

let r2 = &mut s;   // OK
r2.push_str(" world");
```

---

### Error 3: Mutating collection while iterating

```rust
let mut v = vec![1, 2, 3];

for x in &v {
    v.push(*x * 2);  // ERROR: cannot borrow `v` as mutable
                     //        because it is also borrowed as immutable
}
```

**Fix:** Collect modifications separately:

```rust
let mut v = vec![1, 2, 3];
let additions: Vec<i32> = v.iter().map(|x| x * 2).collect();
v.extend(additions);
println!("{:?}", v); // [1, 2, 3, 2, 4, 6]
```

---

## Mutable Borrowing vs Move vs Clone

```
┌─────────────────┬────────────────────────┬──────────────────────────────┐
│ Operation       │ Ownership              │ Use when                     │
├─────────────────┼────────────────────────┼──────────────────────────────┤
│ Move            │ Transferred to callee  │ Callee takes full control    │
│ Immutable borrow│ Stays with owner       │ Callee only needs to read    │
│ Mutable borrow  │ Stays with owner       │ Callee needs to modify       │
│ Clone           │ New copy, new owner    │ Callee needs its own version │
└─────────────────┴────────────────────────┴──────────────────────────────┘
```

---

## Interior Mutability (Advanced)

Sometimes you need to mutate data through a `&T` (shared reference). Rust provides **interior mutability** types for this controlled scenario:

| Type | Single-threaded | Multi-threaded | Notes |
|------|----------------|----------------|-------|
| `Cell<T>` | ✓ | ✗ | Copy types only |
| `RefCell<T>` | ✓ | ✗ | Panics at runtime on violations |
| `Mutex<T>` | ✓ | ✓ | Blocks on contention |
| `RwLock<T>` | ✓ | ✓ | Multiple readers or one writer |

```rust
use std::cell::RefCell;

let data = RefCell::new(vec![1, 2, 3]);

// borrow_mut() returns a mutable guard through a shared reference
data.borrow_mut().push(4);

println!("{:?}", data.borrow()); // [1, 2, 3, 4]
```

`RefCell` moves the borrow check from **compile time** to **runtime**, panicking if the rules are violated. Use only when the compiler's static analysis is too conservative for your design.

---

## Summary

| Aspect | Detail |
|--------|--------|
| **Syntax** | `&mut T` for the reference type; `&mut value` to create one |
| **Requirement** | The variable being borrowed must be declared `mut` |
| **Exclusivity** | At most one `&mut T` alive at any point; no `&T` can coexist |
| **Scope** | Ends at last use (NLL), not at closing brace |
| **Purpose** | Allow mutation without transferring ownership |
| **Safety** | Eliminates data races at compile time |

---

## Related

- [[borrow]] — Borrowing concept and immutable references
- [[Reference]] — References in depth
- [[Non-lexical-lifetime]] — How borrow scopes are computed
- [[Move]] — Ownership transfer as an alternative to borrowing
