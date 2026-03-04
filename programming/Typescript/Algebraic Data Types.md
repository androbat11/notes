# Algebraic Data Types (ADTs) in TypeScript

ADTs are a way to model data by **composing types algebraically**. There are two building blocks:

| Type | Also called | TypeScript equivalent |
|---|---|---|
| **Product type** | AND type | `object`, `tuple`, `interface` |
| **Sum type** | OR type | `union` (`\|`) |

The "algebra" refers to how you count the possible values:
- Product: possibilities multiply (`A & B` = `|A| × |B|`)
- Sum: possibilities add (`A | B` = `|A| + |B|`)

---

## 1. Product Types — "AND"

A product type holds **all fields simultaneously**.

```ts
type Point = {
  x: number;  // AND
  y: number;  // AND
  z: number;
};
// A Point is an x AND a y AND a z
```

Tuples are also product types:

```ts
type Pair<A, B> = [A, B]; // an A AND a B
```

---

## 2. Sum Types — "OR"

A sum type holds **exactly one of its variants** at a time.

```ts
type Shape =
  | { kind: "circle";    radius: number }
  | { kind: "rectangle"; width: number; height: number }
  | { kind: "triangle";  base: number;  height: number };
// A Shape is EITHER a circle OR a rectangle OR a triangle
```

The `kind` field is called a **discriminant** (or tag). It makes narrowing unambiguous.

---

## 3. Discriminated Unions — The Core Pattern

Discriminated unions are sum types with a literal tag field. TypeScript narrows them automatically.

```ts
type Shape =
  | { kind: "circle";    radius: number }
  | { kind: "rectangle"; width: number; height: number };

function area(shape: Shape): number {
  switch (shape.kind) {
    case "circle":
      return Math.PI * shape.radius ** 2;     // shape is Circle here
    case "rectangle":
      return shape.width * shape.height;      // shape is Rectangle here
  }
}
```

### Exhaustiveness checking

Force TypeScript to error if you forget a variant:

```ts
function assertNever(x: never): never {
  throw new Error(`Unhandled case: ${JSON.stringify(x)}`);
}

function area(shape: Shape): number {
  switch (shape.kind) {
    case "circle":    return Math.PI * shape.radius ** 2;
    case "rectangle": return shape.width * shape.height;
    default:          return assertNever(shape); // compile error if a variant is missing
  }
}
```

If you add a new variant to `Shape` but forget to handle it, TypeScript will error at the `assertNever` line.

---

## 4. The `Option` / `Maybe` Type

Replaces `null`/`undefined` with an explicit, type-safe absence.

```ts
type Option<A> =
  | { _tag: "Some"; value: A }
  | { _tag: "None" };

// Constructors
const Some = <A>(value: A): Option<A> => ({ _tag: "Some", value });
const None: Option<never> = { _tag: "None" };

// Usage
function findUser(id: number): Option<User> {
  const user = db.find(u => u.id === id);
  return user ? Some(user) : None;
}

const result = findUser(42);

if (result._tag === "Some") {
  console.log(result.value.name); // TypeScript knows value exists
}
```

### Mapping over an Option (functor)

```ts
function map<A, B>(option: Option<A>, fn: (a: A) => B): Option<B> {
  if (option._tag === "None") return None;
  return Some(fn(option.value));
}

const name = map(findUser(42), user => user.name);
// Option<string> — no nulls, no runtime surprises
```

### Chaining Options (flatMap / chain)

```ts
function flatMap<A, B>(option: Option<A>, fn: (a: A) => Option<B>): Option<B> {
  if (option._tag === "None") return None;
  return fn(option.value);
}

// Example: find user, then find their address
const address = flatMap(findUser(42), user => findAddress(user.addressId));
// Option<Address>
```

---

## 5. The `Result` / `Either` Type

Replaces thrown exceptions with an explicit success/failure value.

```ts
type Result<E, A> =
  | { _tag: "Ok";  value: A }
  | { _tag: "Err"; error: E };

// Constructors
const Ok  = <A>(value: A):  Result<never, A> => ({ _tag: "Ok",  value });
const Err = <E>(error: E):  Result<E, never> => ({ _tag: "Err", error });
```

### Example: parsing and validation

```ts
type ParseError = "empty_input" | "not_a_number";

function parseNumber(input: string): Result<ParseError, number> {
  if (input.trim() === "") return Err("empty_input");
  const n = Number(input);
  if (isNaN(n))             return Err("not_a_number");
  return Ok(n);
}

const result = parseNumber("42");

switch (result._tag) {
  case "Ok":  console.log("Parsed:", result.value); break;
  case "Err": console.log("Error:", result.error);  break;
}
```

### Chaining Results (railway-oriented programming)

```ts
function map<E, A, B>(result: Result<E, A>, fn: (a: A) => B): Result<E, B> {
  if (result._tag === "Err") return result;
  return Ok(fn(result.value));
}

function flatMap<E, A, B>(result: Result<E, A>, fn: (a: A) => Result<E, B>): Result<E, B> {
  if (result._tag === "Err") return result;
  return fn(result.value);
}

// Pipeline: each step only runs if the previous succeeded
const final = flatMap(
  flatMap(
    parseNumber(rawInput),
    n => validatePositive(n)
  ),
  n => formatOutput(n)
);
// Result<ParseError | ValidationError, string>
```

This is called **railway-oriented programming** — success goes on the "happy track", errors are routed around automatically.

---

## 6. Recursive ADTs

ADTs can reference themselves to model tree-like structures.

```ts
// A linked list
type List<A> =
  | { _tag: "Nil" }
  | { _tag: "Cons"; head: A; tail: List<A> };

// A binary tree
type Tree<A> =
  | { _tag: "Leaf" }
  | { _tag: "Node"; value: A; left: Tree<A>; right: Tree<A> };

// Example: sum all values in a tree
function sumTree(tree: Tree<number>): number {
  switch (tree._tag) {
    case "Leaf": return 0;
    case "Node": return tree.value + sumTree(tree.left) + sumTree(tree.right);
  }
}
```

---

## 7. Modeling Domain State as ADTs

ADTs shine when modeling states that have **mutually exclusive shapes**.

```ts
// Bad: using optional fields — all combinations are technically valid
type Order = {
  status: "pending" | "paid" | "shipped" | "cancelled";
  paymentId?: string;      // only valid when paid
  trackingNumber?: string; // only valid when shipped
  cancelReason?: string;   // only valid when cancelled
};

// Good: each state carries exactly the data it needs
type Order =
  | { status: "pending" }
  | { status: "paid";      paymentId: string }
  | { status: "shipped";   paymentId: string; trackingNumber: string }
  | { status: "cancelled"; cancelReason: string };

function processOrder(order: Order) {
  switch (order.status) {
    case "pending":   return schedulePay(order);
    case "paid":      return ship(order.paymentId);      // paymentId guaranteed
    case "shipped":   return track(order.trackingNumber); // trackingNumber guaranteed
    case "cancelled": return log(order.cancelReason);
  }
}
```

This makes **illegal states unrepresentable** — a core principle of type-driven design.

---

## 8. Pattern Matching Utility

TypeScript lacks native `match`, but you can build one:

```ts
type Matcher<T extends { _tag: string }, R> = {
  [K in T["_tag"]]: (variant: Extract<T, { _tag: K }>) => R;
};

function match<T extends { _tag: string }, R>(
  value: T,
  cases: Matcher<T, R>
): R {
  return (cases as any)[value._tag](value);
}

// Usage
const result = match(findUser(42), {
  Some: ({ value }) => `Hello, ${value.name}`,
  None: ()          => "User not found",
});
```

---

## Summary

| Concept | TypeScript tool | FP use case |
|---|---|---|
| Product type | `interface`, object literal | Group related data |
| Sum type | discriminated union | Model alternatives |
| `Option<A>` | `Some \| None` | Replace null/undefined |
| `Result<E, A>` | `Ok \| Err` | Replace exceptions |
| Recursive ADT | self-referencing union | Trees, lists, grammars |
| Exhaustiveness | `assertNever` | Catch missing cases at compile time |

The core principle: **make illegal states unrepresentable** — encode business rules into the type system so the compiler catches logic errors before runtime.
