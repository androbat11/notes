# What React Actually Is

> Phase 2 | Topic 1

## Why this matters
React is a library for building declarative UIs using a virtual DOM. Understanding the virtual DOM and reconciliation algorithm explains why React is fast, what its limitations are, and why the rules of hooks exist. Many developers use React for years without understanding reconciliation — and it shows in their bugs.

## Sub-skills to master

### Declarative vs Imperative
- **Imperative (raw DOM):** you describe *how* to get to the new state step by step — `createElement`, `appendChild`, `removeChild`
- **Declarative (React):** you describe *what the UI should look like* given the current state — React figures out the *how*

### Virtual DOM and Reconciliation
- React maintains a **virtual DOM**: a lightweight JS object tree mirroring the real DOM
- On every render, React produces a new virtual DOM tree
- React **diffs** the new tree against the previous one (reconciliation)
- Only the differences are applied to the real DOM — minimizing expensive DOM operations

### The Diffing Algorithm (key rules)
- **Same position + same type = update:** React reuses the existing DOM node and updates its properties
- **Same position + different type = unmount + remount:** React destroys the old node and creates a new one (all child state is lost)
- **Lists:** without keys, React diffs by index — with keys, React matches by key identity (much more accurate)

### Why keys matter
```jsx
// Without keys — React matches by index, confuses items when list changes
<ul>{items.map(item => <li>{item.name}</li>)}</ul>

// With keys — React correctly identifies each item
<ul>{items.map(item => <li key={item.id}>{item.name}</li>)}</ul>
```

### React vs ReactDOM
- `react` — the library (components, hooks, JSX)
- `react-dom` — the renderer that talks to the browser DOM
- `react-native` — a different renderer that talks to native mobile APIs
- The same React component code can theoretically run on any renderer

## Exercise
Without writing any React code, draw (on paper or in a text diagram) the virtual DOM tree for:
```jsx
<div className="app">
  <header><h1>Title</h1></header>
  <ul>
    {['Alice', 'Bob', 'Charlie'].map(name => <li key={name}>{name}</li>)}
  </ul>
</div>
```

Then show what the diff looks like when:
1. `'Bob'` changes to `'Robert'`
2. `'Bob'` is removed from the list — without keys vs with keys
3. `'Dave'` is inserted at the beginning — without keys vs with keys

## Mastery checkpoint
1. Why does React unmount and remount a component when its **position** in the tree changes, even if it is the same component type? What state is lost?
2. What is the practical consequence of putting different component types at the same position (e.g., toggling between `<Input />` and `<Select />`)?
3. How is intentionally changing the `key` prop used to **force** a component reset — and when is this useful?
