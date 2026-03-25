# Optional Chaining and Nullish Coalescing

> Phase 1 | Topic 6

## Why this matters
React components constantly receive data that may be `null` or `undefined` — data not yet loaded, optional props, API responses with missing fields. Optional chaining (`?.`) and nullish coalescing (`??`) are how you write safe, readable access expressions without verbose null checks. Every React codebase uses these.

## Sub-skills to master
```typescript
// Optional chaining — short-circuits to undefined if left side is null/undefined
user?.profile?.address?.city      // property access
user?.getProfile?.()              // method call
users?.[0]?.name                  // array index

// Nullish coalescing — fallback when value is null or undefined (NOT for falsy values)
const city = user?.address?.city ?? 'Unknown';
const count = response.count ?? 0;

// ?? vs || — THE CRITICAL DIFFERENCE
const a = 0 || 'default';    // → 'default' (wrong! 0 is falsy but valid)
const b = 0 ?? 'default';    // → 0 (correct! 0 is not null/undefined)

const c = '' || 'default';   // → 'default' (wrong for valid empty string)
const d = '' ?? 'default';   // → '' (correct)

const e = false || true;     // → true (falsy short-circuit)
const f = false ?? true;     // → false (not null/undefined)

// Nullish assignment
user.name ??= 'Anonymous';   // only assigns if user.name is null/undefined

// Chaining
const displayName = user?.profile?.displayName
  ?? user?.name
  ?? 'Anonymous';
```

## Exercise
Given an API response that may have partially missing fields:
```typescript
interface ApiResponse {
  user?: {
    id: string;
    name?: string;
    stats?: {
      postCount?: number;
      followerCount?: number;
    };
    subscription?: {
      plan: string;
      expiresAt?: string;
    };
  };
}
```

Write a function `extractDisplayData(response: ApiResponse)` that returns:
```typescript
{
  userId: string | null,
  displayName: string,        // default: 'Anonymous'
  postCount: number,          // default: 0
  followerCount: number,      // default: 0
  plan: string,               // default: 'free'
  isExpired: boolean,         // true if expiresAt is set and in the past
}
```

Use `?.` and `??` throughout. No `if` statements.

## Mastery checkpoint
1. You have a product with `{ price: 0, discount: null }`. Write an expression for `finalPrice` using `??` that gives `0` (the actual price) rather than falling through to a default. Show why `||` would give the wrong result.
2. What does `user?.address?.city ?? 'N/A'` return in each case:
   - `user = null`
   - `user = { address: null }`
   - `user = { address: { city: '' } }`
   - `user = { address: { city: 'Paris' } }`
