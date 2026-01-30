# 🦀 Rust Practice Project List (Progressive)

## 🟢 Level 1 — Rust Basics & Confidence

### 1️⃣ Echo CLI

**Goal:** Print back what the user types.

**What you learn:**

- `std::env::args`
    
- String handling
    
- Basic IO
    
- Compilation flow
    

**Extra ideas:**

- Add `--uppercase` flag
    
- Trim whitespace
    

---

### 2️⃣ Word Counter

**Goal:** Count words in a text file.

**What you learn:**

- File reading
    
- Iterators
    
- HashMap
    
- Ownership with strings
    

**Extra ideas:**

- Sort by frequency
    
- Ignore punctuation
    

---

### 3️⃣ Number Guessing Game

**Goal:** User guesses a random number.

**What you learn:**

- Loops
    
- Pattern matching
    
- Parsing input
    
- Error handling
    

---

---

## 🟡 Level 2 — Ownership, Errors, Data Flow

### 4️⃣ Log File Analyzer

**Goal:** Read a log file and count error levels.

**What you learn:**

- Structs
    
- Enums
    
- Parsing
    
- `Result` propagation
    

---

### 5️⃣ JSON Transformer

**Goal:** Read JSON → transform → output JSON.

**What you learn:**

- serde
    
- Strong typing
    
- Error handling
    
- Data modeling
    

**Extra ideas:**

- Filter fields
    
- Validate schema
    

---

### 6️⃣ Mini Grep

**Goal:** Search text in files.

**What you learn:**

- Lifetimes (references into buffers)
    
- Iterators
    
- Performance tradeoffs
    

(This is classic Rust book project.)

---

---

## 🟠 Level 3 — Concurrency & Systems Thinking

### 7️⃣ Parallel File Scanner

**Goal:** Scan many files in parallel and count lines.

**What you learn:**

- Threads
    
- `Arc`, `Mutex`
    
- Work queues
    
- CPU vs IO
    

---

### 8️⃣ In-Memory Cache

**Goal:** Key-value store with TTL.

**What you learn:**

- HashMap ownership
    
- Time handling
    
- Background cleanup thread
    
- API design
    

---

### 9️⃣ Async HTTP Fetcher

**Goal:** Fetch many URLs concurrently.

**What you learn:**

- async/await
    
- Futures
    
- Tokio
    
- Error propagation
    

---

---

## 🔵 Level 4 — Architecture & Real Engineering

### 🔟 CLI Task Manager

**Goal:** Manage tasks stored locally.

**What you learn:**

- Domain modeling
    
- Persistence
    
- Separation of concerns
    
- Testing
    

---

### 1️⃣1️⃣ Plugin System

**Goal:** Load commands dynamically.

**What you learn:**

- Traits
    
- Dynamic dispatch
    
- Boundaries
    
- API stability
    

---

### 1️⃣2️⃣ Message Pipeline

**Goal:** Pipeline of transformations.

**What you learn:**

- Functional composition
    
- Ownership pipelines
    
- Error handling
    
- Performance
    

---