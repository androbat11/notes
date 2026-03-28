# Structs in Memory

## The core idea

A struct is a **named, contiguous block of memory** — a blueprint the compiler uses to carve out space on the stack (or heap) and give each field a fixed offset from the block's start.

Think of it like a parking lot: the lot has a fixed address, each parking space has a numbered offset, and the size of each space depends on what fits in it.

---

## Layer 1 — What the compiler sees

```rust
struct Point {
    x: f32,   // 4 bytes
    y: f32,   // 4 bytes
    label: u8 // 1 byte
}
```

Naively you'd expect 9 bytes. What you usually get is **12**.

---

## Layer 2 — Alignment and padding

Every type has an **alignment requirement** — it must start at an address divisible by that number.

| Type  | Size | Alignment |
|-------|------|-----------|
| u8    | 1    | 1         |
| u16   | 2    | 2         |
| u32   | 4    | 4         |
| f32   | 4    | 4         |
| f64   | 8    | 8         |
| usize | 8    | 8 (64-bit)|

The struct itself inherits the **largest alignment of its fields**.

```
Point { x: f32, y: f32, label: u8 }

Offset 0:  [x    x    x    x   ]   ← f32, alignment 4 ✓
Offset 4:  [y    y    y    y   ]   ← f32, alignment 4 ✓
Offset 8:  [label              ]   ← u8,  alignment 1 ✓
Offset 9:  [pad  pad  pad     ]   ← 3 bytes padding to reach alignment 4
Total: 12 bytes
```

**Why?** The CPU reads memory in word-size chunks. A misaligned read would either fault or require two reads stitched together — slow and fragile.

---

## Layer 3 — Field ordering and reordering

```rust
// You write this:
struct Bad {
    a: u8,   // 1 byte
    b: u64,  // 8 bytes — forces 7 bytes padding after `a`
    c: u8,   // 1 byte — forces 7 bytes padding at end
}
// Total: 24 bytes

// Reordered:
struct Good {
    b: u64,  // 8 bytes
    a: u8,   // 1 byte
    c: u8,   // 1 byte — 6 bytes padding at end
}
// Total: 16 bytes
```

**Rust does NOT reorder fields by default** (unlike C with `__attribute__((packed))`). The compiler respects declaration order. Use `#[repr(C)]` to guarantee C-compatible layout, or let the default repr have freedom to reorder for optimization.

To force no padding: `#[repr(packed)]` — but this breaks safe reference rules (you can't take `&bad.b` safely).

---

## Layer 4 — Stack vs. heap

```
Stack frame                       Heap
┌──────────────────┐              ┌───────────────────────┐
│  Point { x, y }  │  ← direct   │  Vec<u8> backing array│
│  (12 bytes here) │              │  (grows independently)│
└──────────────────┘              └───────────────────────┘

             ┌──────────────────────────────┐
             │  Box<Point>                  │
             │  stack: ptr (8 bytes)  ───►  │ heap: Point (12 bytes)
             └──────────────────────────────┘
```

- Value types (`Point`, `u32`, arrays) live on the stack unless wrapped in `Box`, `Rc`, `Arc`, or `Vec`.
- The stack pointer moves by `size_of::<T>()` rounded to alignment.

---

## Associated Functions and Methods

### The mental model

An `impl` block is **not stored in the struct**. It is a compile-time namespace of functions that the compiler knows are associated with the type. No function pointer is stored in the struct's memory layout.

```
Memory layout of Point { x: f32, y: f32 }
┌───────┬───────┐
│   x   │   y   │   ← 8 bytes total, no room for methods
└───────┴───────┘

impl Point { ... }  ← lives in the binary's code section, NOT here
```

### Two kinds of items in `impl`

**Associated functions** — no `self`, called with `Type::name()`

```rust
impl Point {
    fn origin() -> Point {         // ← associated function (constructor pattern)
        Point { x: 0.0, y: 0.0 }
    }
}

let p = Point::origin();
```

**Methods** — take `self`, `&self`, or `&mut self` as first parameter

```rust
impl Point {
    fn distance(&self, other: &Point) -> f32 {   // &self = borrow
        ((self.x - other.x).powi(2) + (self.y - other.y).powi(2)).sqrt()
    }

    fn translate(&mut self, dx: f32, dy: f32) {  // &mut self = mutable borrow
        self.x += dx;
        self.y += dy;
    }

    fn into_tuple(self) -> (f32, f32) {           // self = consume/move
        (self.x, self.y)
    }
}
```

`p.distance(&q)` is syntactic sugar for `Point::distance(&p, &q)` — the compiler rewrites it.

---

## Traits

### The mental model

A trait is a **contract**: "any type that implements this trait promises to provide these methods."

The interesting question is **how the compiler calls those methods** — and there are two fundamentally different answers.

---

### Static dispatch — monomorphization

```rust
fn print_area<T: Shape>(s: T) { ... }
```

At compile time, the compiler **stamps out a separate copy** of `print_area` for every concrete type used. No runtime overhead, no indirection.

```
print_area::<Circle>  ← compiled separately
print_area::<Square>  ← compiled separately
```

**Trade-off**: larger binary, faster execution.

---

### Dynamic dispatch — trait objects and vtables

```rust
fn print_area(s: &dyn Shape) { ... }
```

Now `s` is a **fat pointer**: two words wide.

```
&dyn Shape (16 bytes on 64-bit)
┌─────────────────┬──────────────────┐
│  data ptr       │  vtable ptr      │
│  → actual value │  → fn pointers   │
└─────────────────┴──────────────────┘
```

The vtable is a static table in the binary, one per (type, trait) combination:

```
Circle's Shape vtable
┌──────────────────────────────────────┐
│  drop fn ptr    → Circle::drop       │
│  size           → 8                  │
│  align          → 4                  │
│  area fn ptr    → Circle::area       │
│  perimeter ptr  → Circle::perimeter  │
└──────────────────────────────────────┘
```

Calling `s.area()` becomes: dereference vtable ptr → read function pointer at offset → call it. One extra indirection per call.

**Trade-off**: smaller binary (one function body), runtime cost of pointer indirection, and **you can mix types in a collection**:

```rust
let shapes: Vec<Box<dyn Shape>> = vec![
    Box::new(Circle { r: 1.0 }),
    Box::new(Square { side: 2.0 }),
];
```

---

### Object safety

Not every trait can become a trait object. A trait is **object-safe** if:
- No method returns `Self`
- No method has generic type parameters

Reason: the vtable has fixed-size slots. If a method returned `Self`, the compiler wouldn't know the size at the call site.

---

## Summary — cause → effect chain

```
Struct declaration
    → compiler calculates field offsets (alignment rules)
    → pads to satisfy largest-field alignment
    → total size = sum of fields + padding

impl block
    → functions compiled into binary code section
    → zero overhead in the struct's memory layout
    → &self / &mut self / self control borrow semantics

Trait + static dispatch (generics)
    → monomorphization at compile time
    → no runtime indirection, binary grows

Trait + dynamic dispatch (dyn Trait)
    → fat pointer (data + vtable)
    → vtable per (concrete type, trait) pair
    → one pointer dereference per method call
    → enables heterogeneous collections
```
