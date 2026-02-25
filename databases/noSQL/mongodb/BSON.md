# BSON — Binary JSON

## What is BSON?

**BSON** is the binary format MongoDB uses to store and transfer documents.
It stands for **Binary JSON**, and it is what actually lives on disk and in memory — not the JSON you write in your queries.

```
You write (JSON-like):          MongoDB stores (BSON):
──────────────────────          ────────────────────────────────────
{                               \x16\x00\x00\x00          ← doc size
  name: "Alice",                \x02                      ← type: string
  age: 30                       name\x00                  ← field name
}                               \x06\x00\x00\x00Alice\x00 ← string value
                                \x10                      ← type: int32
                                age\x00                   ← field name
                                \x1e\x00\x00\x00          ← 30 as 4 bytes
                                \x00                      ← end of doc
```

JSON is text. BSON is binary — it encodes each value with its **type** and **length** upfront.

---

## Why Not Just Use JSON?

JSON has real problems for a database:

```
Problem                 JSON                    BSON
──────────────────────  ──────────────────────  ──────────────────────────
No type info            "30" vs 30 ambiguous    explicit int32 / int64 / double
No binary support       can't store raw bytes   has a Binary type
Slow to parse           must scan whole string  length-prefixed, skip fields fast
No dates                "2024-01-01" (string)   has a Date type (int64 ms)
Number precision        loses large integers    int32, int64, Decimal128
```

BSON trades human-readability for **machine efficiency** — faster parsing, exact types, and support for binary data.

---

## BSON Document Structure

Every BSON document follows the same envelope:

```
┌─────────────────────────────────────────────────────────────┐
│  BSON Document                                              │
│                                                             │
│  ┌──────────┐  ┌──────────────────────────────────────┐   │
│  │  4 bytes │  │  elements...                  1 byte │   │
│  │  total   │  │                               \x00   │   │
│  │  size    │  │  (all fields go here)         (end)  │   │
│  └──────────┘  └──────────────────────────────────────┘   │
│   int32 LE                                                  │
└─────────────────────────────────────────────────────────────┘
```

Each field (element) inside the document is:

```
┌──────────┬─────────────────┬───────────────────────────┐
│  1 byte  │  field name     │  value                    │
│  type    │  (cstring \x00) │  (format depends on type) │
└──────────┴─────────────────┴───────────────────────────┘
```

---

## BSON Types — The Important Ones

```
Type        Byte   How it's stored             Example
──────────  ─────  ──────────────────────────  ─────────────────
Double      \x01   8 bytes IEEE 754            3.14
String      \x02   int32 length + bytes + \x00 "hello"
Document    \x03   nested BSON doc             { a: 1 }
Array       \x04   BSON doc with "0","1" keys  [1, 2, 3]
Binary      \x05   int32 length + subtype + bytes  Buffer data
ObjectId    \x07   12 bytes (see below)        _id field
Boolean     \x08   1 byte (0x00 or 0x01)       true / false
Date        \x09   int64 milliseconds UTC      new Date()
Null        \x0A   no bytes                    null
Int32       \x10   4 bytes little-endian       30
Int64       \x12   8 bytes little-endian       large numbers
Decimal128  \x13   16 bytes                    financial precision
```

---

## ObjectId — The Default `_id`

When you don't provide an `_id`, MongoDB generates a **12-byte ObjectId**:

```
┌─────────────┬──────────────┬──────────┬────────────────┐
│  4 bytes    │  5 bytes     │  3 bytes │                │
│  Unix time  │  random      │  counter │  total: 12B    │
│  (seconds)  │  per-process │          │  = 24 hex chars│
└─────────────┴──────────────┴──────────┴────────────────┘

Example: 65f1a2b3c4d5e6f7a8b9c0d1
          ────────                 → timestamp (you can extract creation time)
                  ──────────       → random bytes (machine/process unique)
                            ────── → incrementing counter
```

ObjectId is designed to be **globally unique without coordination** — each MongoDB node generates its own IDs independently and collisions are practically impossible.

---

## JSON vs BSON — Full Comparison

```
                    JSON                    BSON
                    ──────────────────────  ──────────────────────────
Format              Text (UTF-8)            Binary
Human-readable      Yes                     No
Parseable by        Any JSON parser         MongoDB drivers only
Types               string, number,         20+ explicit types
                    boolean, null,
                    array, object
Numbers             No distinction          int32, int64, double,
                                            Decimal128
Dates               No native type          int64 (ms since epoch)
Binary data         Base64 workaround       Native Binary type
Size overhead       Smaller for simple      Larger for simple docs
                    docs (no type bytes)    (type + length per field)
Parse speed         Slow (scan text)        Fast (skip by length)
```

---

## How MongoDB Uses BSON

```
Your App                    MongoDB Driver              MongoDB Server
────────────────────────    ──────────────────────────  ──────────────────────
db.users.insertOne({   ──►  serializes to BSON     ──►  stores BSON on disk
  name: "Alice",            (adds _id if missing)
  age: 30
})

db.users.findOne({     ──►  sends BSON query       ──►  reads BSON from disk
  name: "Alice"        ◄──  deserializes BSON       ◄──  returns BSON document
})                          back to JS object
{ name: "Alice", age: 30 }
```

The conversion between your language's objects and BSON happens **inside the driver**. You never touch raw BSON directly.

---

## The BSON ↔ 16MB Cap Connection

Because BSON stores the document size as a **4-byte signed integer** at the start:

```
Max int32 value = 2,147,483,647 bytes ≈ 2 GB  (theoretical max)
                                   ↓
                  MongoDB caps it at 16,777,216 bytes = 16 MB
                  (practical guardrail — see 16MB_Cap.md)
```

The 4-byte size field is also what makes BSON fast to skip over nested documents and arrays — the parser reads the length, jumps forward by that many bytes, and doesn't need to scan character by character.

---

## Key Takeaways

- BSON is binary JSON — same document model, machine-efficient encoding
- Every field has an explicit type byte — no type ambiguity
- Documents are length-prefixed — fast to parse, skip, and size-check
- ObjectId is a 12-byte self-contained unique ID (no central coordinator needed)
- You never write BSON directly — the driver handles serialization transparently
- The 16MB limit comes from the 4-byte size field at the top of every document
