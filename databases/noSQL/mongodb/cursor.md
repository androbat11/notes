# MongoDB Cursor

## What is a Cursor?

A **cursor** is a pointer to a **query** — not to the documents themselves.

When you call `find()`, MongoDB does not load your documents into memory and hand them to you. It records *what you asked for* and *where it is in answering it*. That record is the cursor.

```
What the cursor holds:           What the cursor does NOT hold:
─────────────────────────        ──────────────────────────────
✓ The query filter               ✗ The actual documents
✓ Current position in traversal  ✗ A copy of matching data
✓ The execution plan             ✗ Any reserved memory for results
✓ Sort/projection rules
```

Documents live on **disk** and get pulled into the **WiredTiger cache** (RAM) only when the cursor advances to read them. Once read, they can be evicted from cache at any time — the cursor does not hold onto them.

> Think of it as a streaming handle, not a snapshot of data.

---

## The Big Picture

```
Client (your app)          MongoDB Server
─────────────────          ──────────────────────────────────
                           ┌──────────────────────────────┐
db.users.find({age: 25})──►│  Query Planner               │
                           │  → scans index / collection  │
                           │  → produces result set       │
                           └─────────────┬────────────────┘
                                         │
                           ┌─────────────▼────────────────┐
       cursorId ◄──────────│  Cursor (server-side)        │
                           │  - holds query context       │
                           │  - tracks position           │
                           │  - NOT the full result set   │
                           └──────────────────────────────┘
```

The server assigns a **cursorId** and keeps the query context alive. The client asks for batches using that id.

---

## Cursor Lifecycle

```
find()         getMore()      getMore()      exhausted / close()
  │                │              │                │
  ▼                ▼              ▼                ▼
[open cursor] → [batch 1] → [batch 2] → ... → [cursor closed]

Default batch size: 101 docs on first response, then ~16 MB chunks
```

1. **Open** — `find()` sends the query, server opens a cursor and returns batch 1 + cursorId.
2. **Iterate** — driver calls `getMore` with the cursorId to fetch subsequent batches.
3. **Close** — cursor closes when:
   - All results are consumed
   - Client explicitly closes it
   - Server-side timeout (default **10 minutes** of inactivity)

---

## In-Memory: Where Does Data Actually Live?

There are three distinct layers. The cursor only lives in one of them.

```
─────────────────────────────────────────────────────────────────
LAYER 1 — DISK
  ┌───────────────────────────────────────────────────────────┐
  │  collection.wt  (the actual documents, stored as B-tree) │
  │  index.wt       (indexes, also B-tree pages)             │
  └───────────────────────────────────────────────────────────┘
  Cold data lives here. Reading from disk is slow (~ms).

─────────────────────────────────────────────────────────────────
LAYER 2 — WiredTiger Cache (RAM, shared)
  ┌───────────────────────────────────────────────────────────┐
  │  Recently accessed pages loaded from disk                │
  │  Any query can read from here — it is NOT per-cursor     │
  │  Pages can be evicted at any time (LRU-style)            │
  │  Default size: 50% of RAM − 1 GB                        │
  └───────────────────────────────────────────────────────────┘
  Hot data lives here. Reading from cache is fast (~µs).

─────────────────────────────────────────────────────────────────
LAYER 3 — Query Execution Engine (RAM, per cursor)
  ┌───────────────────────────────────────────────────────────┐
  │  ← THIS IS THE CURSOR                                    │
  │                                                          │
  │  query filter:   { age: 25 }                            │
  │  position:       page 42, slot 7  ← moves as you read   │
  │  execution plan: IXSCAN → FETCH                         │
  │  sort buffer:    only if .sort() with no index           │
  └───────────────────────────────────────────────────────────┘
  Tiny. Just metadata. Does not hold documents.
─────────────────────────────────────────────────────────────────
```

### What happens when you call `.next()`

```
cursor.next()
  │
  ▼
 cursor checks its position → "I need page 42, slot 7"
  │
  ▼
 Is that page in WiredTiger cache?
  ├── YES → read doc from cache  (fast)
  └── NO  → load page from disk into cache, then read  (slow)
  │
  ▼
 return document to client
 cursor advances position → "now at page 42, slot 8"
```

The document passes through cache briefly, then is sent to you. The cursor just moved its pointer — it didn't "hold" the document.

### WiredTiger Cache
- Holds recently accessed **data pages** (documents + indexes)
- Shared across ALL queries and operations
- Default: 50% of RAM minus 1 GB
- The cursor itself does not pin documents in cache — it just knows *where to look*

### Cursor State (in-memory, per query)
Stored in the query execution engine while the cursor is open:
- The **query predicate** (the filter you passed)
- The **current position** in the collection or index
- Execution plan state
- Sort buffer (if you used `.sort()` without an index — this can spill to disk)

---

## Cursor vs. Fetching All at Once

```
find().toArray()          find() with iteration
─────────────────         ──────────────────────────
Client RAM: ALL docs       Client RAM: one batch at a time
Network: one large burst   Network: streamed in chunks
Risk: OOM on large sets    Risk: cursor timeout if idle too long
Good for: small results    Good for: large result sets
```

`toArray()` is syntactic sugar — it just exhausts the cursor and collects results into an array. Under the hood it still uses `getMore`.

---

## The `allowDiskUse` Connection

When a query requires an **in-memory sort** (no index covers the sort), MongoDB has a default **100 MB limit** for the sort buffer:

```
Query: db.logs.find().sort({ timestamp: -1 })
                  (no index on timestamp)

Without allowDiskUse:
  sort buffer > 100 MB → Error: "Executor error: Sort exceeded memory limit"

With allowDiskUse:
  sort buffer > 100 MB → spills to a temp file on disk → slower but succeeds
```

The cursor is still the mechanism through which sorted results flow to you — it's just backed by disk temporarily.

---

## Common Cursor Methods

| Method | What it does |
|---|---|
| `.next()` | Fetch the next document |
| `.hasNext()` | Check if more documents remain |
| `.toArray()` | Exhaust cursor into an array |
| `.forEach(fn)` | Iterate with a callback |
| `.limit(n)` | Cap results at n docs |
| `.skip(n)` | Skip first n docs |
| `.sort({field: 1})` | Sort results |
| `.batchSize(n)` | Override batch size |
| `.close()` | Explicitly release server cursor |

---

## NoCursorTimeout

By default cursors expire after **10 minutes** of inactivity. If you're processing documents slowly:

```js
db.collection.find().noCursorTimeout()
// Must manually close() this cursor or it leaks server resources!
```

---

## Key Takeaways

- A cursor is a **lazy pointer**, not a copy of data
- The server holds cursor state; the client holds the cursorId
- Documents live in WiredTiger cache (shared, evictable) — not "inside" the cursor
- Large in-memory sorts are bounded by the cursor's execution context, not the cache
- Always close cursors you don't exhaust — open cursors consume server memory
