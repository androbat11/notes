# Symbol in TypeScript

## What is a Symbol?

A `Symbol` is a **primitive type** — like `number` or `string` — but every symbol is **guaranteed unique**, even if created with the same description.

```typescript
const a = Symbol("id");
const b = Symbol("id");

console.log(a === b); // false — always unique
console.log(typeof a); // "symbol"
```

---

## Meta-cognition: How to Think About Symbols

> *"If strings are labels anyone can read and copy, symbols are badges only you possess."*

When you see `Symbol("name")`, the `"name"` is just a **debug label** — it has no functional meaning. Two symbols with the same label are still completely different values. This is the key mental shift: identity over value.

Think of it like a cryptographic UUID that **can never collide**, not even in theory.

---

## The Description Parameter

`Symbol()` accepts `string`, `number`, or nothing as its description. It is **only for display/debugging** — it does not affect the symbol's identity or behavior.

```typescript
Symbol();          // ✓ no description
Symbol("user");    // ✓ string
Symbol(3);         // ✓ number
Symbol(true);      // ✗ Error — boolean not allowed
Symbol({});        // ✗ Error — object not allowed
```

You can read the description back via the `.description` property:

```typescript
const a = Symbol("user");

console.log(a.description); // "user"
```

But it is **read-only** — you cannot change it after creation:

```typescript
a.description = "something else"; // ✗ Error: Cannot assign to 'description'
                                   //          because it is a read-only property
```

Two symbols with the same description are still completely different values:

```typescript
const a = Symbol(3);
const b = Symbol(3);

console.log(a.description); // "3"
console.log(a === b);       // false — description is just a label
```

---

## Practical Example: Collision-Free Object Keys

```typescript
// Without Symbol — naming collision risk
const user = {
  id: 1,
  name: "Alice",
};

// A third-party library also sets `id` — collision!
user.id = 999; // overwrites yours

// With Symbol — completely safe
const ID = Symbol("id");
const LIB_ID = Symbol("id"); // same name, different symbol

const userSafe = {
  [ID]: 1,
  name: "Alice",
};

(userSafe as any)[LIB_ID] = 999; // different key entirely
console.log(userSafe[ID]); // still 1 ✓
```

---

## Unique Symbol: `unique symbol`

`unique symbol` is a **compile-time type** that narrows a symbol to a *specific, branded identity*. It must be declared with `const` and typed explicitly.

```typescript
// Regular symbol type — just "symbol"
const X = Symbol("x");
type T1 = typeof X; // → symbol

// Unique symbol — a one-of-a-kind type
const Y: unique symbol = Symbol("y");
type T2 = typeof Y; // → typeof Y (not just "symbol")
```

**Why it matters** — nominal typing / branding:

```typescript
declare const UserID: unique symbol;
declare const PostID: unique symbol;

type UserID = typeof UserID;
type PostID = typeof PostID;

function getUser(id: UserID) { /* ... */ }

const uid = 42 as unknown as UserID;
const pid = 42 as unknown as PostID;

getUser(uid); // ✓ OK
getUser(pid); // ✗ Error: PostID is not assignable to UserID
```

Even though both are `42` at runtime, TypeScript treats them as **incompatible types** at compile time — preventing accidentally passing a `PostID` where a `UserID` is expected.

---

## Quick Reference

| Feature | `symbol` | `unique symbol` |
|---|---|---|
| Runtime uniqueness | Yes | Yes |
| Type-level uniqueness | No | Yes |
| Can be used as type | No | Yes (`typeof X`) |
| `const` required | No | Yes |
| Use case | Key collision avoidance | Nominal/branded types |

---

## When to Use Symbol

- **Metadata keys** on objects you don't own (avoid key collisions)
- **Well-known protocols** (e.g., `Symbol.iterator`, `Symbol.toPrimitive`)
- **Branded/nominal types** via `unique symbol` to make structurally identical types incompatible
