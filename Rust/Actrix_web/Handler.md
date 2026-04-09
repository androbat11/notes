# Actix-web Handler Pattern

In Actix-web, a **Handler** is an asynchronous function where the **signature is the request specification**. It uses **Extractors** to pull data from the request and returns a type that implements the `Responder` trait.

## The "Magic" of Extractors (`FromRequest`)

Every parameter in a handler function (like `web::Query<T>`, `web::Path<T>`, or `web::Json<T>`) must implement the `FromRequest` trait. When a request arrives, Actix-web:
1.  **Extracts**: Pulls the data from the request (path, query, body, etc.).
2.  **Validates**: Deserializes it into your typed struct.
3.  **Fails Fast**: If the data is missing or malformed (e.g., a string where a `u32` was expected), Actix-web returns a **400 Bad Request** automatically. Your handler function is never even called.

## A "Full House" Example

This example demonstrates how to combine multiple extractors into a single "Type-Safe Contract."

```rust
use serde::Deserialize;
use actix_web::{web, HttpResponse, Responder};

#[derive(Deserialize)]
struct Pagination {
    page: u32,
    per_page: Option<u32>, // Optional query parameter
}

#[derive(Deserialize)]
struct UpdateUser {
    display_name: String,
}

// Handler for: PUT /users/{id}/profile?page=1
async fn update_profile(
    // 1. Shared state (e.g. DB Pool)
    db: web::Data<Database>,
    // 2. Path params (extracted from /users/{id}/...)
    user_id: web::Path<u32>,
    // 3. Query params (extracted from ?page=1)
    query: web::Query<Pagination>,
    // 4. JSON Body (extracted from the request body)
    body: web::Json<UpdateUser>,
) -> impl Responder {
    println!("Updating user {} on page {}", user_id, query.page);
    
    // If we reach this line, ALL data is already valid and typed!
    HttpResponse::Ok().finish()
}
```

## Core Extractor Types

| Extractor | Source | Example URL |
| :--- | :--- | :--- |
| `web::Path<T>` | URL Path | `/users/{id}` |
| `web::Query<T>` | Query String | `?page=1&sort=desc` |
| `web::Json<T>` | JSON Body | `{"name": "Alice"}` |
| `web::Data<T>` | App State | Shared DB Pool |
| `web::Form<T>` | Form Data | `name=Alice&age=30` |

## Shared State (`web::Data<T>`)

Shared state must be registered during application setup. `web::Data` is a thin wrapper around `Arc<T>`, allowing safe sharing across worker threads.

```rust
// Registration in main.rs
let data = web::Data::new(AppState { ... });

HttpServer::new(move || {
    App::new()
        .app_data(data.clone()) // Share the pointer
        .route("/", web::get().to(my_handler))
})
```

## The Return Pattern (`Responder`)

Anything that implements `Responder` can be returned. The return type defines the "Out-bound Contract."

### Common Return Types:
- `HttpResponse`: Full control over headers and status.
- `String` / `&str`: Returns `text/plain`.
- `web::Json(struct)`: Returns `application/json`.
- `Result<T, E>`: Idiomatic error handling. Returns `T` on success or an error response on failure.

### Example: Returning JSON Result
```rust
async fn get_user(db: web::Data<Pool>) -> Result<HttpResponse, Error> {
    let user = db.find_user().await?; // '?' automatically handles the error
    Ok(HttpResponse::Ok().json(user))
}
```

## Advanced Pattern: Multipart & Streams (`Payload`)

While simple extractors (JSON, Query) load the entire request into memory before calling the handler, **Multipart** and raw **Payloads** provide a **Stream-based interface**. This is essential for handling large files without crashing the server (OOM).

### The "Russian Doll" of Streams
In a Multipart request, you deal with two levels of asynchronous streams:
1.  **The Multipart Stream (`payload.next()`)**: Iterates through each form field (e.g., "title", "artist", "file").
2.  **The Field Stream (`field.next()`)**: Iterates through the actual byte chunks of a specific field as they arrive over the network.

```rust
while let Some(item) = payload.next().await {
    let mut field = item?; // Get the next field
    
    while let Some(chunk) = field.next().await {
        let data = chunk?; // Get the next packet of bytes
        // Process bytes...
    }
}
```

### Memory Safety & OOM (Out of Memory)
*   **The Trap**: Collecting bytes into a `Vec<u8>` (e.g., `file_bytes.extend_from_slice(&data)`) assumes the file will fit in RAM. If a user uploads a 4GB file, your server will crash.
*   **The Pro Pattern**: Instead of a `Vec`, open a file on disk (using `tokio::fs::File`) and **pipe** the chunks directly to the disk as they arrive. This keeps your memory usage constant (OOM-safe) regardless of file size.

---
*Note: This information was derived from patterns found in `Rust/smart_pointers/Reference counter pointer ARC.md` and real-world implementation analysis.*
