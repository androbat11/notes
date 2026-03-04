# `extends` as a Generic Constraint in TypeScript

The `extends` keyword in a **generic parameter** acts as a **constraint** — it restricts what types can be passed into a generic, ensuring the type has at least the shape you require.

## Syntax

```ts
function fn<T extends SomeType>(arg: T): T {
  return arg;
}
```

`T extends SomeType` means: *"T can be any type, as long as it is assignable to SomeType"*.

---

## Basic Example

```ts
function getLength<T extends { length: number }>(arg: T): number {
  return arg.length;
}

getLength("hello");   // OK — string has .length
getLength([1, 2, 3]); // OK — array has .length
getLength(42);        // Error — number has no .length
```

Without `extends { length: number }`, TypeScript would complain that `arg.length` might not exist.

---

## Constraining to a Known Type

```ts
interface User {
  id: number;
  name: string;
}

function printName<T extends User>(user: T): void {
  console.log(user.name);
}
```

`T` can be `User` or any **subtype** of `User` (i.e., an object with at least `id` and `name`).

---

## Constraining to Another Generic (`keyof`)

A common pattern — ensuring a key actually exists on an object:

```ts
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

const user = { id: 1, name: "Alice" };
getProperty(user, "name"); // OK → returns string
getProperty(user, "age");  // Error — "age" not a key of user
```

`K extends keyof T` means K must be one of the known keys of T.

---

## `extends` vs Interface Inheritance

| Context | Meaning |
|---|---|
| `class Dog extends Animal` | Dog inherits from Animal |
| `interface B extends A` | B must include all of A's members |
| `<T extends A>` | T must be assignable to A (structural constraint) |

In generics, `extends` does **not** imply inheritance — it only enforces structure.

---

## Conditional Types (Advanced)

`extends` is also used in **conditional types**:

```ts
type IsString<T> = T extends string ? "yes" : "no";

type A = IsString<string>; // "yes"
type B = IsString<number>; // "no"
```

This reads: *"If T is assignable to string, resolve to 'yes', otherwise 'no'"*.

---

## Summary

- `<T extends X>` constrains T to types that are assignable to X.
- It gives you access to X's members inside the generic function/type.
- It does not mean inheritance — it means structural compatibility.
- Combined with `keyof`, it enables safe property access patterns.
