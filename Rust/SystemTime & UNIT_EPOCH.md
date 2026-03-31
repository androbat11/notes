# SystemTime & UNIX_EPOCH in Rust

## What is Unix Time?

Before diving into Rust, it helps to understand the foundation: **Unix time** (also called **epoch time** or **POSIX time**).

Unix time is a system for representing a point in time as a single number: **the number of seconds that have elapsed since the Unix Epoch**.

The **Unix Epoch** is a fixed reference point in time:

> **January 1, 1970, 00:00:00 UTC**

This date was chosen somewhat arbitrarily by the designers of Unix in the early 1970s as a convenient "time zero". Every moment in time can then be expressed as an offset from this anchor — positive for times after it, negative for times before it.

For example:
- `0` → Jan 1, 1970, 00:00:00 UTC
- `1_000_000_000` → Sep 9, 2001, 01:46:40 UTC
- `1_711_843_200` → roughly March 31, 2024

Unix time is universally used across operating systems, databases, log systems, and network protocols because it is:
- **Timezone-independent** (always UTC)
- **Easy to compare** (just compare two integers)
- **Easy to do arithmetic on** (add/subtract seconds directly)

---

## SystemTime in Rust

Rust's standard library exposes time through `std::time::SystemTime`. This is a **wall-clock time** — it reflects the current time as reported by the operating system, the same clock a human would read.

```rust
use std::time::SystemTime;
```

`SystemTime` is an **opaque struct**. You cannot directly inspect its internal value as a number. Instead, Rust gives you methods to work with it relative to known reference points.

### Key properties:
- It wraps the OS system clock (`clock_gettime(CLOCK_REALTIME)` on Linux/macOS)
- It can move **backwards** (e.g., if the system clock is adjusted by NTP)
- It is **not monotonic** — don't use it for measuring elapsed time in benchmarks or timeouts. Use `std::time::Instant` for that instead.

---

## UNIX_EPOCH in Rust

Rust defines the Unix Epoch as a constant of type `SystemTime`:

```rust
use std::time::UNIX_EPOCH;
```

`UNIX_EPOCH` represents exactly **January 1, 1970, 00:00:00 UTC** as a `SystemTime` value. It is the anchor point that lets you convert a `SystemTime` into a meaningful number (seconds, milliseconds, etc.).

---

## Getting the Current Time

```rust
use std::time::SystemTime;

fn main() {
    let now = SystemTime::now();
    println!("{:?}", now); // SystemTime { tv_sec: ..., tv_nsec: ... }
}
```

`SystemTime::now()` returns the current system time. By itself, the value is opaque — to turn it into a number you need to measure it against a reference point.

---

## Converting to Unix Timestamp

The central operation is `duration_since()`. It returns the `Duration` between two `SystemTime` values:

```rust
use std::time::{SystemTime, UNIX_EPOCH};

fn main() {
    let now = SystemTime::now();
    let duration = now.duration_since(UNIX_EPOCH).expect("Time went before epoch");

    println!("Seconds since epoch: {}", duration.as_secs());
    println!("Milliseconds:        {}", duration.as_millis());
    println!("Microseconds:        {}", duration.as_micros());
    println!("Nanoseconds:         {}", duration.as_nanos());
}
```

`duration_since()` returns `Result<Duration, SystemTimeError>` because the operation can fail if `now` is somehow **before** `UNIX_EPOCH` (which can happen on misconfigured systems or when working with historical timestamps).

---

## Duration

`std::time::Duration` represents a span of time. It stores seconds and nanoseconds internally.

```rust
use std::time::Duration;

let d = Duration::from_secs(90);
println!("{}", d.as_secs());   // 90
println!("{}", d.as_millis()); // 90000
println!("{}", d.as_nanos());  // 90000000000

// You can also construct with sub-second precision:
let precise = Duration::from_millis(1500); // 1.5 seconds
let also    = Duration::from_nanos(500_000_000); // 0.5 seconds
```

---

## Practical Examples

### Example 1 — Unix timestamp as u64

```rust
use std::time::{SystemTime, UNIX_EPOCH};

fn unix_timestamp() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("Clock went backwards")
        .as_secs()
}

fn main() {
    println!("Now: {}", unix_timestamp());
}
```

### Example 2 — Millisecond timestamp (common in APIs and logging)

```rust
use std::time::{SystemTime, UNIX_EPOCH};

fn timestamp_ms() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("Clock went backwards")
        .as_millis()
}

fn main() {
    println!("Now (ms): {}", timestamp_ms());
}
```

> Note: `as_millis()` returns `u128` because milliseconds since 1970 exceed the range of `u64` in the far future.

### Example 3 — Measuring elapsed time (the wrong and right way)

**Wrong** — `SystemTime` can go backwards:

```rust
use std::time::SystemTime;

let start = SystemTime::now();
// ... do work ...
let elapsed = SystemTime::now().duration_since(start); // may error!
```

**Right** — use `Instant` for elapsed time:

```rust
use std::time::Instant;

let start = Instant::now();
// ... do work ...
println!("Elapsed: {:?}", start.elapsed());
```

Use `SystemTime` when you need a **calendar timestamp** (e.g., logging, file metadata, API payloads). Use `Instant` when you need to **measure duration**.

### Example 4 — Converting a Unix timestamp back to SystemTime

```rust
use std::time::{Duration, UNIX_EPOCH};

fn from_unix(secs: u64) -> std::time::SystemTime {
    UNIX_EPOCH + Duration::from_secs(secs)
}

fn main() {
    let t = from_unix(1_000_000_000);
    println!("{:?}", t); // SystemTime for Sep 9, 2001
}
```

### Example 5 — Time arithmetic: expiry / deadline

```rust
use std::time::{SystemTime, Duration};

fn main() {
    let issued_at = SystemTime::now();
    let expiry = issued_at + Duration::from_secs(3600); // 1 hour from now

    match expiry.duration_since(SystemTime::now()) {
        Ok(remaining) => println!("Token expires in {} seconds", remaining.as_secs()),
        Err(_) => println!("Token has already expired"),
    }
}
```

### Example 6 — Formatting as a human-readable date

The standard library does not provide date formatting. For that, use the `chrono` or `time` crates:

```toml
# Cargo.toml
[dependencies]
chrono = "0.4"
```

```rust
use chrono::{DateTime, Utc};
use std::time::SystemTime;

fn main() {
    let now = SystemTime::now();
    let datetime: DateTime<Utc> = now.into();
    println!("{}", datetime.format("%Y-%m-%d %H:%M:%S UTC"));
    // e.g., "2024-03-31 14:22:05 UTC"
}
```

---

## SystemTime vs Instant — Summary

| | `SystemTime` | `Instant` |
|---|---|---|
| Represents | Wall-clock calendar time | Monotonic point in time |
| Can go backwards? | Yes (NTP, manual adjustment) | No, guaranteed monotonic |
| Use for | Timestamps, logging, expiry | Measuring elapsed time |
| Anchor | `UNIX_EPOCH` | No fixed anchor |
| Human-readable? | Yes (via chrono/time) | No |

---

## How It Works Under the Hood

On Linux and macOS, `SystemTime::now()` calls:

```c
clock_gettime(CLOCK_REALTIME, &ts)
```

`CLOCK_REALTIME` is the system-wide clock that tracks wall time. It is adjustable — the kernel or NTP daemon can change it at any time.

`UNIX_EPOCH` is simply a `SystemTime` constructed with `tv_sec = 0, tv_nsec = 0` — the zero point of that same clock.

When you call `duration_since(UNIX_EPOCH)`, Rust computes:

```
duration = now.tv_sec - epoch.tv_sec  →  seconds since Jan 1, 1970
```

---

## Common Pitfalls

1. **Using `unwrap()` carelessly** — `duration_since()` returns `Result`. On some embedded or virtualized systems, the clock may not be initialized and could return a time before epoch. Use `.expect("...")` with a meaningful message or handle the error.

2. **Storing as `i64` vs `u64`** — Many external systems (databases, JavaScript) store Unix timestamps as signed `i64` to support pre-1970 dates. Rust's `as_secs()` returns `u64`. Cast explicitly when interfacing with these systems.

3. **Milliseconds overflow `u64`** — Use `u128` for millisecond and nanosecond precision timestamps, or accept the truncation knowingly.

4. **`SystemTime` is not `Send` on all platforms** — In practice it is, but be aware when crossing thread boundaries with time values captured before spawning threads.

---

## Quick Reference

```rust
use std::time::{SystemTime, UNIX_EPOCH, Duration, Instant};

// Current time
let now = SystemTime::now();

// Seconds since epoch
let secs: u64 = now.duration_since(UNIX_EPOCH).unwrap().as_secs();

// Milliseconds since epoch
let ms: u128 = now.duration_since(UNIX_EPOCH).unwrap().as_millis();

// Build SystemTime from known timestamp
let t = UNIX_EPOCH + Duration::from_secs(1_700_000_000);

// Add time
let later = now + Duration::from_secs(60);

// Subtract time
let earlier = now - Duration::from_secs(60);

// Compare two SystemTimes
if now > earlier { println!("now is after earlier"); }

// Measure elapsed (use Instant!)
let start = Instant::now();
let elapsed: Duration = start.elapsed();
```
