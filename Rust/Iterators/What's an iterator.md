# What's an Iterator?

## Definition (Computer Science)

An **iterator** is an object that enables sequential traversal over a collection (or any sequence of values) **without exposing the underlying representation** of that collection.

It encapsulates two responsibilities:
1. **State** — remembering *where you are* in the sequence.
2. **Behavior** — knowing *how to advance* to the next element.

This is the **Iterator Pattern** (Gang of Four), and it separates the *traversal logic* from the *collection structure*.

---

## The Mental Model

Think of an iterator like a **cursor on a tape**:

```
Collection (the tape):
┌───┬───┬───┬───┬───┐
│ A │ B │ C │ D │ E │
└───┴───┴───┴───┴───┘
  0   1   2   3   4

Iterator (the cursor):
          ^
        pos=1
```

The iterator doesn't *own* the data — it **points into it** and knows how to move forward.

---

## How It Works in Memory

### Step-by-step traversal

```
INITIAL STATE
─────────────────────────────────────────────────────
Stack                     Heap
┌─────────────────┐       ┌───┬───┬───┬───┬───┐
│ iter            │──────▶│ A │ B │ C │ D │ E │
│  .ptr ──────────┼──┐    └───┴───┴───┴───┴───┘
│  .end ──────────┼──┼──────────────────────▲
└─────────────────┘  │                      │
                     └──▶ [A]  (current)    │
                          ptr points here   │
                          end points here ──┘


AFTER first .next()
─────────────────────────────────────────────────────
Stack                     Heap
┌─────────────────┐       ┌───┬───┬───┬───┬───┐
│ iter            │──────▶│ A │ B │ C │ D │ E │
│  .ptr ──────────┼──┐    └───┴───┴───┴───┴───┘
│  .end ──────────┼──┼──────────────────────▲
└─────────────────┘  │                      │
                     └────────▶ [B]         │
                          ptr moved +1      │
                          end unchanged ────┘
  Returned: Some(&A)


AFTER exhaustion (.next() returns None)
─────────────────────────────────────────────────────
Stack                     Heap
┌─────────────────┐       ┌───┬───┬───┬───┬───┐
│ iter            │──────▶│ A │ B │ C │ D │ E │
│  .ptr == .end ──┼──┐    └───┴───┴───┴───┴───┘
└─────────────────┘  │                      ▲
                     └──────────────────────┘
  ptr == end  →  sequence is exhausted
  Returned: None
```

### What actually lives on the stack vs. heap

| Location | What's there |
|---|---|
| **Stack** | The iterator struct itself (ptr, end, maybe index) |
| **Heap** | The actual data (owned by the Vec/String/etc.) |
| **Iterator** | Borrows the heap data — does NOT own it (usually) |

> In Rust specifically: `vec.iter()` borrows, `vec.into_iter()` moves ownership into the iterator.

---

## The Core Interface

Every iterator in every language boils down to one operation:

```
next() -> Option<Item>
  Some(value)  →  here's the next item, state advanced
  None         →  sequence is exhausted
```

Everything else (`map`, `filter`, `zip`, `enumerate`, ...) is built on top of this single method.

---

## Iterator vs. Iterable

A common confusion:

| Concept | What it is | Example |
|---|---|---|
| **Iterable** | Something you *can* iterate over | `Vec<T>`, `String`, a range |
| **Iterator** | The *cursor* doing the traversal | `std::slice::Iter<'_, T>` |

```
Iterable ──.iter()──▶ Iterator ──.next()──▶ Option<Item>
```

You call `.iter()` (or equivalent) on an iterable to *produce* an iterator. The iterator is the thing that has state and moves.

---

## Metacognition: What Your Brain Needs to Track

When you encounter an iterator, ask yourself these questions in order:

### 1. What is the source?
> "Where does the data live, and who owns it?"

- Is the iterator borrowing (`&T`) or consuming (`T`)?
- Does calling `.iter()` vs `.into_iter()` matter here?

### 2. What is the current state?
> "Where is the cursor right now?"

- An iterator is a **snapshot of position**, not a snapshot of data.
- Two iterators over the same Vec are independent cursors.

### 3. What does `.next()` return?
> "What type comes out, and what does `None` mean?"

- `None` means exhaustion — not an error, not empty data.
- Once `None` is returned, most iterators stay exhausted (fused).

### 4. Is this lazy or eager?
> "Is work happening now, or when I consume?"

```
Lazy  (no work yet):   vec.iter().map(|x| x * 2).filter(|x| x > 4)
Eager (work happens):  .collect()  /  .for_each()  /  .sum()
```

Adapter methods (`map`, `filter`, `take`) are **lazy** — they return a new iterator struct that wraps the previous one. No elements are processed until you consume.

### 5. What is the consumption model?
> "After I use this, is the source gone?"

```
Borrow:   for x in &vec      →  vec still usable after
Move:     for x in vec       →  vec is consumed, gone
Clone:    for x in vec.clone() →  original intact, copy consumed
```

---

## The Iterator Composition Stack (mental image)

When you chain adapters, you're building a **stack of wrappers**:

```
Source data:       [1, 2, 3, 4, 5]
                        │
                   .iter()
                        │
                   Iter { ptr }           ← raw cursor
                        │
                   .filter(|x| x % 2 == 0)
                        │
                   Filter { iter, pred }  ← wraps Iter
                        │
                   .map(|x| x * 10)
                        │
                   Map { iter, f }        ← wraps Filter
                        │
                   .collect::<Vec<_>>()
                        │
                   [20, 40]               ← eager consumption
                                            pulls from Map,
                                            which pulls from Filter,
                                            which pulls from Iter
```

Each `.next()` call **cascades downward** through the stack until a value satisfies all predicates or the source is exhausted. This is **pull-based** lazy evaluation.

---

## Key Insight

> An iterator does not process elements — it *describes* how to process them.
> Processing only happens when something pulls from the end of the chain.

This is why you can build a chain over a million-element collection and pay zero cost until `.collect()` or `.for_each()` is called.
