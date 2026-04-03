	# Arc — Atomically Reference Counted

`Arc<T>` is a **thread-safe shared ownership pointer**. It lets multiple owners hold a reference to the same heap-allocated value. When the last owner drops, the value is freed.

It lives in `std::sync::Arc`.

```rust
use std::sync::Arc;

let db = Arc::new(Database::new());

let db1 = Arc::clone(&db); // owner 1
let db2 = Arc::clone(&db); // owner 2
// both point to the same Database on the heap
```

## How It Works

Internally, `Arc<T>` stores two things on the heap:

1. **The value `T`** — your actual data
2. **An atomic reference count** — how many `Arc` handles exist

Every `Arc::clone()` increments the count. Every `drop()` decrements it. When it hits zero, the value is freed.

The count is **atomic** (using CPU atomic instructions) so it's safe to increment/decrement from multiple threads simultaneously — unlike `Rc<T>`, which is single-threaded only.

```
Arc::clone()  →  count + 1
drop(arc)     →  count - 1  →  if count == 0: free memory
```

## Diagram

```
Thread 1            Thread 2            Thread 3
   │                   │                   │
   │  Arc::clone()     │  Arc::clone()     │  Arc::clone()
   ▼                   ▼                   ▼
┌──────────┐       ┌──────────┐       ┌──────────┐
│  Arc<T>  │       │  Arc<T>  │       │  Arc<T>  │
│ (handle) │       │ (handle) │       │ (handle) │
└────┬─────┘       └────┬─────┘       └────┬─────┘
     │                  │                  │
     └──────────────────┴──────────────────┘
                        │
                        ▼
              ┌─────────────────────┐
              │      Heap           │
              │  ┌───────────────┐  │
              │  │  ref_count: 3 │  │  ← atomic usize
              │  ├───────────────┤  │
              │  │   value: T    │  │  ← your data (e.g. DB pool)
              │  └───────────────┘  │
              └─────────────────────┘

  When each thread drops its handle:
  ref_count: 3 → 2 → 1 → 0  →  memory freed
```

## Arc vs Rc

| | `Rc<T>` | `Arc<T>` |
|---|---|---|
| Thread-safe | No | Yes |
| Count ops | Regular integer | Atomic CPU ops |
| Performance | Faster | Slight overhead |
| Use case | Single-threaded | Multi-threaded |

---

## The Problem: One Connection Per Request

Without sharing, you might naively build a DB client inside each request handler:

```rust
// BAD: called on every incoming HTTP request
async fn handler() -> impl Responder {
    let db = Database::connect("postgres://...").await; // ← new TCP connection!
    let result = db.query("SELECT ...").await;
    HttpResponse::Ok().json(result)
}
```

**What happens:**

```
Request 1 ──► open TCP connection ──► query ──► close connection
Request 2 ──► open TCP connection ──► query ──► close connection
Request 3 ──► open TCP connection ──► query ──► close connection
     ...
```

Each request pays the cost of:
- TCP handshake
- TLS negotiation (if SSL)
- Database authentication
- Connection setup

Under load (100 req/s = 100 new DB connections/s). Most databases have connection limits (e.g. Postgres defaults to 100). You'll hit them fast and start getting errors.

---

## The Solution: `web::Data<T>` in Actix-web

`web::Data<T>` is just a thin wrapper around `Arc<T>`. It stores your shared state **once** at startup and hands each request handler a clone of the `Arc` — not a clone of the data.

```rust
// at startup — one connection pool, created once
let db_pool = web::Data::new(PgPool::connect("postgres://...").await?);

HttpServer::new(move || {
    App::new()
        .app_data(db_pool.clone()) // Arc::clone — cheap pointer copy
        .route("/users", web::get().to(get_users))
})
.bind("0.0.0.0:8080")?
.run()
.await
```

```rust
// handler — receives Arc clone, shares the pool
async fn get_users(db: web::Data<PgPool>) -> impl Responder {
    let rows = sqlx::query!("SELECT * FROM users")
        .fetch_all(db.get_ref()) // same pool, no new connection
        .await?;
    HttpResponse::Ok().json(rows)
}
```

**What actually happens:**

```
                    ┌──────────────────────────┐
                    │   Arc<PgPool>  (heap)    │
                    │   ref_count: N           │
                    │   pool: [conn1..conn10]  │  ← one pool, shared
                    └────────────┬─────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
          ▼                      ▼                      ▼
   Request 1              Request 2              Request 3
   Arc clone              Arc clone              Arc clone
   (cheap ptr)            (cheap ptr)            (cheap ptr)
   queries pool           queries pool           queries pool
```

The connection pool itself manages a fixed set of DB connections internally and hands them out as needed — your handlers never open new ones.

## Summary

| Approach | Connections | Safe across threads | Cost per request |
|---|---|---|---|
| `Database::new()` per request | 1 per request | N/A | High (TCP + auth) |
| Shared `Arc<Pool>` via `web::Data` | Fixed pool size | Yes (Arc) | Near zero (ptr copy) |

> `web::Data<T>` = `Arc<T>` + actix extractor sugar.  
> You get shared ownership, thread safety, and zero-copy access to your services.

---

## Socratic Questions — Think Before You Read Answers

These questions are meant to make you pause and reason. Try to answer each one before expanding the answer. The goal is to catch gaps in your mental model.

**Q1. Why can't you just use a global `static` variable to share state across threads instead of `Arc`?**
> Statics are fixed at compile time and can't hold values that are created at runtime (like a DB pool whose URL comes from env vars). `Arc` wraps any value created dynamically. Also, `static` gives you no ownership tracking — you'd need `unsafe` to mutate it. `Arc` gives you safe shared ownership with automatic cleanup.

**Q2. If `Arc::clone()` doesn't copy the data, what exactly does it copy?**
> Only the pointer (the memory address of the heap allocation). The ref count is then atomically incremented. The `T` on the heap is never touched. That's why cloning an `Arc<PgPool>` is cheap regardless of how large the pool is.

**Q3. Two threads both call `Arc::clone()` at the exact same moment. What prevents the ref count from being corrupted?**
> The "Atomic" in `Arc`. The count uses CPU-level atomic operations (`fetch_add`, `fetch_sub`) which are indivisible — no thread can observe a half-completed increment. A regular integer would have a data race here; an atomic integer cannot.

**Q4. `Arc<T>` gives shared ownership, but can threads mutate the inner value?**
> No — not directly. `Arc<T>` only gives shared *immutable* references. If you need mutation, you must combine it with an interior mutability type: `Arc<Mutex<T>>` for exclusive access, or `Arc<RwLock<T>>` for concurrent reads / exclusive writes. This is a deliberate design: `Arc` handles *who owns it*, `Mutex`/`RwLock` handles *who can change it*.

**Q5. What happens if you wrap `Arc` in `Arc` — `Arc<Arc<T>>`? Is there a reason to ever do this?**
> It compiles, but it's pointless. The outer `Arc` already gives you shared ownership of whatever is inside, including another `Arc`. You'd just be paying two ref-count operations per clone for no benefit. If you find yourself writing this, it's a sign the design needs revisiting.

**Q6. A `web::Data<T>` is cloned for every worker thread when the server starts. Does that mean the handler's `db: web::Data<PgPool>` parameter is a fresh pool on each request?**
> No. The clone is an `Arc::clone` — a pointer copy. Every worker thread and every request handler points to the same `PgPool` on the heap. `web::Data::clone()` is intentionally cheap by design.

---

## Meta-cognition — Reflect on Your Understanding

Before moving on, honestly rate yourself on each:

| Concept | I can explain it without notes | I need to re-read |
|---|---|---|
| What ref-counting is and why it enables shared ownership | | |
| Why atomicity matters specifically in a multi-threaded context | | |
| The difference between `Arc` (ownership) and `Mutex` (mutation) | | |
| Why `Arc::clone` is O(1) regardless of `T`'s size | | |
| What `web::Data` is actually doing under the hood | | |

**Patterns to notice in your thinking:**
- If you understood the diagram but couldn't explain *why* the count needs to be atomic — you learned the shape but not the reason. Go back to Q3.
- If you're fuzzy on when to add `Mutex` — you've learned `Arc` in isolation. The real usage is almost always `Arc<Mutex<T>>` or `Arc<RwLock<T>>`. Note that gap.
- If the actix section felt like magic — re-read it with the mental model: "actix is just calling `Arc::clone()` on my data before routing each request."

---

## Exercises

### Exercise 1 — Trace the ref count by hand

Given this code, what is the ref count at each marked line?

```rust
use std::sync::Arc;

fn main() {
    let a = Arc::new(42);          // (A) count = ?
    let b = Arc::clone(&a);        // (B) count = ?
    {
        let c = Arc::clone(&a);    // (C) count = ?
        println!("{}", c);
    }                              // (D) count = ?  (c dropped here)
    drop(b);                       // (E) count = ?
}                                  // (F) count = ?  (a dropped here)
```

<details>
<summary>Answer</summary>

- (A) 1
- (B) 2
- (C) 3
- (D) 2 — `c` goes out of scope, count decrements
- (E) 1 — `b` explicitly dropped
- (F) 0 — `a` dropped, value freed

</details>

---

### Exercise 2 — Spot the bug

This code tries to share a counter across two threads. What is wrong with it, and how do you fix it?

```rust
use std::sync::Arc;
use std::thread;

fn main() {
    let counter = Arc::new(0u32);

    let c1 = Arc::clone(&counter);
    let c2 = Arc::clone(&counter);

    let t1 = thread::spawn(move || { *c1 += 1; });
    let t2 = thread::spawn(move || { *c2 += 1; });

    t1.join().unwrap();
    t2.join().unwrap();

    println!("{}", counter);
}
```

<details>
<summary>Answer</summary>

`Arc<T>` only gives shared *immutable* access. You cannot do `*c1 += 1` because `Arc` dereferences to `&T`, not `&mut T`.

**Fix:** use `Arc<Mutex<u32>>`:

```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    let counter = Arc::new(Mutex::new(0u32));

    let c1 = Arc::clone(&counter);
    let c2 = Arc::clone(&counter);

    let t1 = thread::spawn(move || { *c1.lock().unwrap() += 1; });
    let t2 = thread::spawn(move || { *c2.lock().unwrap() += 1; });

    t1.join().unwrap();
    t2.join().unwrap();

    println!("{}", counter.lock().unwrap());
}
```

</details>

---

### Exercise 3 — Rc vs Arc decision

For each scenario, choose `Rc<T>` or `Arc<T>` and justify why:

1. A config struct read by multiple parts of a single-threaded CLI tool.
2. A connection pool shared across actix-web worker threads.
3. A parsed AST shared between passes of a compiler running on one thread.
4. A cache shared between a Tokio async task spawned with `tokio::spawn`.

<details>
<summary>Answer</summary>

1. `Rc<T>` — single-threaded, no overhead needed.
2. `Arc<T>` — multiple OS threads; `Rc` would not compile here (`Rc` is not `Send`).
3. `Rc<T>` — single-threaded compiler pass.
4. `Arc<T>` — `tokio::spawn` requires `Send`, and `Rc` is not `Send`. Even though it's async, tasks can move between threads.

</details>

---

### Exercise 4 — What does web::Data actually deref to?

Given:

```rust
async fn handler(config: web::Data<AppConfig>) -> impl Responder {
    let name = config.app_name.clone(); // works — why?
    HttpResponse::Ok().body(name)
}
```

Why can you access `.app_name` directly on `config` without calling `.get_ref()` first?

<details>
<summary>Answer</summary>

`web::Data<T>` implements `Deref<Target = T>`. When you write `config.app_name`, Rust's auto-deref coercion kicks in and transparently calls `config.deref().app_name`, which resolves through the `Arc` to the actual `AppConfig`. You only need `.get_ref()` when you explicitly need a `&T` reference (e.g. to pass to a function expecting `&AppConfig`).

</details>

---

### Exercise 5 — Design question

You're building a web service. You have two pieces of shared state:
- `AppConfig` — read-only, set once at startup, never changes.
- `RequestCounter` — incremented on every request.

Which type should each be? Fill in the blanks and explain your reasoning:

```rust
let config: web::Data<___________> = web::Data::new(...);
let counter: web::Data<___________> = web::Data::new(...);
```

<details>
<summary>Answer</summary>

```rust
let config: web::Data<AppConfig>            = web::Data::new(...);
let counter: web::Data<Mutex<u64>>          = web::Data::new(Mutex::new(0));
// or better:
let counter: web::Data<AtomicU64>           = web::Data::new(AtomicU64::new(0));
```

- `AppConfig` — immutable after init, so plain `Arc<AppConfig>` (via `web::Data`) is enough. No lock needed.
- `RequestCounter` — mutated concurrently by many threads. Needs either `Mutex<u64>` (simple but locks) or `AtomicU64` (lock-free, preferred for a simple counter).

Key insight: `Arc` alone is not enough when you need mutation. The type inside `Arc` must provide its own synchronization.

</details>
