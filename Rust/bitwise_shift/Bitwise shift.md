---
title: Bitwise Shift in Rust
description: ''
author: generic-claude-agent
created: 2026-04-13T14:43:58.404818+00:00
remargin_pending: 0
remargin_pending_for: []
remargin_last_activity: null
---

# Bitwise Shift in Rust

Bitwise shift operators move the bits of an integer left or right by a given number of positions.

## Operators

| Operator | Symbol | Description |
|----------|--------|-------------|
| Left shift  | `<<` | Shifts bits toward the most significant bit (higher value) |
| Right shift | `>>` | Shifts bits toward the least significant bit (lower value) |

## How It Works

Each shift by 1 position is equivalent to multiplying (`<<`) or dividing (`>>`) by 2.

```
value << n  →  value × 2ⁿ
value >> n  →  value / 2ⁿ  (integer division)
```

### Visual example with `u8` (8 bits)

```
0b0000_0001  =   1
<< 1
0b0000_0010  =   2

<< 3
0b0000_1000  =   8

>> 2
0b0000_0010  =   2
```

## Signed vs Unsigned Behavior

| Type | Right shift (`>>`) |
|------|--------------------|
| Unsigned (`u8`, `u32`, …) | **Logical shift** — fills vacated bits with `0` |
| Signed (`i8`, `i32`, …)   | **Arithmetic shift** — fills vacated bits with the sign bit |

```rust
let a: i8 = -8_i8;   // 0b1111_1000
let b = a >> 2;       // 0b1111_1110 = -2  (sign bit propagated)

let c: u8 = 0b1111_1000;
let d = c >> 2;       // 0b0011_1110 = 62  (zero-filled)
```

## Panics and Overflow

Rust panics in debug mode (and wraps silently in release mode) if you shift by **≥ the number of bits** in the type.

```rust
let x: u8 = 1;
let y = x << 8; // panics in debug!
```

Use `checked_shl` / `checked_shr` for safe variants that return `None` on overflow:

```rust
let safe = 1_u8.checked_shl(8); // None
let ok   = 1_u8.checked_shl(3); // Some(8)
```

## Practical Uses

| Use case | Pattern |
|----------|---------|
| Multiply / divide by power of 2 | `x << n`, `x >> n` |
| Set a bit | `x \| (1 << n)` |
| Clear a bit | `x & !(1 << n)` |
| Toggle a bit | `x ^ (1 << n)` |
| Check if bit `n` is set | `(x >> n) & 1 == 1` |
| Extract low N bits (mask) | `x & ((1 << n) - 1)` |
| Pack two values into one | `(hi << 8) \| lo` |

## Examples to Play With

```rust
fn main() {
    // --- Basic shifts ---
    let x: u32 = 1;
    println!("{}", x << 0);  // 1
    println!("{}", x << 1);  // 2
    println!("{}", x << 4);  // 16
    println!("{}", x << 10); // 1024

    // --- Fast multiply / divide ---
    let n: u32 = 100;
    println!("{}", n << 3); // 800  (100 × 8)
    println!("{}", n >> 2); // 25   (100 / 4)

    // --- Bit manipulation ---
    let mut flags: u8 = 0b0000_0000;

    // Set bit 3
    flags |= 1 << 3;
    println!("{:08b}", flags); // 00001000

    // Set bit 1
    flags |= 1 << 1;
    println!("{:08b}", flags); // 00001010

    // Check bit 3
    let is_set = (flags >> 3) & 1 == 1;
    println!("Bit 3 set: {}", is_set); // true

    // Clear bit 3
    flags &= !(1 << 3);
    println!("{:08b}", flags); // 00000010

    // --- Packing two u8 values into a u16 ---
    let hi: u16 = 0xAB;
    let lo: u16 = 0xCD;
    let packed: u16 = (hi << 8) | lo;
    println!("{:#06X}", packed); // 0xABCD

    // Unpack
    let extracted_hi = (packed >> 8) as u8;
    let extracted_lo = (packed & 0xFF) as u8;
    println!("hi={:#X} lo={:#X}", extracted_hi, extracted_lo);

    // --- Signed arithmetic shift ---
    let neg: i32 = -64;
    println!("{}", neg >> 2); // -16  (sign preserved)

    // --- Safe shift ---
    let safe = 1_u32.checked_shl(31); // Some(2147483648)
    let over = 1_u32.checked_shl(32); // None
    println!("{:?} {:?}", safe, over);
}
```
