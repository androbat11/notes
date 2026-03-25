# useState: The Snapshot Mental Model

> Phase 2 | Topic 6

## Why this matters
State is not a live variable — it is a **snapshot** captured at the time of a render. When you call `setState`, you are not mutating the current value; you are scheduling a new render with a new snapshot. Misunderstanding this causes the most common React bugs: stale reads inside callbacks, unexpected behavior when calling setState multiple times.

## Sub-skills to master
```typescript
// Basic usage
const [count, setCount] = useState(0);
const [user, setUser] = useState<User | null>(null);
const [items, setItems] = useState<string[]>([]);

// State is read-only within the current render — count is frozen
// Calling setCount does NOT change count in this render, it schedules the next one
setCount(count + 1);
console.log(count); // still the old value!

// Functional update — use when new value depends on previous value
setCount(prev => prev + 1);  // always correct, reads the latest committed state

// Why functional updates matter (multiple calls in one event handler)
// These three lines all read count = 5, all schedule count = 6 — not 8
setCount(count + 1);
setCount(count + 1);
setCount(count + 1); // result: 6, not 8

// Functional updates correctly stack
setCount(c => c + 1); // 5 → 6
setCount(c => c + 1); // 6 → 7
setCount(c => c + 1); // 7 → 8

// Object state — must spread (partial update is not automatic)
const [form, setForm] = useState({ name: '', email: '' });
setForm({ ...form, name: 'Alice' }); // correct
setForm({ name: 'Alice' });          // WRONG: loses email field

// Lazy initialization — function runs only once
const [data, setData] = useState(() => JSON.parse(localStorage.getItem('data') ?? '{}'));

// React 18 automatic batching: multiple setState calls in same event = one re-render
function handleClick() {
  setA(1);   // ─┐
  setB(2);   //  ├─ one re-render (batched)
  setC(3);   // ─┘
}
```

## Exercise
**Part 1:** Build a counter with:
- Display showing current count
- "Increment", "Decrement", "Reset" buttons
- An "Increment 3×" button

Implement "Increment 3×" first with `setCount(count + 1)` called three times. Observe it only adds 1.
Then fix it with `setCount(c => c + 1)` called three times. Observe it correctly adds 3.

**Part 2:** Build a profile form with fields `name`, `email`, `bio` stored in a single state object:
```typescript
const [form, setForm] = useState({ name: '', email: '', bio: '' });
```
Each input has its own `onChange` handler. Implement a helper `updateField(field, value)` that updates one field without losing others. No controlled input should reset the other fields when any input changes.

## Mastery checkpoint
1. `count` is currently `5`. You call `setCount(count + 1)` three times synchronously. What is the resulting value? Why?
2. How do you fix the above to get `8`?
3. Immediately after calling `setCount(10)`, you `console.log(count)`. What does it print and why?
4. Why is `useState(() => expensiveFunction())` better than `useState(expensiveFunction())` when the initial value is expensive to compute?
