# useEffect: The Synchronization Model

> Phase 2 | Topic 7

## Why this matters
`useEffect` is the most misunderstood hook. The correct mental model: **keep this side effect synchronized with this state/props**. Not "run code when something changes." Not "componentDidMount." Thinking of it as synchronization leads to correct dependency arrays and correct cleanup. The alternative leads to bugs.

## Sub-skills to master
```typescript
// Signature
useEffect(() => {
  // setup — runs after render when deps changed
  return () => {
    // cleanup — runs before next effect AND on unmount
  };
}, [dep1, dep2]); // dependency array

// No dep array: runs after EVERY render — almost always wrong
useEffect(() => { document.title = `Count: ${count}`; });

// Empty array []: runs once after mount — correct for one-time setup only
useEffect(() => {
  const sub = eventBus.subscribe(handler);
  return () => sub.unsubscribe();
}, []);

// With deps: re-runs whenever any dep changes
useEffect(() => {
  fetchUser(userId).then(setUser);
}, [userId]); // re-runs when userId changes

// Cleanup is critical for subscriptions, timers, AbortControllers
useEffect(() => {
  const controller = new AbortController();

  fetch(`/api/users/${userId}`, { signal: controller.signal })
    .then(r => r.json())
    .then(setUser)
    .catch(e => { if (e.name !== 'AbortError') setError(e); });

  return () => controller.abort(); // cancel if userId changes before response arrives
}, [userId]);

// INFINITE LOOP trap: object/function in deps creates new reference every render
useEffect(() => {
  fetchData(options);
}, [options]); // BUG if `options` is defined as {} inside the component
```

### Execution order
1. Component renders
2. React updates the DOM
3. Cleanup from previous effect runs (if any)
4. New effect runs

## Exercise
Build a `UserProfile` component that receives `userId: string` as a prop:
1. Fetches `/api/users/${userId}` when `userId` changes
2. Shows loading state while fetching
3. Shows error state if the fetch fails
4. Cancels the previous fetch using `AbortController` when `userId` changes before the response arrives
5. Cleans up properly on unmount

```typescript
function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // your useEffect here
}
```

## Mastery checkpoint
1. A new `userId` prop arrives. Write the exact sequence of events:
   - Component re-renders (with new userId)
   - Previous effect cleanup runs
   - New effect runs
   At what point does the AbortController cancel the old fetch?

2. Why does this cause an infinite loop?
```typescript
useEffect(() => {
  setData(transform(data));
}, [data]);
```

3. You have `useEffect(() => { fetchData(query); }, [query])`. The ESLint rule says `fetchData` should be in the deps. If you add it, and `fetchData` is defined in the component body, what happens? How do you fix it properly?

4. What is the difference between `useEffect` and `useLayoutEffect`? When would you use `useLayoutEffect`?
