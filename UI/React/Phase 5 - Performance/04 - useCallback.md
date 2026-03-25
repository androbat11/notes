# useCallback

> Phase 5 | Topic 4

## Why this matters
`useCallback` returns a memoized function reference that stays stable across renders as long as its dependencies don't change. Its purpose is narrow: prevent a memoized child component from re-rendering due to a new function reference from its parent. Without `React.memo` on the child, `useCallback` does nothing for rendering performance.

## Sub-skills to master
```typescript
// Syntax
const stableHandler = useCallback(() => {
  doSomething(a, b);
}, [a, b]); // same function reference until a or b changes

// The only useful scenario: passing to a memoized child
const handleDelete = useCallback((id: string) => {
  setItems(prev => prev.filter(i => i.id !== id));
}, []); // empty deps — setItems is stable

const MemoizedRow = React.memo(function Row({ onDelete }: { onDelete: (id: string) => void }) {
  return <button onClick={() => onDelete(rowId)}>Delete</button>;
});

// Parent — without useCallback, MemoizedRow re-renders on every parent render
// because handleDelete is a new function reference each time
function List() {
  const handleDelete = useCallback((id: string) => { ... }, []);
  return items.map(item => <MemoizedRow key={item.id} onDelete={handleDelete} />);
}
```

### When useCallback does NOT help
```typescript
// ✗ Child is NOT wrapped in React.memo — stable reference doesn't matter
<Button onClick={handleClick}>  // Button re-renders with parent regardless

// ✗ Handler is used only in useEffect — add it to deps instead of memoizing
// (or use a ref pattern if the function changes often)

// ✗ Creating a new function inline at the call site — defeats the purpose
<MemoizedChild onClick={() => stableCallback(item.id)} /> // new arrow every render!
```

### useCallback vs useMemo
```typescript
// These are equivalent:
const fn = useCallback(() => doSomething(x), [x]);
const fn = useMemo(() => () => doSomething(x), [x]);
// useCallback is just syntactic sugar for memoizing a function
```

### The over-memoization trap
```typescript
// Every function in the component wrapped in useCallback — very common anti-pattern
// Costs memory + comparison overhead on every render
// Only adds value when the function is passed to a memoized child or a useEffect dep

// WRONG: wrapping everything
const handleA = useCallback(() => {}, []);
const handleB = useCallback(() => {}, []);
const handleC = useCallback(() => {}, []);  // for buttons with no memoized children — wasted

// RIGHT: only for memoized children
const handleDelete = useCallback(...); // passed to React.memo'd Row component
const handleSearch = () => {};          // used only in this component — no useCallback needed
```

## Exercise
1. Build `ItemList` with 100 `Item` rows. Each `Item` has a delete button.
2. `ItemList` has a `filter` input (local state). Typing in the filter re-renders `ItemList`.
3. First version: `Item` is NOT memoized. Add `console.log` to each `Item`. Observe all 100 log on every keystroke.
4. Wrap `Item` in `React.memo`. Observe all 100 still log — because `onDelete` is a new function reference each render.
5. Add `useCallback` to `onDelete`. Observe only the affected row logs.

## Mastery checkpoint
1. `useCallback(fn, deps)` — `fn` is recreated every render. Does `useCallback` store the latest `fn` or the first one?
2. You have `const handler = useCallback(() => setValue(value), [value])`. `value` changes every render. Does `useCallback` help here?
3. Explain the relationship: `useCallback` is only useful when combined with ______.
