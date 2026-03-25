# React.memo

> Phase 5 | Topic 2

## Why this matters
`React.memo` prevents a component from re-rendering when its props are shallowly equal to the previous render. Used correctly it eliminates expensive renders. Used incorrectly it adds memory and comparison cost with zero benefit. The key question before reaching for it: is this component actually slow, and are its props actually stable?

## Sub-skills to master
```typescript
// Wrapping a component
const ExpensiveList = React.memo(function ExpensiveList({ items }: { items: Item[] }) {
  // Only re-renders when items reference changes
  return <ul>{items.map(i => <li key={i.id}>{i.name}</li>)}</ul>;
});

// With a named function (better DevTools display name)
function ExpensiveListBase({ items }: { items: Item[] }) {
  return <ul>{items.map(i => <li key={i.id}>{i.name}</li>)}</ul>;
}
export const ExpensiveList = React.memo(ExpensiveListBase);

// Custom comparator (rarely needed)
const MyComponent = React.memo(MyComponentBase, (prevProps, nextProps) => {
  // Return true to SKIP re-render (props considered equal)
  // Return false to RE-RENDER
  return prevProps.id === nextProps.id && prevProps.name === nextProps.name;
});
```

### Shallow equality check
```typescript
// memo compares each prop with Object.is()
{ id: 1, name: 'Alice' } vs { id: 1, name: 'Alice' }
// → primitives: same values ✓ — memo SKIPS re-render

{ items: [1, 2, 3] } vs { items: [1, 2, 3] }
// → different array references ✗ — memo RE-RENDERS (even though contents are equal)
```

### When memo helps
```typescript
// ✓ Component is expensive to render (long list, complex calculation in JSX)
// ✓ Props are primitives (string, number, boolean) that rarely change
// ✓ Props are stable references (memoized with useMemo / useCallback)
```

### When memo does NOT help
```typescript
// ✗ Parent passes inline objects: <Comp options={{ color: 'blue' }} /> — always new ref
// ✗ Parent passes inline functions: <Comp onClick={() => fn(id)} /> — always new ref
// ✗ Parent passes inline arrays: <Comp items={[...list]} /> — always new ref
// ✗ Component renders almost always anyway
// ✗ Component is cheap to render
```

## Exercise
1. Create a `ParentComponent` with a `count` state and a `message` state
2. Create a `MessageDisplay` that renders the `message` prop — expensive simulation: do 10,000 iterations in the render
3. Observe that clicking "increment count" re-renders `MessageDisplay` even though `message` didn't change
4. Wrap `MessageDisplay` in `React.memo` and verify the expensive render is skipped
5. Now add `onClick={() => console.log(message)}` as a prop — observe memo breaks again
6. Fix with `useCallback` — observe memo works again

## Mastery checkpoint
1. `React.memo` wraps a component, but it still re-renders on every parent render. What are the 3 most common causes?
2. Is `React.memo` worth using on every component by default? Why or why not?
3. What is the actual cost of `React.memo`? (It is not free — what does it do on every render even when skipping?)
