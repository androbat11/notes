## String | ownership explained

## The String Type

For example, what if we want to take user input and store it? It is for these situations that Rust has the `String` type.

* This type manages data allocated on the heap and as such is able to store an amount of text that is unknown to us at compile time. You can create a `String` from a string literal using the `from` function, like so:

```rust
let s = String::from("hello");
```

```rust
let mut s = String::from("hello");

s.push_str(", world!"); // push_str() appends a literal to a String

println!("{s}"); // this will print `hello, world!`
```

## Memory Allocation

With the `String` type, in order to support a mutable, growable piece of text, we need to allocate an amount of memory on the heap, unknown at compile time, to hold the contents. This means:

- The memory must be ==requested from the memory allocator== at runtime.
- We need a way of returning this memory to the allocator when we're done with our `String`.

However, the second part is different. In languages with a _garbage collector (GC)_, the GC keeps track of and cleans up memory that isn't being used anymore, and we don't need to think about it. In most languages without a GC, it's our responsibility to identify when memory is no longer being used and to call code to explicitly free it, just as we did to request it. Doing this correctly has historically been a difficult programming problem.
* If we forget, we'll waste memory. If we do it too early, we'll have an invalid variable. If we do it twice, that's a bug too. We need to pair exactly one `allocate` with exactly one `free`.*
* ==Rust takes a different path: The memory is automatically returned once the variable that owns it goes out of scope==.

### The drop Function

* There is a natural point at which we can return the memory our `String` needs to the allocator: when `s` goes out of scope. When a variable goes out of scope, Rust calls a special function for us. This function is called [`drop`](https://doc.rust-lang.org/std/ops/trait.Drop.html#tymethod.drop), and it's where the author of `String` can put the code to return the memory. Rust calls `drop` automatically at the closing curly bracket.

## String Internal Structure

* Pointer to the **memory that holds the contents of the string**, a **length** and a **capacity**.
* This group of data is stored on the stack. On the right is the memory on the heap that holds the contents.*
![[Pasted image 20260129085510.png]]
* The ==length== is how much memory, ==in bytes==, the contents of the `String` are currently using.*
* The capacity is the total amount of memory, in bytes, that the `String` has received from the allocator.

## Move Semantics

```rust
let s1 = String::from("hello");
let s2 = s1;
```

* ==*When we assign `s1` to `s2`, the `String` data is copied, meaning we copy the pointer, the length, and the capacity that are on the stack. We do not copy the data on the heap that the pointer refers to. In other words, the data representation in memory looks like Figure 4-2.*==
* ![[Pasted image 20260129085939.png]]

### The Double Free Problem

* Earlier, we said that when a variable goes out of scope, Rust automatically calls the `drop` function and cleans up the heap memory for that variable. But Figure 4-2 shows both data pointers pointing to the same location. This is a problem: ==When `s2` and `s1` go out of scope==, they will both try to free the same memory. This is known as a _double free_ error and is one of the memory safety bugs we mentioned previously.
* Freeing memory twice can lead to memory corruption, which can potentially lead to security vulnerabilities. To ensure memory safety, after the line `let s2 = s1;`, Rust considers `s1` as no longer valid. Therefore, ==Rust doesn't need to free anything when `s1` goes out of scope==. Check out what happens when you try to use `s1` after `s2` is created; it won't work:

```rust
let s1 = String::from("hello");
let s2 = s1;

println!("{s1}, world!");
```

```
$ cargo run
   Compiling ownership v0.1.0 (file:///projects/ownership)
error[E0382]: borrow of moved value: `s1`
 --> src/main.rs:5:16
  |
2 |     let s1 = String::from("hello");
  |         -- move occurs because `s1` has type `String`, which does not implement the `Copy` trait
3 |     let s2 = s1;
  |              -- value moved here
4 |
5 |     println!("{s1}, world!");
  |                ^^ value borrowed here after move
  |
  = note: this error originates in the macro `$crate::format_args_nl` which comes from the expansion of the macro `println` (in Nightly builds, run with -Z macro-backtrace for more info)
help: consider cloning the value if the performance cost is acceptable
  |
3 |     let s2 = s1.clone();
  |                ++++++++

For more information about this error, try `rustc --explain E0382`.
error: could not compile `ownership` (bin "ownership") due to 1 previous error
```

## Reassignment

```rust
let mut s = String::from("hello");
s = String::from("ahoy");

println!("{s}, world!");
```

We initially declare a variable `s` and bind it to a `String` with the value `"hello"`. Then, we immediately create a new `String` with the value `"ahoy"` and assign it to `s`. At this point, nothing is referring to the original value on the heap at all.

![[Pasted image 20260130090920.png]]

### What happens in memory during reassignment

1. `String::from("hello")` allocates heap memory, `s` points to it
2. `String::from("ahoy")` allocates **new** heap memory
3. ==Rust calls `drop()` on the old String ("hello")== — the heap memory is freed
4. `s` now points to the new allocation containing "ahoy"

### Reassignment vs Move — Key Distinction

| Scenario | What happens to old value |
|----------|---------------------------|
| `let s2 = s1;` | Ownership **moves** — old binding invalidated, `drop()` is **not** called |
| `s = new_value;` | Old value is **dropped** — `drop()` is called, memory freed immediately |

In a move (`let s2 = s1`), ownership transfers to `s2`, so the data still exists — it just has a new owner. No cleanup is needed for `s1`.

In reassignment (`s = new_value`), the old value has nowhere to "move to" — it's being replaced, not transferred. Rust must clean it up immediately by calling `drop()`.

### Why this matters

This automatic cleanup on reassignment prevents memory leaks. In C, you'd need to manually call `free()` on the old allocation before reassigning, or you'd leak memory. Rust handles this automatically through its ownership system.

## Clone

If we _do_ want to deeply copy the heap data of the `String`, not just the stack data, we can use a common method called `clone`.

```rust
let s1 = String::from("hello");
let s2 = s1.clone();

println!("s1 = {s1}, s2 = {s2}");
```

* This works just fine and explicitly produces the behavior shown in Figure 4-3, where the heap data _does_ get copied.*

## Stack-Only Data and Copy

```rust
let x = 5;
let y = x;

println!("x = {x}, y = {y}");
```

==The reason is that types such as integers that have a known size at compile time are stored entirely on the stack==, so copies of the actual values are quick to make. That means there's no reason we would want to prevent `x` from being valid after we create the variable `y`. In other words, there's no difference between ==deep== and ==shallow copying== here, so calling `clone` wouldn't do anything different from the usual shallow copying, and we can leave it out.

## @important | Pay attention
Rust has a special annotation called the `Copy` trait that we can place on types that are stored on the stack, as integers are (we’ll talk more about traits in [Chapter 10](https://doc.rust-lang.org/book/ch10-02-traits.html)). If a type implements the `Copy` trait, variables that use it do not move, but rather are trivially copied, making them still valid after assignment to another variable.

So, what types implement the `Copy` trait? You can check the documentation for the given type to be sure, but as a general rule, any group of simple scalar values can implement `Copy`, and nothing that requires allocation or is some form of resource can implement `Copy`. Here are some of the types that implement `Copy`:

- All the integer types, such as `u32`.
- The Boolean type, `bool`, with values `true` and `false`.
- All the floating-point types, such as `f64`.
- The character type, `char`.
- Tuples, if they only contain types that also implement `Copy`. For example, `(i32, i32)` implements `Copy`, but `(i32, String)` does not.