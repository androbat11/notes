# MongoDB Projection

## What is Projection?

**Projection** is the mechanism MongoDB uses to **control which fields are returned** in a query result.
Instead of fetching the entire document, you tell MongoDB: _"I only want these fields"_ or _"give me everything except these fields"_.

This is analogous to the `SELECT field1, field2 FROM table` in SQL — instead of `SELECT *`.

---

## Why Use Projection?

- **Performance**: Less data transferred over the network.
- **Privacy**: Avoid exposing sensitive fields (e.g., passwords, tokens).
- **Clarity**: The caller only receives what it needs.

---

## Basic Syntax

Projection is the **second argument** to `find()`:

```js
db.collection.find(<filter>, <projection>)
```

| Value | Meaning                  |
|-------|--------------------------|
| `1`   | Include this field        |
| `0`   | Exclude this field        |

---

## Inclusion vs Exclusion

### Inclusion — Explicitly include fields

```js
db.users.find({}, { name: 1, email: 1 })
```

Result:
```json
{ "_id": ObjectId("..."), "name": "Alice", "email": "alice@example.com" }
```

> `_id` is **always included by default** unless you explicitly exclude it.

### Exclusion — Explicitly exclude fields

```js
db.users.find({}, { password: 0, token: 0 })
```

Result: every field except `password` and `token`.

### Suppress `_id`

```js
db.users.find({}, { name: 1, email: 1, _id: 0 })
```

Result:
```json
{ "name": "Alice", "email": "alice@example.com" }
```

---

## The Golden Rule: Don't Mix Include and Exclude

You **cannot mix** inclusion and exclusion in the same projection — except for `_id`.

```js
// INVALID — mixing 1 and 0 (besides _id)
db.users.find({}, { name: 1, password: 0 })  // Error!

// VALID — _id is the only exception
db.users.find({}, { name: 1, _id: 0 })       // OK
```

---

## Nested Fields (Dot Notation)

You can project fields inside embedded documents using dot notation:

```js
// Document structure:
// { name: "Alice", address: { city: "NY", zip: "10001" } }

db.users.find({}, { "address.city": 1 })
```

Result:
```json
{ "_id": ObjectId("..."), "address": { "city": "NY" } }
```

---

## Array Field Projection

### Project a field that is an array

```js
db.orders.find({}, { items: 1 })
```

Returns the entire `items` array as-is.

### `$elemMatch` — Return only the first matching element

```js
db.orders.find(
  { "items.qty": { $gte: 5 } },
  { "items": { $elemMatch: { qty: { $gte: 5 } } } }
)
```

Returns only **the first** array element that matches the condition.

### `$slice` — Limit number of array elements returned

```js
// Return first 3 elements of 'comments' array
db.posts.find({}, { comments: { $slice: 3 } })

// Return last 3 elements
db.posts.find({}, { comments: { $slice: -3 } })

// Skip 2, return next 4
db.posts.find({}, { comments: { $slice: [2, 4] } })
```

### `$` (Positional Operator) — Return first element that matches query

```js
db.orders.find(
  { "items.name": "Apple" },
  { "items.$": 1 }
)
```

Returns only the first matching element in `items` that satisfies the query filter.
The `$` refers to the matched position from the filter.

---

## Projection in Aggregation Pipeline (`$project`)

In an aggregation pipeline, `$project` works similarly but is **more powerful**:

```js
db.users.aggregate([
  { $project: { name: 1, email: 1, _id: 0 } }
])
```

### Computed/Renamed Fields

You can create new fields or rename existing ones:

```js
db.orders.aggregate([
  {
    $project: {
      customerName: "$name",              // rename 'name' to 'customerName'
      totalWithTax: { $multiply: ["$total", 1.2] }  // computed field
    }
  }
])
```

### Nested Computed Fields

```js
db.users.aggregate([
  {
    $project: {
      fullName: { $concat: ["$firstName", " ", "$lastName"] },
      yearJoined: { $year: "$createdAt" }
    }
  }
])
```

### Conditional Fields with `$cond`

```js
db.products.aggregate([
  {
    $project: {
      name: 1,
      status: {
        $cond: {
          if: { $gte: ["$stock", 1] },
          then: "In Stock",
          else: "Out of Stock"
        }
      }
    }
  }
])
```

---

## `$project` vs `find()` Projection — Key Differences

| Feature                     | `find()` projection | `$project` in aggregation |
|-----------------------------|---------------------|---------------------------|
| Include/exclude fields      | Yes                 | Yes                       |
| Rename fields               | No                  | Yes                       |
| Computed/derived fields     | No                  | Yes                       |
| Use expressions (`$concat`) | No                  | Yes                       |
| Full pipeline integration   | No                  | Yes                       |

---

## Real-World Examples

### Return only public profile info

```js
db.users.find(
  { username: "alice" },
  { username: 1, bio: 1, avatar: 1, _id: 0 }
)
```

### Exclude sensitive data before API response

```js
db.users.find({}, { password: 0, refreshToken: 0, __v: 0 })
```

### Get product name and a computed discount price

```js
db.products.aggregate([
  {
    $project: {
      name: 1,
      discountedPrice: { $multiply: ["$price", 0.9] }
    }
  }
])
```

### Paginate array (comments page 2, 10 per page)

```js
db.posts.find(
  { _id: postId },
  { comments: { $slice: [10, 10] } }
)
```

---

## Summary

| Scenario                        | Tool                        |
|---------------------------------|-----------------------------|
| Return specific fields          | `{ field: 1 }`              |
| Hide specific fields            | `{ field: 0 }`              |
| Hide `_id`                      | `{ _id: 0 }`                |
| Nested field                    | `{ "a.b": 1 }`              |
| Slice array                     | `{ arr: { $slice: N } }`    |
| First matching array element    | `{ arr: { $elemMatch: {} }}` |
| Rename / compute fields         | `$project` in aggregation   |
