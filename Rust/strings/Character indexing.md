
## What it is

Character indexing in Rust is **intentionally restricted**. You cannot index a `String` or `&str` with a plain integer like `s[0]` — the compiler will reject it. This is not a limitation; it is a design decision enforced by the UTF-8 encoding guarantee.

## Why direct indexing is banned

A `String` stores bytes, not characters. A single Unicode character (a `char`) can occupy 1 to 4 bytes. If Rust allowed `s[0]`, it would return a byte — which may be only half of a character. That would silently corrupt data.

```
"hello"   → [ h  e  l  l  o  ]   5 bytes, 5 chars  ✓ works intuitively
"héllo"   → [ h  é     l  l  o ] 6 bytes, 5 chars  ✗ é is 2 bytes
              ^--^
              byte 0 and 1 are one char
```

```rust
let s = String::from("héllo");
let c = s[0]; // COMPILE ERROR: String cannot be indexed by integer
```

## The three views of a string

Rust forces you to decide *what* you're indexing into:

| View              | Method           | Unit         | Use when                          |
|-------------------|------------------|--------------|-----------------------------------|
| Unicode characters | `.chars()`      | `char`       | Working with human-readable text  |
| Raw bytes          | `.bytes()`      | `u8`         | Working with ASCII or binary data |
| Byte positions     | `.char_indices()`| `(usize, char)` | Need index + character together |

## Iterating over characters

```rust
let s = String::from("héllo");

for c in s.chars() {
    println!("{c}");
}
// h, é, l, l, o  — 5 iterations
```

## Getting a character by position

There is no O(1) character-by-index. To get the nth character you iterate:

```rust
let s = String::from("héllo");

let third = s.chars().nth(2); // Some('l')
let oob   = s.chars().nth(99); // None
```

This is O(n) — Rust makes the cost visible rather than hiding it.

## Byte slicing (advanced, unsafe to misuse)

You can slice a string by **byte range**, but the range must fall on valid UTF-8 character boundaries or the program will panic at runtime.

```rust
let s = String::from("hello");
let slice = &s[1..4]; // "ell" — safe, all ASCII (1 byte each)

let s2 = String::from("héllo");
let bad = &s2[0..1]; // PANIC — slices in the middle of 'é' (2 bytes)
let good = &s2[0..2]; // "h é" — correct byte boundary for 'é'
```

Use `.char_indices()` to find safe byte boundaries dynamically:

```rust
let s = String::from("héllo");

for (i, c) in s.char_indices() {
    println!("byte {i} → '{c}'");
}
// byte 0 → 'h'
// byte 1 → 'é'
// byte 3 → 'l'
// byte 4 → 'l'
// byte 5 → 'o'
```

## Summary mental model

```
s.chars()        → treat the string as a sequence of characters (Unicode)
s.bytes()        → treat the string as a sequence of raw bytes
s.char_indices() → zip of byte position + character
&s[a..b]         → byte slice — you own the boundary correctness
```

The rule: Rust never guesses what you mean. You choose the unit explicitly.

## Related

- [[String]] — owned string type
- [[str]] — borrowed string slice
- [[String vs str]] — when to use which
