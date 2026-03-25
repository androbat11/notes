# React's Rendering Model

> Phase 5 | Topic 1

## Why this matters
Before optimizing anything, you must understand exactly when and why React re-renders. The rendering model is simple but its consequences surprise most developers. Profiling before optimizing is not optional — without a mental model of re-renders, you optimize the wrong things.

## Sub-skills to master

### What triggers a re-render
```typescript
// 1. setState / dispatch — direct cause
const [count, setCount] = useState(0);
setCount(1); // triggers re-render

// 2. Parent re-renders → ALL children re-render by default
function Parent() {
  const [x, setX] = useState(0);
  return <Child />; // Child re-renders every time Parent does, even with no props
}

// 3. Context value changes — all consumers re-render
const { theme } = useContext(ThemeContext); // re-renders when theme changes

// 4. useReducer dispatch
dispatch({ type: 'ACTION' }); // triggers re-render
```

### Re-rendering ≠ DOM update
```
1. React calls the component function → produces new JSX (virtual DOM)
2. React diffs new virtual DOM vs previous virtual DOM
3. React updates ONLY the changed DOM nodes
```
The function call is cheap. The DOM update is what's expensive. Many re-renders with no actual DOM changes are wasteful but not catastrophic.

### The referential equality trap
```typescript
function Parent() {
  const [x, setX] = useState(0);

  // These create NEW references on every render:
  const options = { color: 'blue' };        // new object reference
  const items = ['a', 'b', 'c'];            // new array reference
  const handleClick = () => console.log(x); // new function reference

  // Child wrapped in React.memo will STILL re-render because
  // its props (options, items, handleClick) are always new references
  return <Child options={options} items={items} onClick={handleClick} />;
}
```

### Bailout
React skips re-rendering when:
- `Object.is(prevState, nextState)` is true (same reference or same primitive value)
- The component is wrapped in `React.memo` AND all props pass shallow equality

## Exercise
Build a component tree and observe re-renders:
```
Counter (has count state)
├── Header (no props)
├── CountDisplay (receives count)
└── Controls (receives setCount)
```

1. Add a `console.log('Header rendered')`, `console.log('CountDisplay rendered')`, `console.log('Controls rendered')` to each child
2. Click the increment button — observe that ALL three children log, even `Header` which doesn't use `count`
3. Wrap `Header` in `React.memo` — observe that it no longer re-renders

## Mastery checkpoint
1. A component has no props and no state. Its parent re-renders. Does the child re-render? Why?
2. `React.memo` is supposed to prevent re-renders. But your memoized component still re-renders on every parent render. What is the likely cause?
3. What is the difference between a React "render" (calling the function) and a DOM "update" (writing to the browser DOM)?
4. You call `setState` with the same value as current state: `setCount(count)`. Does React re-render? (Answer: it bails out after the first re-render.)
