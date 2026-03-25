# Closures and Stale State

> Phase 1 | Topic 8

## Why this matters
The most common category of React bugs involves closures capturing stale values. A `useEffect` or event handler that closes over a state variable but does not list it in the dependency array will always see the value from the render it was created in — not the current value. Understanding closures precisely is the key to this entire class of bugs.

## Sub-skills to master
```typescript
// A closure captures the variables from its surrounding scope at creation time
function makeCounter(start: number) {
  let count = start;
  return {
    increment: () => ++count,  // closes over `count`
    getCount: () => count,
  };
}

// The stale closure pattern — classic React bug
function Counter() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    const id = setInterval(() => {
      setCount(count + 1); // BUG: `count` is always 0 (captured at effect creation)
    }, 1000);
    return () => clearInterval(id);
  }, []); // empty deps = never re-runs = count is always the initial 0
}

// Fix 1: functional update — doesn't need to read current count
setCount(prev => prev + 1); // always correct

// Fix 2: add count to deps — but now the interval resets every second
useEffect(() => { ... }, [count]);

// Fix 3: useRef for stable mutable reference
const countRef = useRef(count);
countRef.current = count; // always the latest value
useEffect(() => {
  const id = setInterval(() => {
    setCount(countRef.current + 1); // reads latest via ref
  }, 1000);
  return () => clearInterval(id);
}, []); // ref is stable, no deps needed
```

## Exercise
Build a `Counter` component with:
1. A displayed count starting at 0
2. An "Increment" button
3. A "Delayed Increment (+1 after 3 seconds)" button that calls `setCount(count + 1)` after 3 seconds

**Step 1:** Implement with the stale closure bug. Click "Increment" 5 times rapidly, then click "Delayed Increment". Observe the count revert.

**Step 2:** Fix using `setCount(c => c + 1)`. Verify the bug is gone.

**Step 3:** Explain in a comment exactly why `setCount(count + 1)` captured the wrong value and why the functional form does not.

## Mastery checkpoint
1. In your own words (no code): why does a `setInterval` inside `useEffect` with an empty dep array `[]` always see the initial state value, even as it changes?
2. What is the difference between these two `useEffect` patterns for a component that subscribes to a WebSocket with a message handler that reads state?
   ```typescript
   // Pattern A — handler created once
   useEffect(() => {
     socket.on('message', () => process(data)); // data is stale
   }, []);

   // Pattern B — ref pattern
   const dataRef = useRef(data);
   dataRef.current = data;
   useEffect(() => {
     socket.on('message', () => process(dataRef.current)); // always fresh
   }, []);
   ```
3. The ESLint rule `react-hooks/exhaustive-deps` would warn about Pattern A. What would it suggest, and why might naively following that suggestion (adding `data` to the dep array) cause a different bug?
