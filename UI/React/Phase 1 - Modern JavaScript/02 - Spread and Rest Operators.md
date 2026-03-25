# Spread and Rest Operators

> Phase 1 | Topic 2

## Why this matters
React relies on spread for immutable state updates (`{ ...prevState, field: newValue }`), for passing props forward (`<Component {...props} />`), and for merging configs without mutation. Misunderstanding spread — especially its **shallow** nature — is a source of subtle state bugs that are hard to trace.

## Sub-skills to master
```typescript
// Object spread — merge / override
const merged = { ...defaults, ...overrides };

// Object spread — immutable update
const updated = { ...user, name: 'Bob' };

// Shallow copy warning: nested objects are still shared references
const copy = { ...user }; // copy.address === user.address (same reference!)

// Array spread — clone
const clone = [...arr];

// Array spread — concat
const combined = [...arr1, ...arr2];

// Insert at index (immutable)
const inserted = [...arr.slice(0, index), newItem, ...arr.slice(index)];

// Replace at index (immutable)
const replaced = [...arr.slice(0, index), newItem, ...arr.slice(index + 1)];

// Rest in function params
function fn(first: string, ...rest: string[]) {}

// Rest in destructuring
const { a, b, ...remaining } = obj;
const [head, ...tail] = arr;

// JSX prop spreading
<Input {...inputProps} className="override" /> // className overrides spread value
```

## Exercise
**Part 1 — Immutable nested update**

Given:
```typescript
const state = {
  user: {
    name: 'Alice',
    address: { city: 'Paris', zip: '75001' },
  },
  theme: 'dark',
};
```

Write a pure function `updateCity(state, newCity)` that returns a new state object with `city` updated to `newCity`, without mutating the original and without losing any fields.

Explain why a single spread `{ ...state, city: newCity }` would be wrong.

**Part 2 — Array immutable replace**

Write a pure function `replaceAtIndex<T>(arr: T[], index: number, newItem: T): T[]` that returns a new array with the item at `index` replaced — no mutation.

## Mastery checkpoint
1. Why does `const copy = { ...obj }` NOT protect you from mutation if `obj` has nested objects?
2. In React, why is `setState({ ...state, count: state.count + 1 })` correct but `state.count++; setState(state)` broken? (Two separate reasons.)
3. When prop spreading in JSX (`<Comp {...props} />`), what is the danger? How do you safely pass through props while still being able to override specific ones?
