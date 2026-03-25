# Destructuring

> Phase 1 | Topic 1

## Why this matters
Destructuring is in every React file. Props are destructured in every component signature. `useState` returns an array you destructure. `useReducer`, custom hooks — all destructured. Reading React code fluently requires seeing through destructuring syntax instantly.

## Sub-skills to master
```typescript
// Object destructuring
const { name, age } = user;

// Rename on extraction
const { name: userName } = user;

// Default values
const { theme = 'light' } = settings;

// Nested
const { address: { city } } = user;

// Nested with rename + default
const { address: { city: userCity = 'Unknown' } } = user;

// Array destructuring
const [first, second, ...rest] = arr;

// Skip elements
const [, second] = arr;

// Function parameter destructuring (React component style)
function Card({ title, disabled = false, onClick }: Props) {}

// In loops
for (const { id, label } of items) { }
```

## Exercise
Given this API response object:
```typescript
const response = {
  data: {
    id: 'usr_123',
    profile: {
      name: 'Alice Dupont',
      avatar: null,
    },
    settings: {
      theme: 'dark',
      notifications: true,
    },
    address: {
      city: 'Paris',
      country: 'France',
    },
  },
  meta: {
    requestId: 'req_456',
    duration: 120,
  },
};
```

Write **a single destructuring expression** that extracts:
- `userId` from `data.id`
- `displayName` from `data.profile.name`
- `avatar` from `data.profile.avatar`, defaulting to `'/default-avatar.png'`
- `theme` from `data.settings.theme`, defaulting to `'light'`
- `city` from `data.address.city`
- `requestId` from `meta.requestId`

## Mastery checkpoint
Write a TypeScript component signature for a `Button` component that:
- Accepts `id: string`, `label: string`, `disabled?: boolean` (defaults to `false`), `variant?: 'primary' | 'danger'` (defaults to `'primary'`), `onClick: (id: string) => void`
- Uses an `interface Props`
- Destructures all props in the function parameter with defaults inline

One expression — interface definition + function signature.
