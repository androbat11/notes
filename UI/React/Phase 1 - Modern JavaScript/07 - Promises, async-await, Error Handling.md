# Promises, async/await, Error Handling

> Phase 1 | Topic 7

## Why this matters
Every React data-fetching pattern involves Promises. `useEffect` with fetch, React Query's internals, form submission handlers — all async. You need precise error handling patterns, including the distinction between network errors and HTTP error responses, to build robust components.

## Sub-skills to master
```typescript
// Promise states: pending → fulfilled | rejected

// async/await — syntactic sugar over Promises
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);

  // CRITICAL: fetch() does NOT reject on HTTP errors — you must check response.ok
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }

  return response.json() as Promise<User>;
}

// try/catch/finally
async function loadUser(id: string) {
  try {
    const user = await fetchUser(id);
    return user;
  } catch (error) {
    if (error instanceof NetworkError) { /* handle */ }
    throw error; // re-throw if you can't handle it
  } finally {
    setLoading(false); // always runs
  }
}

// Parallel — both start immediately, fail fast if either rejects
const [user, posts] = await Promise.all([fetchUser(id), fetchPosts(id)]);

// Parallel — all results, never rejects
const results = await Promise.allSettled([fetchA(), fetchB()]);
results.forEach(r => {
  if (r.status === 'fulfilled') console.log(r.value);
  if (r.status === 'rejected') console.error(r.reason);
});

// Race — whichever resolves/rejects first wins
const result = await Promise.race([fetch('/api/data'), timeout(5000)]);
```

## Exercise
Write a `fetchUser(id: string): Promise<User>` function that:
1. Makes a `fetch` request to `/api/users/${id}`
2. On network failure → rejects with `NetworkError`
3. On HTTP 404 → throws `NotFoundError` (custom class)
4. On HTTP 500 → throws `ServerError` (custom class)
5. On success → returns `User` object (type it properly)

Then write the call site with `try/catch` that:
- Shows a "not found" message for `NotFoundError`
- Shows a "server error" message for `ServerError`
- Shows a generic "network error" message for `NetworkError`
- Re-throws unexpected errors

```typescript
class NotFoundError extends Error { constructor(id: string) { super(`User ${id} not found`); } }
class ServerError extends Error {}
class NetworkError extends Error {}
```

## Mastery checkpoint
```typescript
// Pattern A
const [a, b] = await Promise.all([fetchA(), fetchB()]);

// Pattern B
const a = await fetchA();
const b = await fetchB();
```

1. What is the performance difference between these two patterns?
2. If `fetchA()` takes 300ms and `fetchB()` takes 500ms, how long does each pattern take?
3. If `fetchA()` rejects in Pattern A, what happens to `fetchB()`?
4. When is Pattern B appropriate despite being slower?
