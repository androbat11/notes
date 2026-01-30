# Double Free Bug

## What is a Double Free Bug?

A **double free bug** occurs when a program attempts to free (deallocate) the same memory location more than once. This is a serious memory safety vulnerability that can cause:

- **Program crashes** (segmentation faults)
- **Memory corruption** (heap metadata gets corrupted)
- **Security exploits** (attackers can manipulate heap state to execute arbitrary code)

## How It Happens (in C/C++)

In languages without ownership systems, multiple pointers can reference the same heap memory:

```c
#include <stdlib.h>
#include <string.h>

int main() {
    char *s1 = malloc(6);
    strcpy(s1, "hello");

    char *s2 = s1;  // s2 points to the SAME memory as s1

    free(s1);       // First free - OK
    free(s2);       // Second free - BUG! Same memory freed twice

    return 0;
}
```

### Memory State Visualization

```
After malloc:
s1 ──┐
     ├──> [heap memory: "hello"]
s2 ──┘

After free(s1):
s1 ──┐
     ├──> [freed/invalid memory]
s2 ──┘

After free(s2):
     CRASH or UNDEFINED BEHAVIOR
     (attempting to free already-freed memory)
```

## Why Is It Dangerous?

1. **Heap Corruption**: The memory allocator maintains metadata about allocated blocks. Freeing twice corrupts this metadata.

2. **Use-After-Free**: The freed memory might be reallocated to another variable. The second free could deallocate memory now owned by something else.

```c
char *s1 = malloc(100);
char *s2 = s1;

free(s1);

char *s3 = malloc(100);  // Allocator might reuse the same memory
// s2 and s3 now point to the same location!

free(s2);  // This frees s3's memory!
// s3 is now a dangling pointer
```

3. **Security Exploits**: Attackers can exploit double-free to gain control of program execution through heap manipulation techniques.

## How Rust Prevents Double Free

Rust's ownership system makes double free **impossible at compile time**:

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1;  // Ownership MOVES to s2, s1 is invalidated

    // When s2 goes out of scope, memory is freed ONCE
    // s1 cannot be used, so no double free is possible
}
```

If you try to use `s1` after the move:

```rust
fn main() {
    let s1 = String::from("hello");
    let s2 = s1;

    println!("{s1}");  // Compile error!
}
```

```
error[E0382]: borrow of moved value: `s1`
 --> src/main.rs:5:16
  |
2 |     let s1 = String::from("hello");
  |         -- move occurs because `s1` has type `String`
3 |     let s2 = s1;
  |              -- value moved here
5 |     println!("{s1}");
  |                ^^ value borrowed here after move
```

## The Ownership Solution

| Problem | Rust's Solution |
|---------|-----------------|
| Multiple owners of heap data | Only ONE owner allowed via [[Move]] |
| Both try to free | Only the owner frees when it goes out of scope |
| Double free | Compile-time error prevents it entirely |

## Related Concepts

- [[Move]] - How Rust transfers ownership to prevent multiple owners
- [[Borrowing]] - How to reference data without taking ownership
- [[Drop]] - The trait that handles deallocation when a value goes out of scope
