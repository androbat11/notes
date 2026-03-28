
## What It Is

When constructing a struct, you often want to create a new instance that differs from an existing one in only a few fields. Struct update syntax lets you fill in the remaining fields from another instance of the same type:

```rust
let user2 = User {
    email: String::from("new@example.com"),
    ..user1  // fill remaining fields from user1
};
```

Without it, you'd have to name every field explicitly, even the ones you're not changing. The `..other` syntax means "take all fields I haven't listed from `other`."

> The `..` here is called the **struct update operator** (or **base struct syntax**). It only appears in struct literal expressions — it is unrelated to the `..` range operator (`1..10`) or the `..` rest pattern in destructuring (`let (a, ..) = tuple`). Same symbols, completely different meanings depending on context.

---

## How It Works in Memory

The update operator copies or moves fields from the source struct **field by field**, using the exact same rules as any other assignment in Rust:

| Field type | What happens | Why |
|---|---|---|
| `i32`, `f64`, `bool`, `char`, `u8`, … | **Copied** (bitwise) | These types implement `Copy` |
| `String`, `Vec<T>`, `Box<T>`, … | **Moved** | These types own heap data and do not implement `Copy` |

Consider this struct:

```rust
struct User {
    username: String,   // heap-allocated, moves
    email: String,      // heap-allocated, moves
    age: u32,           // Copy
    active: bool,       // Copy
}
```

```
user1 (stack)
┌─────────────────────────────────────────┐
│ username → [ heap: "alice" ]            │
│ email    → [ heap: "alice@mail.com" ]   │
│ age      = 30                           │
│ active   = true                         │
└─────────────────────────────────────────┘
```

Now create `user2` overriding only `email`:

```rust
let user2 = User {
    email: String::from("new@mail.com"),
    ..user1
};
```

```
user1 (stack) — PARTIALLY MOVED
┌─────────────────────────────────────────┐
│ username → [ heap: "alice" ]  ← MOVED  │
│ email    → [ INVALID ]                  │  ← was already overridden, ignored
│ age      = 30  (copied)                 │
│ active   = true (copied)                │
└─────────────────────────────────────────┘

user2 (stack)
┌─────────────────────────────────────────┐
│ username → [ heap: "alice" ]  ← owns it │
│ email    → [ heap: "new@mail.com" ]     │
│ age      = 30                           │
│ active   = true                         │
└─────────────────────────────────────────┘
```

`user1.username` was moved into `user2`. `user1.age` and `user1.active` were copied. `user1.email` was not touched at all — you provided a new value, so Rust never looked at `user1.email`.

After this, `user1` is **partially moved**: you cannot use `user1` as a whole, but you *can* still use `user1.email` and `user1.age` and `user1.active` individually, because only `username` was moved out.

---

## Ownership Implications

This is the key insight: **Rust resolves the update field by field, not as a single atomic operation.**

### Case 1: You override all `String` fields

```rust
let user2 = User {
    username: String::from("bob"),
    email: String::from("bob@mail.com"),
    ..user1  // only copies age and active (both Copy)
};
// user1 is still fully valid — nothing was moved out
println!("{}", user1.username); // fine
```

Because you provided new values for every non-`Copy` field, the `..user1` part only pulls out `Copy` fields. Copying never invalidates the source. `user1` is untouched.

### Case 2: You override *some* `String` fields

```rust
let user2 = User {
    email: String::from("bob@mail.com"),
    ..user1  // moves user1.username, copies age and active
};
// user1.username has been moved — user1 is partially moved
// println!("{}", user1.username); // ERROR: value borrowed after move
// println!("{}", user1.email);    // OK — email was never touched
// println!("{}", user1.age);      // OK — age was copied
```

### Case 3: You override nothing

```rust
let user2 = User {
    ..user1  // moves user1.username AND user1.email
};
// user1 is now fully moved — cannot be used at all
// println!("{}", user1.email); // ERROR
```

The rule in one sentence: **if struct update syntax moves any field out of the source, the source becomes (at least partially) invalidated.**

---

## Exercises

### Exercise 1 — All `Copy` fields, source stays valid

```rust
#[derive(Debug)]
struct Point {
    x: f64,
    y: f64,
    z: f64,
}

fn main() {
    let p1 = Point { x: 1.0, y: 2.0, z: 3.0 };

    let p2 = Point {
        z: 10.0,
        ..p1
    };

    // Can we still use p1?
    println!("p1 = {:?}", p1);  // Does this compile?
    println!("p2 = {:?}", p2);
}
```

**Predict before running**: `f64` is `Copy`. The update syntax copies `x` and `y` from `p1`. No move happens. `p1` should still be fully valid.

**Expected output**:
```
p1 = Point { x: 1.0, y: 2.0, z: 3.0 }
p2 = Point { x: 1.0, y: 2.0, z: 10.0 }
```

**Why it works**: Every field in `Point` implements `Copy`, so `..p1` only ever copies — it never takes ownership of anything.

---

### Exercise 2 — `String` field present, but overridden

```rust
#[derive(Debug)]
struct Config {
    host: String,
    port: u16,
    debug: bool,
}

fn main() {
    let default_config = Config {
        host: String::from("localhost"),
        port: 8080,
        debug: false,
    };

    // Override the String field explicitly
    let prod_config = Config {
        host: String::from("prod.example.com"),
        ..default_config
    };

    // Can we still use default_config?
    println!("default host = {}", default_config.host);   // Does this compile?
    println!("prod host    = {}", prod_config.host);
}
```

**Predict before running**: `host` is a `String`, but we provided a new value for it. `..default_config` only needs to fill in `port` and `debug`, which are both `Copy`. Nothing is moved out of `default_config`.

**Expected output**:
```
default host = localhost
prod host    = prod.example.com
```

**Why it works**: Rust never touches `default_config.host` during the update. The `..default_config` clause only copies the `Copy` fields. The source struct is fully intact.

---

### Exercise 3 — `String` field not overridden

```rust
#[derive(Debug)]
struct Config {
    host: String,
    port: u16,
    debug: bool,
}

fn main() {
    let default_config = Config {
        host: String::from("localhost"),
        port: 8080,
        debug: false,
    };

    // Override only Copy fields
    let dev_config = Config {
        port: 3000,
        ..default_config   // host is a String — what happens here?
    };

    // Try to use default_config after the update:
    println!("default host = {}", default_config.host);  // Compile or error?
    println!("dev host     = {}", dev_config.host);
}
```

**Predict before running**: `host` is a `String` and we did not override it. `..default_config` must move `default_config.host` into `dev_config`. After the move, `default_config.host` is no longer valid. Accessing it should produce a compile error.

**Compiler error you'll see**:
```
error[E0382]: borrow of partially moved value: `default_config`
  --> src/main.rs:19:36
   |
14 |     let dev_config = Config {
15 |         port: 3000,
16 |         ..default_config
   |           -------------- value partially moved here
...
19 |     println!("default host = {}", default_config.host);
   |                                   ^^^^^^^^^^^^^^^^^^^ value borrowed here after partial move
```

**Fix option A** — override `host` explicitly (as in Exercise 2):
```rust
let dev_config = Config {
    host: default_config.host.clone(),  // clone to keep source valid, or
    port: 3000,
    ..default_config
};
```

**Fix option B** — accept the move and stop using `default_config` afterwards:
```rust
let dev_config = Config {
    port: 3000,
    ..default_config   // default_config.host is moved
};
// only use dev_config from here on
```

**Why it fails**: Rust's ownership model forbids two variables from owning the same heap data simultaneously. Moving `host` into `dev_config` is the correct, safe behavior — you just can't then read from the moved-out field.

---

## Quick Reference

```
let new = Type {
    field_a: new_value,   // explicit: your value, source field ignored
    ..source              // implicit: Copy fields copied, non-Copy fields moved
};
```

- If ALL non-`Copy` fields are overridden → source is untouched, fully usable
- If SOME non-`Copy` fields come from source → source is partially moved
- If ALL non-`Copy` fields come from source → source is fully moved (or partially, depending on what was `Copy`)
