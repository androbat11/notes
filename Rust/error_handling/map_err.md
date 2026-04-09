# Error Handling: `map_err`

In Rust, `map_err` is a powerful functional method on the `Result<T, E>` type. It is used to transform the error variant of a result into a different type or format while leaving the success variant untouched.

---

## 1. What is `map_err`?
`map_err` is a **combinator**. It allows you to "map" a function over the `Err` case of a `Result`. 

**Signature:**
```rust
fn map_err<F, O>(self, op: O) -> Result<T, F>
where O: FnOnce(E) -> F
```

- If the result is `Ok(v)`, it returns `Ok(v)` (unchanged).
- If the result is `Err(e)`, it calls the closure `op(e)` and returns `Err(new_e)`.

---

## 2. What does it do? (The "Repackaging" Pattern)
It is primarily used for **Error Conversion**. In Rust, a function can only return one type of error. When you call multiple functions that return different error types (e.g., `io::Error`, `serde_json::Error`, `ParseIntError`), you must convert them into a single, unified error type to use the `?` operator.

### Basic Example:
```rust
let res: Result<i32, i32> = Err(404);
let translated = res.map_err(|e| format!("Error code: {}", e));

assert_eq!(translated, Err("Error code: 404".to_string()));
```

---

## 3. The Pattern: Idiomatic Error Chaining
The most common "Pro" pattern is using `map_err` to wrap low-level errors into high-level "Domain Errors."

```rust
#[derive(Debug)]
enum AppError {
    DatabaseError(String),
    NetworkError(String),
}

fn fetch_user() -> Result<String, AppError> {
    // .map_err converts a standard io::Error into our custom AppError
    let data = std::fs::read_to_string("user.txt")
        .map_err(|e| AppError::DatabaseError(e.to_string()))?; 
    
    Ok(data)
}
```

---

## 4. `map` vs `map_err`
- **`map`**: Changes the **Success** (`Ok`). Use it when you want to process the data.
- **`map_err`**: Changes the **Failure** (`Err`). Use it when you want to process the error.

---

## Meta-Cognition Questions
*Reflect on these to solidify your understanding:*

1.  **Contextual Awareness**: The `?` operator uses the `From` trait to convert errors automatically. In what situation would `map_err` be *better* than relying on `From`? (Hint: Think about adding specific error messages like "Failed to read config file" vs just "File not found").
2.  **Execution Logic**: If I have a chain of five `.map_err()` calls, but the first operation returns `Ok(value)`, how many of those closures actually get executed?
3.  **Architectural Design**: Why is `map_err` essential for maintaining **Abstraction Layers**? (e.g., Why shouldn't your Web Handler return a "Database Connection Refused" error directly to the user?)

---
*Note: Master `map_err` to write clean, expressive, and type-safe error handling in Rust.*
