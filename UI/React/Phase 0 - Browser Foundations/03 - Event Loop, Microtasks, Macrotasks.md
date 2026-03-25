# Event Loop, Microtasks, Macrotasks

> Phase 0 | Topic 3

## Why this matters
React's state updates, effects, and async data fetching all operate within the JavaScript event loop. Stale closure bugs, update batching behavior, and the timing of `useEffect` all make sense only if you have a precise mental model of how JS scheduling works. The browser adds the rendering pipeline as a participant in the loop, which changes the picture compared to Node.js.

## Sub-skills to master
- **Call stack:** synchronous execution — one thing at a time
- **Macrotask queue:** `setTimeout`, `setInterval`, UI events (`click`, `keydown`), I/O callbacks
- **Microtask queue:** Promise `.then`/`.catch`, `queueMicrotask()`, `MutationObserver`
- **Execution order per iteration:** current sync code → drain all microtasks → one macrotask → render opportunity → repeat
- **Why `Promise.then` runs before `setTimeout(fn, 0)`:** microtasks are drained before the next macrotask
- **Render opportunity:** the browser gets a chance to render only between tasks — never mid-task
- **Long tasks freeze the UI:** any synchronous work > ~16ms blocks the render opportunity and causes frame drops

## Exercise
Without running it first, write down the exact console output order:

```javascript
console.log('1');

setTimeout(() => console.log('2'), 0);

Promise.resolve()
  .then(() => console.log('3'))
  .then(() => console.log('4'));

queueMicrotask(() => console.log('5'));

console.log('6');
```

Then verify in the browser console. Explain each step.

**Bonus:** add a `MutationObserver` callback and predict where it appears in the order.

## Mastery checkpoint
1. React 18 automatically batches state updates. In which queue does React schedule its re-render after calling `setState`?
2. Pre-React 18, wrapping a `setState` call inside `setTimeout(() => setState(...), 0)` would escape batching. Why? (Hint: when does React flush its batch?)
3. A user clicks a button rapidly 5 times. Each click dispatches a macrotask. How does React 18 ensure only the final state is rendered, rather than 5 intermediate renders?
