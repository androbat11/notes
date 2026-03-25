# Immutability Patterns

> Phase 1 | Topic 9 | Phase Checkpoint

## Why this matters
React's re-rendering system depends on reference equality checks. If you mutate state in place, React cannot detect that anything changed and will not re-render. This is not a best-practice suggestion — it is a **correctness requirement**. As a Rust developer you already think in terms of ownership and mutation — apply that same discipline here.

## Sub-skills to master
```typescript
// NEVER do this with state:
state.count++;                    // mutation — React won't re-render
arr.push(newItem);                // mutation
arr.sort();                       // mutation
obj.nested.field = 'value';      // mutation

// Immutable array operations
const added    = [...arr, newItem];                              // add to end
const prepend  = [newItem, ...arr];                              // add to start
const removed  = arr.filter(item => item.id !== targetId);      // remove by predicate
const replaced = arr.map(item => item.id === id ? newItem : item); // replace by id
const sorted   = [...arr].sort((a, b) => a.name.localeCompare(b.name)); // sort copy

// Immutable object updates
const updated  = { ...obj, field: newValue };                   // shallow update
const nested   = { ...obj, address: { ...obj.address, city } }; // nested update

// Immer — write mutating-looking code, get immutable output
import { produce } from 'immer';

const nextState = produce(state, draft => {
  draft.user.address.city = 'Lyon';  // looks like mutation, is not
  draft.items.push(newItem);          // this is safe inside produce
});
```

## Exercise
You have a kanban board state:
```typescript
interface Card    { id: string; title: string; done: boolean; }
interface Column  { id: string; name: string; cards: Card[]; }
interface Board   { columns: Column[]; }
```

Write pure functions (no mutation) for:

1. `addCard(board: Board, columnId: string, card: Card): Board`
2. `toggleCard(board: Board, columnId: string, cardId: string): Board`
3. `deleteCard(board: Board, columnId: string, cardId: string): Board`
4. `moveCard(board: Board, fromColumnId: string, toColumnId: string, cardId: string): Board`

All must return a **new Board** with updated references along the changed path, and unchanged references everywhere else (structural sharing).

## Phase 1 Checkpoint
Given this data structure:
```typescript
interface Address { city: string; zip: string; country: string; }
interface User {
  id: string;
  name: string;
  email: string;
  isActive: boolean;
  address: Address;
}
```

Write pure TypeScript functions (strict types, no mutation, no `any`):

1. `filterActiveUsers(users: User[]): User[]`
2. `sortByCity(users: User[]): User[]` — alphabetical, does not mutate the input array
3. `toDisplayUsers(users: User[]): { fullName: string; cityLabel: string; id: string }[]`
4. `summarize(users: User[]): { total: number; activeCount: number; cityCounts: Record<string, number> }`

No intermediate variables required. Chain where you can.
