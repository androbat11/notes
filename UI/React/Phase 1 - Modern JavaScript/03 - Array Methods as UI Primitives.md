# Array Methods as UI Primitives

> Phase 1 | Topic 3

## Why this matters
In React, UI is a function of data. You do not imperatively add and remove DOM nodes — you transform data arrays into JSX arrays using `.map()`, `.filter()`, `.reduce()`. These are the primary way React UIs are built. Every list, every filtered view, every aggregated summary uses these.

## Sub-skills to master
```typescript
// .map() — transform every element, same length output
const labels = users.map(u => u.name);

// .filter() — keep elements where predicate is true
const active = users.filter(u => u.isActive);

// .reduce() — accumulate a single value
const total = prices.reduce((sum, p) => sum + p, 0);

// .find() — first match or undefined
const user = users.find(u => u.id === id);

// .findIndex() — index of first match or -1
const idx = users.findIndex(u => u.id === id);

// .some() — true if any matches
const hasAdmin = users.some(u => u.role === 'admin');

// .every() — true if all match
const allActive = users.every(u => u.isActive);

// .flatMap() — map then flatten one level
const allTags = posts.flatMap(p => p.tags);

// .sort() — MUTATES the array! Always spread first
const sorted = [...users].sort((a, b) => a.name.localeCompare(b.name));

// Chaining
const result = users
  .filter(u => u.isActive)
  .sort((a, b) => a.name.localeCompare(b.name))
  .map(u => ({ id: u.id, label: u.name }));
```

## Exercise
Given an array of products:
```typescript
interface Product {
  id: string;
  name: string;
  price: number;
  category: string;
  inStock: boolean;
  rating: number; // 0–5
}
```

Write a **pure function** with this signature:
```typescript
function getDisplayProducts(
  products: Product[],
  category: string
): {
  items: { id: string; label: string; formattedPrice: string }[];
  totalCount: number;
}
```

It must:
1. Filter to in-stock items only
2. Filter to the given category
3. Sort by rating descending
4. Map to `{ id, label: name, formattedPrice: '$X.XX' }`
5. Return both the `items` array and `totalCount`

No mutation. No intermediate variables required (chain it).

## Mastery checkpoint
Given:
```typescript
const departments = [
  { name: 'Engineering', employees: [{ title: 'Engineer' }, { title: 'Manager' }] },
  { name: 'Design', employees: [{ title: 'Designer' }, { title: 'Manager' }] },
];
```

Write a **single expression** using `.flatMap()` and `.reduce()` that produces:
```typescript
{ Engineer: 1, Manager: 2, Designer: 1 }
```
