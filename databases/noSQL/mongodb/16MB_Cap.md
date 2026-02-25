# MongoDB 16MB Document Cap

## What is it?

Every document in MongoDB is stored as **BSON** (Binary JSON). A hard architectural limit exists:

```
┌─────────────────────────────────────────┐
│  Max document size = 16 MB             │
│                                         │
│  This applies to ONE document —        │
│  not a collection, not a database.     │
└─────────────────────────────────────────┘
```

This limit is enforced by the MongoDB server on every write. Exceeding it throws an error — there is no overflow, no truncation.

---

## Where Does 16MB Come From?

BSON encodes its own size as a 32-bit signed integer at the start of every document:

```
BSON document on disk:
┌──────────────┬──────────────────────────────────────┐
│  4 bytes     │  rest of document...                 │
│  total size  │  fields, values, nested docs         │
│  (int32)     │                                      │
└──────────────┴──────────────────────────────────────┘

Max value of int32 = 2,147,483,647 bytes (~2 GB)

MongoDB artificially caps it at 16 MB as a design guardrail.
```

The 2GB theoretical max was intentionally restricted. A 2GB document would be catastrophic for RAM, cursor traversal, and network transfer. 16MB is the practical upper bound MongoDB's designers chose to prevent accidental abuse of the document model.

---

## Why It Exists as a Design Guardrail

MongoDB's document model encourages **embedding** related data inside a single document (arrays, nested objects). Without a cap, it's easy to keep growing a document unboundedly:

```
Bad pattern — unbounded array growth:

{
  _id: "playlist_1",
  name: "My Playlist",
  songs: [          ← keep appending here forever?
    { songId, title, ... },
    { songId, title, ... },
    ...             ← 10,000 songs later → document bloat
  ]
}
```

The 16MB cap forces you to think about when **embedding** stops being the right answer and **referencing** (storing IDs and linking across documents) becomes necessary.

---

## Embedding vs Referencing: The Cap as a Design Signal

```
EMBEDDING (store data inside the document)
  ✓ Great for: small, bounded, tightly related data
  ✓ Example: a blog post with 5 comments
  ✗ Bad for: unbounded arrays (keep appending over time)

REFERENCING (store IDs, join at query time)
  ✓ Great for: large or growing relationships
  ✓ Example: a playlist with thousands of songs
  ✗ Trade-off: requires extra queries to resolve references
```

The 16MB cap is MongoDB's way of saying: **if embedding is making your document huge, you probably need references**.

---

## What Counts Toward the 16MB?

Everything inside the document:

```
{
  _id: ObjectId(...),        ← counts (12 bytes)
  title: "...",              ← counts
  nested: { ... },           ← counts (recursively)
  array: [ ... ],            ← counts (all elements)
  longString: "aaa...aaa"    ← counts (every character)
}

BSON field names also count — "description" is 11 bytes per occurrence.
```

In practice, the risk isn't a single large string. It's **arrays that grow over time** without a ceiling.

---

## GridFS: For When You Actually Need > 16MB

If you need to store large binary files (images, videos, PDFs), MongoDB provides **GridFS**:

```
GridFS splits large files into chunks and stores them across two collections:

  fs.files   → metadata (filename, size, upload date...)
  fs.chunks  → the actual binary data in 255KB pieces

Your application reassembles the chunks when reading.
```

GridFS is not a workaround for a bad schema — it's specifically for binary blob storage, not for document data that grew too large.

---

## Key Takeaways

- 16MB is a per-document hard limit, enforced on every write
- It exists because BSON documents are loaded whole into memory — a huge document is a huge memory cost
- The limit is a design guardrail pushing you toward referencing when data is unbounded
- In practice, most well-designed documents are in the KB range — hitting 16MB signals a schema problem, not a need for a bigger limit
- For actual large binaries, use GridFS
