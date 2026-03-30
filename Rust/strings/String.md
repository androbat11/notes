# String

## What it is

`String` is Rust's **owned, heap-allocated, growable** UTF-8 string type. It lives in the standard library (`std::string::String`) and is the string type you reach for when you need to *own* and *mutate* string data.

## Core properties

| Property     | Value                        |
|--------------|------------------------------|
| Ownership    | Owned (it owns its bytes)    |
| Storage      | Heap                         |
| Encoding     | UTF-8 (guaranteed)           |
| Mutable      | Yes (if `mut`)               |
| Sized        | Yes — knows its length       |

## Internal structure

Under the hood, a `String` is a wrapper around `Vec<u8>` with the UTF-8 validity guarantee enforced at all insertion points.

```
String {
    ptr  → [ h | e | l | l | o ]   ← heap
    len  = 5
    cap  = 5
}
```

Three fields: a pointer to heap memory, a length, and a capacity.

## How to create one

```rust
let s = String::new();                // empty string
let s = String::from("hello");        // from a string literal
let s = "hello".to_string();          // via the ToString trait
let s = format!("{} world", "hello"); // formatted
```

## Ownership and the drop

When a `String` goes out of scope, Rust automatically frees the heap memory — no GC, no manual `free`. This is the ownership system at work.

```rust
{
    let s = String::from("hello"); // heap allocated here
} // s dropped here — memory freed
```

## Related

- [[str]] — the borrowed string slice (`&str`)
- [[String vs str]] — when to use which
