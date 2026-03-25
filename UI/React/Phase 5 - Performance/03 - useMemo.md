# useMemo

> Phase 5 | Topic 3

## Why this matters
`useMemo` memoizes the result of an expensive computation, recalculating only when dependencies change. The critical word is **expensive** — computing a filtered array of 10 items is not expensive. Wrapping it in `useMemo` adds overhead without benefit. Use it when you have a measured performance problem, or to stabilize an object reference for a memoized child.

## Sub-skills to master
```typescript
// Syntax
const result = useMemo(() => expensiveComputation(a, b), [a, b]);
// Recomputes when a or b changes; returns cached value otherwise

// Use case 1: genuinely expensive computation
const processedData = useMemo(() => {
  return largeDataset
    .filter(complexPredicate)
    .map(heavyTransform)
    .sort(comparator);
}, [largeDataset, filter]);

// Use case 2: stabilizing a reference for React.memo children
// WITHOUT useMemo — new object reference every render → memo on child fails
function Parent() {
  const [x, setX] = useState(0);
  const config = { theme: 'dark', size: 'lg' }; // new ref every render
  return <MemoizedChild config={config} />; // memo always fails
}

// WITH useMemo — same reference until theme/size change
function Parent() {
  const [x, setX] = useState(0);
  const config = useMemo(() => ({ theme: 'dark', size: 'lg' }), []); // stable
  return <MemoizedChild config={config} />; // memo works
}

// Use case 3: expensive derived value displayed in the UI
const sortedItems = useMemo(() =>
  [...items].sort((a, b) => a.name.localeCompare(b.name)),
  [items]
);
```

### When NOT to use useMemo
```typescript
// Cheap computation — useMemo costs more than the computation
const fullName = useMemo(() => `${first} ${last}`, [first, last]); // overkill
const fullName = `${first} ${last}`; // just compute it

// Missing measurement — don't add useMemo without profiling first

// As a correctness guarantee — useMemo is an optimization hint, not a guarantee
// React may discard memoized values in some future scenarios
```

### Measuring before optimizing
```typescript
// Add timing to see if a computation is actually slow
const processedData = useMemo(() => {
  const t0 = performance.now();
  const result = expensiveComputation(data);
  console.log(`Computation took ${performance.now() - t0}ms`);
  return result;
}, [data]);
// If it's < 1ms, useMemo is probably not worth it
```

## Exercise
1. Build a component with a `data` array of 50,000 numbers and a `filter` string
2. Implement filtering and sorting in the component body (no useMemo)
3. Use `performance.now()` to measure how long it takes
4. Add `useMemo` — measure again
5. Reduce data to 50 items and measure both approaches — observe that useMemo overhead can exceed computation time for small datasets

## Mastery checkpoint
1. `useMemo` vs computed variable: when does the memoized version win?
2. You use `useMemo` to memoize an object passed to a child. The child is NOT wrapped in `React.memo`. Does the `useMemo` help performance? Why?
3. React documentation says `useMemo` is a hint, not a guarantee. What does that mean in practice?
