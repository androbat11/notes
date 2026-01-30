# Slice

A **slice** is a reference to a contiguous sequence of elements in a collection. It lets you reference a portion of data without taking ownership of it.

## Basic Syntax

```rust
let arr = [1, 2, 3, 4, 5];
let slice: &[i32] = &arr[1..4];  // References elements at index 1, 2, 3
```

## How Slices Work in Memory

A slice is a **fat pointer** consisting of two components:
1. **Pointer** - address to the first element of the slice
2. **Length** - number of elements in the slice

```
Stack:                    Heap/Stack (original data):
┌─────────────┐          ┌───┬───┬───┬───┬───┐
│ ptr   ──────┼────────► │ 1 │ 2 │ 3 │ 4 │ 5 │
├─────────────┤          └───┴───┴───┴───┴───┘
│ len: 3      │                ▲
└─────────────┘                │
                               slice points here (&arr[1..4])
```

## Common Slice Types

| Type | Description |
|------|-------------|
| `&[T]` | Immutable slice of type T |
| `&mut [T]` | Mutable slice of type T |
| `&str` | String slice (UTF-8 encoded) |

## String Slices

String slices (`&str`) are the most common slice type:

```rust
let s = String::from("hello world");
let hello: &str = &s[0..5];   // "hello"
let world: &str = &s[6..11];  // "world"
```

## Slice Ranges

```rust
let arr = [0, 1, 2, 3, 4];

&arr[..3]   // From start: [0, 1, 2]
&arr[2..]   // To end: [2, 3, 4]
&arr[..]    // Entire array: [0, 1, 2, 3, 4]
&arr[1..4]  // Range: [1, 2, 3]
```

## Why Use Slices?

1. **No ownership transfer** - borrow data without moving it
2. **Flexibility** - functions accepting `&[T]` work with arrays, vectors, and other slices
3. **Safety** - bounds checking at runtime prevents buffer overflows
4. **Zero-cost abstraction** - no heap allocation for the slice itself
