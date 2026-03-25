# React & UI Engineering: Master Study Guide

> **Student profile:** Mid-level backend engineer (Node.js, TypeScript, Rust, MongoDB). Strong in typed systems, functional patterns, and architecture. New to UI programming and the browser model.
> **Goal:** Job-ready React developer. Depth and correctness over speed.
> **Rule:** Complete each checkpoint before advancing to the next phase.

---

## PHASE 0 — UI & Browser Foundations

### Why this phase exists
React is an abstraction over the browser. If you do not understand what the browser is doing, React will feel like magic — and magic breaks in ways you cannot debug. Before writing a single JSX file, you need a working mental model of the platform React runs on. Think of it like understanding the OS scheduler before reasoning about async Rust.

---

### Topic 1 — How the Browser Renders a Page

**The why:** Every frame your browser displays is the result of a pipeline: parse HTML into a DOM tree, parse CSS into a CSSOM tree, combine them into a render tree, calculate layout (geometry), paint pixels, then composite layers. React's entire value proposition — the virtual DOM and reconciliation — is an optimization against this pipeline. You cannot understand why React batches updates or avoids unnecessary re-renders without knowing what a re-render actually costs at the browser level.

**Sub-skills to master:**
- Understand the critical rendering path: HTML → DOM, CSS → CSSOM, DOM + CSSOM → Render Tree
- Know what "layout" (reflow) means: computing position and size of every element
- Know what "paint" means: filling in pixels for a given geometry
- Know what "composite" means: assembling GPU layers into the final frame
- Understand which operations are cheap (composite-only: `transform`, `opacity`) vs expensive (layout-triggering: `width`, `height`, `top`, `left`)
- Understand what "blocking" means in the rendering pipeline — why a `<script>` in `<head>` without `defer` freezes rendering

**Exercise:** Open Chrome DevTools → Performance tab. Record a page load of any site. Identify the "Layout", "Paint", and "Composite Layers" events in the flame chart. Find at least one layout thrash (a JS read followed immediately by a write that forces synchronous layout).

**Mastery checkpoint:** Explain in writing: what is the difference between a repaint and a reflow? Give one concrete example of a CSS property change that causes a reflow and one that causes only a repaint. Why does React try to minimize DOM mutations?

---

### Topic 2 — The DOM and JavaScript Manipulation

**The why:** React's JSX compiles down to `React.createElement()` calls, which produce a virtual representation that React then syncs to the real DOM via `document.createElement`, `appendChild`, `setAttribute`, and friends. If you have never written raw DOM manipulation, you will not appreciate what React is automating — and you will struggle to reach outside React when you need to (e.g., integrating a third-party canvas library or managing focus imperatively).

**Sub-skills to master:**
- `document.querySelector`, `getElementById`, `getElementsByClassName`
- `createElement`, `appendChild`, `removeChild`, `insertBefore`, `replaceChild`
- Reading and writing attributes: `getAttribute`, `setAttribute`, `dataset`
- Reading and writing styles: `element.style.property` vs CSS classes
- Adding and removing event listeners: `addEventListener`, `removeEventListener`
- Event object: `target`, `currentTarget`, `preventDefault`, `stopPropagation`
- Understanding event bubbling and capturing phases

**Exercise:** Without any framework, build a dynamic todo list in a single HTML file. Use `createElement` to add items, `removeChild` to delete them, and event delegation on the parent `<ul>` (one listener, not one per item) to handle clicks.

**Mastery checkpoint:** What is event delegation and why is it a performance optimization? How does React's synthetic event system use this same technique under the hood?

---

### Topic 3 — Event Loop, Microtasks, Macrotasks

**The why:** React's state updates, effects, and async data fetching all operate within the JavaScript event loop. Stale closure bugs, batching behavior, and the timing of `useEffect` all make sense only if you have a precise mental model of how JS schedules work. As a Node.js engineer you have intuitions here — but the browser adds the rendering pipeline as a participant in the loop, which changes the picture.

**Sub-skills to master:**
- Call stack, heap, and the task queue (macrotask queue)
- What constitutes a macrotask: `setTimeout`, `setInterval`, I/O callbacks, UI events
- Microtask queue: Promises (`.then`), `queueMicrotask`, `MutationObserver`
- Execution order: current synchronous code → all microtasks → next macrotask → render → repeat
- Why `Promise.resolve().then(fn)` runs before `setTimeout(fn, 0)`
- How the browser gets a chance to render: only between tasks, never mid-task
- Why long synchronous tasks freeze the UI (blocking the render opportunity)

**Exercise:** Without running it first, predict the exact console output order of a code snippet mixing `setTimeout`, `Promise.resolve().then`, `queueMicrotask`, and synchronous `console.log`. Then verify in DevTools.

**Mastery checkpoint:** React 18 automatically batches state updates. In which queue does React schedule its re-render after `setState`? Why does wrapping an update in `setTimeout` historically escape batching (pre-React 18)?

---

### Topic 4 — CSS Layout: Box Model, Flexbox, Grid

**The why:** You will spend a significant fraction of your React career fighting layout bugs. Understanding CSS layout is not a "nice to have" — it is the foundation of every UI you build. Backend engineers typically underestimate this. Flexbox and Grid are the two layout systems you will use in 95% of React UIs. Knowing them deeply means you stop fighting the browser and start composing layouts intentionally.

**Sub-skills to master:**
- Box model: `content`, `padding`, `border`, `margin` — and `box-sizing: border-box` (use it everywhere)
- Block vs inline vs inline-block display behavior
- Flexbox: `display: flex`, `flex-direction`, `justify-content`, `align-items`, `align-self`, `flex-wrap`, `flex-grow`, `flex-shrink`, `flex-basis`, `gap`
- Grid: `display: grid`, `grid-template-columns`, `grid-template-rows`, `grid-column`, `grid-row`, `grid-area`, `gap`, `fr` unit, `auto-fill` vs `auto-fit`, `minmax()`
- When to use Flexbox (one-dimensional: row or column) vs Grid (two-dimensional)
- `position`: `static`, `relative`, `absolute`, `fixed`, `sticky` — and stacking context implications
- `overflow`, `z-index`, and why `z-index` only works on positioned elements

**Exercise:** Build three layouts from scratch using only HTML/CSS: (1) a navigation bar with logo left, links center, button right using Flexbox; (2) a 3-column card grid that collapses to 2 then 1 column using CSS Grid with `auto-fill`; (3) a sidebar layout where the sidebar is fixed width and the content fills the rest.

**Mastery checkpoint:** Without looking anything up, build a "holy grail" layout: sticky header, sticky footer, left sidebar (fixed width), right sidebar (fixed width), center content (fluid). Use CSS Grid. No JavaScript.

---

### Topic 5 — CSS Specificity, Cascade, Inheritance

**The why:** Styles breaking unexpectedly — a component's style being overridden by something unrelated, or a style applying where it shouldn't — is one of the most time-consuming debugging experiences in UI work. CSS Modules and utility-first CSS (Tailwind) exist precisely because specificity at scale is hard. You need to understand the underlying rules before you use tools that abstract them.

**Sub-skills to master:**
- Specificity scoring: inline styles (1,0,0,0) > IDs (0,1,0,0) > classes/attributes/pseudo-classes (0,0,1,0) > elements/pseudo-elements (0,0,0,1)
- The cascade: how the browser resolves conflicting declarations (origin, importance, specificity, source order)
- Inheritance: which properties inherit by default (mostly typographic) and which do not (mostly box model)
- `!important`: what it does, why it is a code smell, when it is occasionally justified
- The `:is()`, `:where()`, `:not()` pseudo-classes and their specificity behavior
- How to debug styles in DevTools: computed styles, overridden declarations, inherited values

**Exercise:** Given a broken stylesheet where a button's color is being overridden unexpectedly, use DevTools to identify the source of the conflict, explain the specificity calculation, and fix it without using `!important`.

**Mastery checkpoint:** You have a component library that styles `button.primary` with a certain color. A consuming page adds a style `#app button { color: red }` and overrides it. Explain why, calculate the specificity of both selectors, and propose two ways to fix it at the library level without touching the consumer.

---

### Topic 6 — Responsive Design

**The why:** Every React app you build will be used on screens ranging from 320px to 2560px wide. Mobile-first responsive design is not optional — it is table stakes. You need to think in fluid, relative units rather than fixed pixels, and understand how to restructure layouts at breakpoints. Tailwind's responsive modifiers (`sm:`, `md:`, `lg:`) are just CSS media queries with a systematic API — understanding the underlying mechanism makes you better at both.

**Sub-skills to master:**
- `em` (relative to parent font-size), `rem` (relative to root font-size), `vh`/`vw` (viewport), `%` (relative to parent) — when to use each
- Media queries: `@media (min-width: ...)`, mobile-first strategy (start with mobile styles, add breakpoints upward)
- `<meta name="viewport" content="width=device-width, initial-scale=1">` — why it is required
- Fluid typography: `clamp(min, preferred, max)` for type that scales without breakpoints
- Responsive images: `max-width: 100%`, `srcset`, `sizes`
- Testing responsive layouts: DevTools device toolbar, real device testing

**Exercise:** Take the card grid from Topic 4 and make it fully responsive: single column on mobile (< 640px), two columns on tablet (640–1024px), three columns on desktop (> 1024px). Use only CSS Grid with `auto-fill`/`minmax()` — no media queries needed for this one. Then add a media query for the sidebar that hides it on mobile.

**Mastery checkpoint:** Build a fully responsive two-column layout with a sticky header and a card grid using only HTML and CSS, zero frameworks. The header must stick to the top on scroll. The layout must collapse to a single column on mobile. Cards must have consistent height with content-aligned footers (use Flexbox inside each card).

---

## PHASE 1 — Modern JavaScript for React

### Why this phase exists
React code is dense with modern JavaScript patterns. Every React tutorial assumes you are already fluent with destructuring, spread operators, array methods, and closures. If you are not, you will constantly lose the thread of what is "React" vs "JavaScript." These patterns must be second nature — automatic — before you write your first component.

---

### Topic 1 — Destructuring

**The why:** Destructuring is everywhere in React. Props are destructured in every function component signature. useState returns an array you destructure. useReducer, useContext, custom hooks — all destructured. Reading React code fluently requires seeing through destructuring syntax instantly.

**Sub-skills to master:**
- Object destructuring: `const { a, b } = obj`
- Renaming during destructuring: `const { a: myA } = obj`
- Default values: `const { a = 'default' } = obj`
- Nested destructuring: `const { user: { name, address: { city } } } = data`
- Array destructuring: `const [first, second, ...rest] = arr`
- Function parameter destructuring: `function fn({ name, age = 0 }: Props) {}`
- Destructuring in loops: `for (const { id, label } of items)`

**Exercise:** Given a deeply nested API response object (user with profile, settings, and address), write a single destructuring expression that extracts: `userId` (renamed from `id`), `displayName` (from `profile.name`), `theme` (from `settings.theme`, defaulting to `'light'`), and `city` (from `address.city`).

**Mastery checkpoint:** Write a React-style function component signature for a component that receives `id`, `label`, `disabled` (optional, defaults to false), and `onClick` props — using TypeScript interface + destructured parameter in one expression.

---

### Topic 2 — Spread and Rest Operators

**The why:** React relies heavily on spread for immutable state updates (`{ ...prevState, field: newValue }`), for passing props forward (`<Component {...props} />`), and for merging objects without mutation. Misunderstanding spread — especially its shallow nature — is a source of subtle state bugs.

**Sub-skills to master:**
- Object spread: merging, overriding, shallow copy semantics
- Array spread: cloning, concatenating, inserting at index
- Rest in function parameters: `function fn(first, ...rest)`
- Rest in destructuring: `const { a, ...remaining } = obj`
- The shallow copy problem: spread does not deep clone nested objects
- Prop spreading in JSX: `<Input {...inputProps} />` — power and danger

**Exercise:** Given a state object `{ user: { name: 'Alice', address: { city: 'Paris' } }, theme: 'dark' }`, write the correct immutable update that changes only `city` to `'Lyon'` — without mutating the original and without losing any other fields. Then explain why a single spread would not be enough.

**Mastery checkpoint:** You have an array of todo objects. Write a pure function that returns a new array with the item at index `n` replaced by a new object — without mutating the original array.

---

### Topic 3 — Array Methods as UI Primitives

**The why:** In React, your UI is a function of your data. You do not imperatively add and remove DOM nodes — you transform data arrays into JSX arrays using `.map()`, `.filter()`, `.reduce()`. These are not optional advanced features; they are the primary way React UIs are built. Every list, every filtered view, every aggregated summary uses these.

**Sub-skills to master:**
- `.map(fn)` → transforms every element, returns new array of same length
- `.filter(predicate)` → returns new array of elements where predicate returns true
- `.reduce(fn, initial)` → accumulates a single value from an array
- `.find(predicate)` → returns first matching element or undefined
- `.findIndex(predicate)` → returns index of first match or -1
- `.some(predicate)` → returns true if any element matches
- `.every(predicate)` → returns true if all elements match
- `.flatMap(fn)` → map then flatten one level
- Chaining: `.filter().map().sort()`
- Immutability: none of these mutate the original array

**Exercise:** Given an array of 100 product objects with `{ id, name, price, category, inStock, rating }`, write a pipeline that: filters to in-stock items only, filters to a specific category passed as a parameter, sorts by rating descending, maps to a display object `{ id, label: name, formattedPrice: '$X.XX' }`, and returns both the display array and the total count of results.

**Mastery checkpoint:** Given a nested data structure — an array of departments, each with an array of employees — write a single expression using `.flatMap()` and `.reduce()` that produces a count of employees per job title across all departments.

---

### Topic 4 — ES Modules

**The why:** Every React file is an ES module. Every import of a component, hook, utility, or type uses ES module syntax. Understanding named vs default exports affects how you structure component files, how tree-shaking works, and how to avoid circular dependency bugs.

**Sub-skills to master:**
- Named exports: `export const fn = ...`, `export { a, b }`
- Default exports: `export default Component`
- Named imports: `import { fn, type MyType } from './module'`
- Default imports: `import Component from './Component'`
- Renaming imports: `import { fn as myFn } from './module'`
- Re-exports: `export { fn } from './module'` (barrel files / index.ts)
- Type-only imports in TypeScript: `import type { Foo } from './types'`
- Dynamic imports: `import('./module').then(m => m.default)` — used by React.lazy

**Exercise:** Create a small module structure with: a `types.ts` exporting interfaces, a `utils.ts` exporting named utility functions, a `Component.tsx` with a default export, and an `index.ts` barrel file that re-exports everything cleanly. Then explain the tradeoff of barrel files (convenience vs tree-shaking granularity).

**Mastery checkpoint:** What is the difference between `import React from 'react'` and `import * as React from 'react'`? When do you need each in a modern React TypeScript project with `"jsx": "react-jsx"` in tsconfig?

---

### Topic 5 — Template Literals and Tagged Templates

**The why:** Template literals appear constantly in React for dynamic class names, aria labels, error messages, and URL construction. Tagged templates are used by styled-components and other CSS-in-JS libraries — you need to recognize the pattern even if you do not write it often.

**Sub-skills to master:**
- Basic template literal: `` `Hello, ${name}!` ``
- Multiline strings
- Expressions inside `${}`: ternaries, function calls, arithmetic
- Tagged templates: `` fn`template ${expr}` `` — the function receives string parts and interpolated values
- Common use in styled-components: `` styled.div`color: ${props => props.color}` ``

**Exercise:** Write a utility function `buildApiUrl(base: string, path: string, params: Record<string, string>)` using template literals for path construction and `URLSearchParams` for query string encoding. Then write its tagged template equivalent.

---

### Topic 6 — Optional Chaining and Nullish Coalescing

**The why:** React components constantly receive data that may be `null` or `undefined` — data not yet loaded, optional props, API responses with missing fields. Optional chaining (`?.`) and nullish coalescing (`??`) are how you write safe, readable access expressions without verbose null checks. Every React codebase uses these constantly.

**Sub-skills to master:**
- `obj?.prop` — short-circuits to undefined if obj is null/undefined
- `obj?.method()` — only calls method if obj exists
- `arr?.[index]` — safe array access
- `??` vs `||` — the critical difference: `??` only short-circuits on null/undefined, not falsy values (`0`, `''`, `false`)
- Chaining: `user?.profile?.address?.city ?? 'Unknown'`

**Exercise:** Given an API response that may partially fail (some fields null, some missing entirely), write a function that safely extracts display data with sensible defaults — using `?.` and `??` throughout. Then show the bug that would occur if `||` were used instead of `??` for a numeric field that can legitimately be `0`.

---

### Topic 7 — Promises, async/await, Error Handling

**The why:** Every React data-fetching pattern involves Promises. `useEffect` with fetch, React Query's internals, form submission handlers — all async. You need precise error handling patterns, including the distinction between network errors and HTTP error responses, to build robust data-fetching components.

**Sub-skills to master:**
- Promise states: pending, fulfilled, rejected
- `.then()`, `.catch()`, `.finally()`
- `async/await` as syntactic sugar over Promises
- `try/catch/finally` with async/await
- `Promise.all()` — parallel, fails fast
- `Promise.allSettled()` — parallel, all results regardless of failure
- `Promise.race()`, `Promise.any()`
- The critical bug: `fetch()` does not reject on HTTP error status — you must check `response.ok`
- Returning early from async functions, typed return types `Promise<T>`

**Exercise:** Write a `fetchUser(id: string): Promise<User>` function that: handles network failure (rejects), handles HTTP 404 (throws a typed `NotFoundError`), handles HTTP 500 (throws a typed `ServerError`), and returns a properly typed `User` on success. Then write the call site with proper `try/catch` that handles each error type differently.

**Mastery checkpoint:** What is the difference between these two patterns, and when does it matter?
```typescript
// Pattern A
const [a, b] = await Promise.all([fetchA(), fetchB()]);

// Pattern B
const a = await fetchA();
const b = await fetchB();
```

---

### Topic 8 — Closures and Stale State

**The why:** The most common category of React bugs involves closures capturing stale values. A `useEffect` that closes over a state variable but does not list it in its dependency array will always see the value from the render it was created in — not the current value. Understanding closures precisely is the key to understanding this class of bugs, which trips up almost every developer moving to React hooks.

**Sub-skills to master:**
- What a closure is: a function that captures its surrounding lexical scope
- How closures interact with loop variables (classic `var` in `for` loop bug)
- How event handlers in React close over state values at render time
- The "stale closure" pattern: a callback that references a state value that has since changed
- How `useRef` is used to work around stale closures (storing a mutable ref to the latest value)
- How ESLint's `exhaustive-deps` rule helps catch these at compile time

**Exercise:** Write a counter component with a button that increments after a 3-second delay. First implement it with a stale closure bug (the count never advances past 1 after rapid clicks). Then fix it using the functional update form of `setState`. Explain why `setCount(count + 1)` is buggy but `setCount(c => c + 1)` is not.

**Mastery checkpoint:** In your own words, without code: why does a `useEffect` that does `setInterval` need to either include its state dependency in the dep array or use a ref? What goes wrong in each failure mode?

---

### Topic 9 — Immutability Patterns

**The why:** React's re-rendering system depends on reference equality checks. If you mutate state in place, React cannot detect that anything changed and will not re-render. This is not a best-practice suggestion — it is a correctness requirement. As a Rust developer you already think in terms of ownership and mutation; apply that discipline here.

**Sub-skills to master:**
- Never mutate: `arr.push()`, `arr.splice()`, `obj.field = value` on state objects
- Immutable array operations: spread + slice for insert/delete/replace
- Immutable object updates: `{ ...obj, field: newValue }`
- Deeply nested immutable updates (and why they become painful — motivation for Immer)
- Immer's `produce()` API: write mutating-looking code, get immutable output
- Structural sharing: immutable updates only copy changed paths, not entire trees
- `Object.freeze()` for development-time enforcement

**Exercise:** Given a state tree representing a kanban board (columns → cards → subtasks), write pure functions for: moving a card from one column to another, updating a subtask's completion status, and deleting a card — all without any mutation.

**Mastery checkpoint:** Given a raw data array of users with nested address objects, write pure functions (no mutation) to: filter active users, sort by city (without mutating the array), map to display-ready objects `{ fullName, cityLabel }`, and compute a summary `{ total, activeCount, cityCounts: Record<string, number> }`. TypeScript strict types required.

---

## PHASE 2 — React Core

### Why this phase exists
This is where React actually begins. Everything in Phases 0 and 1 was preparation. React's core model — declarative rendering, component composition, hooks — is simple but precise. Getting the mental models right here prevents an entire class of bugs and misunderstandings that plague developers who learn React by copying patterns without understanding them.

---

### Topic 1 — What React Actually Is

**The why:** React is not a framework — it is a library for building declarative UIs using a virtual DOM. Understanding the virtual DOM and reconciliation algorithm explains why React is fast, what its limitations are, and why the rules of hooks exist. Many developers use React for years without ever understanding reconciliation — and it shows in their code.

**Sub-skills to master:**
- Declarative vs imperative UI: you describe what the UI should look like given state, React figures out how to get there
- The virtual DOM: a lightweight JavaScript object tree that mirrors the real DOM
- Reconciliation: React diffs the previous virtual DOM with the new one after a render
- The diffing algorithm: same position + same type = update; different type = unmount + remount
- Why the `key` prop exists: helps React identify which list items changed, added, or removed
- React vs ReactDOM: the library vs the renderer (React Native uses a different renderer)
- React 18 concurrent features at a conceptual level: rendering can be interrupted and resumed

**Exercise:** Without writing any React code, draw a virtual DOM tree for a simple card list component. Then show what the diff would look like if you: (a) change a card's title, (b) remove the second card, (c) add a card at the top without keys vs with keys.

**Mastery checkpoint:** Why does React re-mount (destroy and recreate) a component when its position in the tree changes, even if it is the same component type? What are the consequences, and how do you work around it?

---

### Topic 2 — JSX

**The why:** JSX is not HTML. It is syntactic sugar that compiles to `React.createElement(type, props, ...children)` calls. Understanding this compilation output explains the rules (one root element, `className` not `class`, camelCase events), why you can use JSX in expressions, and what Fragments are really doing.

**Sub-skills to master:**
- JSX compiles to: `React.createElement('div', { className: 'foo' }, children)`
- With `react-jsx` transform (React 17+): `_jsx('div', { className: 'foo', children })` — no explicit React import needed
- Rules: single root element (or Fragment `<>...</>`), `className` not `class`, `htmlFor` not `for`
- All attributes are camelCase: `onClick`, `onChange`, `tabIndex`, `strokeWidth`
- Expressions in JSX: `{expression}` — any JS expression, but not statements
- Self-closing tags required for void elements: `<input />`, `<img />`
- Fragments: `<React.Fragment>` or `<>` — renders no DOM node, required for keys in lists
- JSX is not a string — it is a value you can store in variables, return from functions, pass as props

**Exercise:** Take this HTML snippet and convert it correctly to JSX, including all necessary attribute name changes, a dynamic class based on a boolean prop, a conditional child element, and a list rendered with `.map()` and proper keys.

**Mastery checkpoint:** What does this JSX compile to? Write the explicit `React.createElement` calls manually:
```jsx
<ul className="list">
  {items.map(item => (
    <li key={item.id}>{item.label}</li>
  ))}
</ul>
```

---

### Topic 3 — Components, Props, and TypeScript Interfaces

**The why:** Components are typed functions from props to UI. This framing — which comes naturally to a TypeScript backend engineer — is the right mental model. Props are the function's parameters: immutable, owned by the parent, typed. A component that respects its prop contract and produces predictable output from the same inputs is easy to test, reuse, and reason about.

**Sub-skills to master:**
- Function components: `function MyComponent(props: Props): JSX.Element`
- Props interface: define with `interface` (prefer for component APIs) or `type`
- Optional props: `label?: string` with a default value in destructuring
- `React.FC<Props>` vs plain function — prefer plain functions (FC has subtle issues with generics)
- `children` prop: type as `React.ReactNode` (broadest), `React.ReactElement` (specific), `React.PropsWithChildren<Props>`
- Readonly props: TypeScript interfaces for props are implicitly readonly by convention
- Prop forwarding: passing unknown/extra props through with `...rest`
- Composition over configuration: prefer `children` over `renderX` props for simple cases

**Exercise:** Build a `Card` component with typed props: `title`, `subtitle` (optional), `variant` (`'default' | 'highlighted' | 'danger'`), `children: React.ReactNode`, and an optional `footer: React.ReactNode`. TypeScript strict mode. No use of `any`.

---

### Topic 4 — Rendering: Conditional and Lists

**The why:** React rendering is just JavaScript. Conditional rendering uses `&&`, ternary, or early return — not special syntax. List rendering uses `.map()`. The `key` prop on list items is not optional; it is how React's diffing algorithm maintains identity across renders. Getting these patterns right is foundational to all React work.

**Sub-skills to master:**
- Conditional with `&&`: `{condition && <Component />}` — beware: `{0 && <X />}` renders `0`, use `{!!count && <X />}` or a ternary
- Ternary: `{condition ? <A /> : <B />}` — for two branches
- Early return: for complex conditions, return early from the component function
- Rendering null: returning `null` renders nothing and is valid
- List rendering: `{items.map(item => <Item key={item.id} {...item} />)}`
- Keys must be stable, unique among siblings — do NOT use array index as key unless the list is static and never reordered
- Fragment with key: `<React.Fragment key={id}>` for lists of multi-element groups

**Exercise:** Build a `StatusList` component that renders a list of status items. Each item has `{ id, label, status: 'active' | 'inactive' | 'pending' }`. Render a different icon/badge for each status. Show a message "No items" when the list is empty. Add a "show inactive" toggle that filters them out. All using the patterns above.

**Mastery checkpoint:** Why is using array index as a key dangerous when items can be reordered or deleted? Give a concrete example of the bug it causes (with input elements).

---

### Topic 5 — Events in React

**The why:** React's event system is a synthetic layer over native browser events. All events are attached to the root container via delegation (one listener for everything), then React dispatches synthetic event objects to your handlers. Understanding this explains why `event.nativeEvent` exists, why you rarely need `stopPropagation` in React, and how event handler prop patterns work.

**Sub-skills to master:**
- Synthetic events: same API as native events, but pooled and normalized across browsers
- Attaching handlers: `onClick={handleClick}` — pass the function reference, do not call it
- Common events: `onClick`, `onChange`, `onSubmit`, `onKeyDown`, `onFocus`, `onBlur`, `onMouseEnter`
- `onChange` in React fires on every keystroke (unlike native `change` which fires on blur) — intentional design
- TypeScript event types: `React.MouseEvent<HTMLButtonElement>`, `React.ChangeEvent<HTMLInputElement>`
- `event.preventDefault()` for forms, links
- Handler patterns: inline arrow, named handler, handler factory (returns a handler)
- Passing data to handlers: `onClick={() => handleClick(item.id)}` — create a new function in render (minor perf cost, usually fine)

**Exercise:** Build a form with a text input and a select dropdown. Log the typed value and the selected option to the console using properly typed `onChange` handlers. Prevent the form's default submit behavior and log the final values instead.

---

### Topic 6 — useState: The Snapshot Mental Model

**The why:** The single most important mental model in React hooks. State is not a live variable — it is a snapshot captured at the time of a render. When you call `setState`, you are not mutating the current value; you are scheduling a new render with a new snapshot. Misunderstanding this causes subtle bugs: stale reads inside callbacks, unexpected behavior when calling setState multiple times in sequence.

**Sub-skills to master:**
- `const [value, setValue] = useState<T>(initialValue)` — value is read-only within this render
- State is frozen per render: reading `value` inside an event handler gives you the value from the render that defined the handler
- Functional updates: `setValue(prev => prev + 1)` — use when the new value depends on the previous value
- React 18 automatic batching: multiple `setState` calls in the same event handler are batched into one render
- `useState` with objects: you must spread to create a new object — partial updates are not automatic
- Lazy initialization: `useState(() => expensiveComputation())` — runs once
- The state update is asynchronous: reading the state variable immediately after `setValue` still gives the old value

**Exercise:** Build a counter that has: increment, decrement, and reset buttons. Then add a "increment 3 times" button that calls `setValue` three times in a row. Observe the difference between `setValue(count + 1)` called three times vs `setValue(c => c + 1)` called three times. Explain why they produce different results.

**Mastery checkpoint:** If `count` is currently `5` and you call `setCount(count + 1)` three times synchronously, what is the new value and why? How do you fix it to get `8`?

---

### Topic 7 — useEffect: The Synchronization Model

**The why:** `useEffect` is the most misunderstood hook. The correct mental model is not "run code when something changes" — it is "keep this side effect synchronized with this state." The dependency array is a declaration of what the effect depends on, and React will re-run the effect when those dependencies change. Thinking of it as a lifecycle method (`componentDidMount`) leads to bugs. Thinking of it as a synchronization contract leads to correct code.

**Sub-skills to master:**
- `useEffect(fn, deps)` — runs after render when any dep has changed (by reference equality)
- No dependency array: runs after every render — almost always wrong
- Empty array `[]`: runs once after mount — correct only for true one-time setup
- With deps: `[userId]` — runs after mount and whenever `userId` changes
- Cleanup function: returned from the effect, runs before the next effect run and on unmount — critical for subscriptions, timers, abort controllers
- The ESLint `exhaustive-deps` rule: follow it, do not silence it without understanding why
- Common mistakes: missing deps causing stale closures; objects/functions as deps causing infinite loops (new reference every render)
- `useEffect` does NOT run on the server (SSR) — important for Next.js

**Exercise:** Build a component that fetches a user by ID (passed as a prop). Handle: loading state, error state, success state. Cancel the previous fetch when the ID changes (use `AbortController`). Clean up properly on unmount. This exercise touches every important `useEffect` concept.

**Mastery checkpoint:** You have `useEffect(() => { fetchData(query); }, [query])`. A new query prop arrives. In what order do these things happen: the component re-renders, the old effect's cleanup runs, the new effect runs? Now add a cleanup that cancels the fetch — where exactly does the cancellation occur?

---

### Topic 8 — useRef

**The why:** `useRef` serves two distinct purposes that share one API: (1) accessing a real DOM node imperatively, and (2) storing a mutable value that persists across renders without causing re-renders. Understanding both uses prevents you from either reaching for `useState` when you should use `ref` (causing unnecessary re-renders) or from using `ref` when you should use `state` (causing missed renders).

**Sub-skills to master:**
- `const ref = useRef<T>(initialValue)` — `ref.current` is mutable and not tracked by React
- Attaching to DOM: `<input ref={myRef} />` — `myRef.current` is the DOM node after mount
- Use cases: focusing an input, measuring an element's size, integrating with a non-React library
- Storing mutable values: storing the previous value, storing a timer ID, storing a callback for stale closure workaround
- Key rule: changing `ref.current` does NOT trigger a re-render
- `ref.current` is `null` on first render (before mount) — always check before use
- `useImperativeHandle` with `forwardRef` for exposing ref APIs from child components

**Exercise:** Build a search input that: (1) auto-focuses when a "Start searching" button is clicked using a ref, and (2) stores the timestamp of the last keystroke in a ref (without re-rendering) and displays "Typing stopped" 1 second after the last keystroke (using a debounce timer in a ref).

---

### Topic 9 — Component Composition

**The why:** React's composition model — building complex UIs by combining simpler components — is its core power. The `children` prop is how React achieves inversion of control: instead of configuring everything via props, you pass the thing you want rendered. Understanding composition patterns is the difference between building rigid, hard-to-reuse components and building flexible, combinable ones.

**Sub-skills to master:**
- `children` prop: rendering whatever the parent decides to put inside
- Lifting state up: moving state to the nearest common ancestor of components that need it
- Prop drilling: the problem that occurs when you lift state too high
- Component slots via named props: `header`, `footer`, `sidebar` as `React.ReactNode` props
- The `as` prop pattern: allowing the consumer to control the underlying HTML element
- Composition vs configuration: when to use `children` vs explicit props
- Component trees: thinking about your UI as a tree of components with clear data flow

**Exercise:** Build a `Layout` component that accepts `header`, `sidebar`, and `children` as separate props. Build a `Page` that uses it. Then build a `Dialog` component that accepts `title` and `children` — the parent controls the dialog's content entirely. Lift the open/closed state up to the parent.

---

### Topic 10 — Controlled vs Uncontrolled Components

**The why:** Forms are the most common source of confusion for React beginners. Controlled components — where React state is the single source of truth for every input value — are the React-idiomatic approach and make validation, formatting, and submission straightforward. Uncontrolled components use refs to access DOM values directly, which is simpler for simple cases but limits what you can do. You need to know both, know when to use each, and understand why React Hook Form uses uncontrolled inputs under the hood for performance.

**Sub-skills to master:**
- Controlled: `<input value={state} onChange={e => setState(e.target.value)} />` — React owns the value
- Uncontrolled: `<input ref={inputRef} />` — DOM owns the value, you read it via ref
- Why you need `onChange` with `value`: without it, the input becomes read-only
- `defaultValue` vs `value` — default value for uncontrolled, initial value for controlled
- Controlled checkboxes: `checked` + `onChange`
- Controlled selects: `value` on `<select>`, not on `<option>`
- `textarea`: in React, `value` prop controls content (not inner text as in HTML)
- When uncontrolled is appropriate: file inputs (always uncontrolled), high-frequency inputs where performance matters

**Mastery checkpoint:** Build a filterable, sortable data table component in TypeScript. Accept an array of objects via a generic `data: T[]` prop and a `columns: Column<T>[]` config. Render rows with `.map()`. Support a text filter (controlled input) that filters across all string fields. Support clicking a column header to sort (ascending/descending toggle). All state managed with `useState`. No external libraries.

---

## PHASE 3 — React State Architecture

### Why this phase exists
As components grow, `useState` scattered across a component tree becomes hard to reason about. This phase teaches you how to think about state: where it belongs, how to share it, and when to reach for more powerful tools. State architecture is the primary thing senior React developers get asked about in interviews.

---

### Topic 1 — Local vs Shared State

**The why:** The number one state management mistake is putting everything in a global store. The right default is to keep state as local as possible — inside the component that owns it. Only lift it when two components genuinely need to share it. Lifting too high causes unnecessary re-renders and tight coupling. This is the state colocation principle, and it is the first thing a senior engineer checks in a code review.

**Sub-skills to master:**
- Local state: state that only one component needs — keep it there
- Shared state: state needed by sibling components — lift to their nearest common ancestor
- The cost of lifting: every state change in a parent re-renders all its children
- "Pushing state down": if only one child needs a piece of state, move it there
- State vs derived state: if a value can be computed from existing state, do not store it — compute it
- The rule: the right place for state is the lowest component that can own it while satisfying all consumers

**Exercise:** Given a product page with a `ProductGallery` component and a `ProductInfo` component that both need to know the selected image index — identify where the state should live, lift it there, and pass it down. Then identify three values that should be derived (not stored) from that state.

---

### Topic 2 — useReducer

**The why:** When state logic becomes complex — multiple sub-values, transitions that depend on multiple pieces of current state, actions that can fail — `useReducer` brings the clarity of an explicit state machine. As a TypeScript engineer, you will appreciate how discriminated union action types make all valid transitions explicit and compiler-checked. `useReducer` is not just "Redux lite" — it is the right tool for any component with non-trivial state transitions.

**Sub-skills to master:**
- `const [state, dispatch] = useReducer(reducer, initialState)`
- Reducer function: `(state: State, action: Action) => State` — pure, returns new state
- Action types as discriminated unions: `type Action = { type: 'INCREMENT' } | { type: 'SET', payload: number }`
- `dispatch({ type: 'INCREMENT' })` — always returns void
- When to use over useState: multiple related pieces of state, next state depends on multiple current values, complex transition logic
- Reducers are pure functions: no side effects, no async, no mutations
- Combining with TypeScript: exhaustive switch statements for action types
- Initializer function: `useReducer(reducer, initialArg, init)` for lazy initialization

**Exercise:** Rewrite a multi-step form (personal info → address → confirmation) using `useReducer`. Model the steps as state, each field update as an action, forward/back navigation as actions, and submission as a final action. Type all actions as a discriminated union.

---

### Topic 3 — useContext

**The why:** Context solves prop drilling — the need to pass data through many layers of components that do not use it, just to get it to a deeply nested consumer. The canonical use cases are: current user, theme, locale. The critical warning is performance: any component that calls `useContext` re-renders whenever the context value changes, even if that component only uses part of the value. Misusing context as a global state store causes performance problems.

**Sub-skills to master:**
- `createContext<T>(defaultValue)` — the default is only used when there is no Provider above in the tree
- `<MyContext.Provider value={value}>` — wraps the subtree that can consume the context
- `const value = useContext(MyContext)` — subscribes the component to the context
- The re-render trap: context consumers re-render whenever the provider's `value` changes by reference
- Splitting contexts: separate frequently-changing state from rarely-changing state
- Context is not a replacement for a state management library — it is a dependency injection mechanism
- Pattern: pair context with `useReducer` for a lightweight Redux-like pattern

**Exercise:** Build a theme context that provides `{ theme: 'light' | 'dark', toggleTheme: () => void }`. Wrap the app in the provider. Consume it in a deeply nested component. Measure (with React DevTools) how many components re-render when the theme changes.

---

### Topic 4 — Custom Hooks

**The why:** Custom hooks are the primary mechanism for code reuse in React. They let you extract stateful logic — data fetching, form management, subscriptions, any behavior involving hooks — into a reusable function. This is a major interview topic because it reveals how well you understand the hooks model. A developer who writes custom hooks well writes much cleaner, more testable React code.

**Sub-skills to master:**
- Custom hook = any function starting with `use` that calls other hooks
- They can use `useState`, `useEffect`, `useRef`, `useCallback`, any hook
- They can accept arguments and return any value (state, functions, derived values)
- Rules of hooks still apply: only call at the top level, only call from React functions
- Testing: custom hooks are easily testable with `renderHook` from React Testing Library
- Common patterns: `useLocalStorage`, `useFetch`, `useDebounce`, `useWindowSize`, `useOnClickOutside`
- Return shape: either a tuple `[value, setter]` (like useState) or an object `{ data, loading, error }`

**Exercise:** Build `useDebounce<T>(value: T, delay: number): T` — a hook that returns a debounced version of any value. Then build `useLocalStorage<T>(key: string, initialValue: T): [T, (value: T) => void]` — a hook that syncs state to localStorage. Both must be fully typed with generics.

**Mastery checkpoint:** Refactor the Phase 2 data table to use `useReducer` for all state (filter text, sort column, sort direction). Extract that logic into a custom hook called `useTableState<T>`. Add a `useContext`-based theme toggle (light/dark) wrapping the whole app. The hook's public API should be typed and clean enough that a consumer never needs to dispatch actions directly.

---

### Topic 5 — State Colocation Principle

**The why:** This principle has a direct impact on performance and maintainability. State lives at the wrong level in most large React codebases — usually too high. When state is higher than it needs to be, more components re-render when it changes. When it is lower than it needs to be, you end up with prop drilling or sync bugs. The skill is developing an instinct for the right level.

**Sub-skills to master:**
- "As close to where it is used as possible" — the first question when adding state
- Recognizing when state is lifted too high (components re-rendering that do not use the state)
- Recognizing when state is too low (prop drilling required to share it)
- Dynamic children: components that render lists of items should often manage their own local state
- Server state vs client state: data from an API is different from UI state (expanded/collapsed, selected tab)

---

### Topic 6 — Derived State

**The why:** One of the most common React anti-patterns is syncing state to state — storing a value in `useState` that could be computed from another state value. This creates bugs: the derived copy can go out of sync, requires extra `useEffect` to keep it updated, and makes the state harder to reason about. The rule is simple: if you can compute it, do not store it.

**Sub-skills to master:**
- "Can I compute this from existing state?" — ask this before every `useState` call
- Computing during render: `const filtered = items.filter(...)` — this is free if not expensive
- `useMemo` for expensive derivations: `const sorted = useMemo(() => [...items].sort(...), [items])`
- The anti-pattern: `useEffect(() => setFiltered(items.filter(...)), [items, filter])` — unnecessary, just compute
- Props-derived state: do not copy props into state unless you explicitly need local override behavior

---

### Topic 7 — External State Management Overview

**The why:** When your application grows beyond what component state and context can handle cleanly — multiple routes sharing state, optimistic updates, complex async state machines — you need an external store. You do not need to master both Zustand and Redux Toolkit. You need to understand the problem they solve, when to reach for them, and the mental model of each.

**Sub-skills to master:**
- Signals vs atoms vs store: different mental models for external state
- Zustand: a small, un-opinionated store with a simple API — good for "global UI state" like user session, cart
- Redux Toolkit: the batteries-included Redux with `createSlice`, `createAsyncThunk` — good for complex, normalized server state in large apps
- The problem context alone cannot solve: context causes too many re-renders at scale; it lacks selectors
- Selectors: the pattern of reading only the slice of state a component needs — prevents unnecessary re-renders
- When to use: multiple unrelated components reading the same state, state that outlives any single route

---

## PHASE 4 — Component Design & UI Patterns

### Why this phase exists
Writing correct React is table stakes. Writing well-designed components — ones that are reusable, composable, and maintainable — is what separates junior from senior. These patterns appear in every component library, every production codebase, and every React interview.

---

### Topic 1 — Thinking in Components

**The why:** Breaking a UI mockup into components is a design skill that requires practice. The heuristic is the Single Responsibility Principle: each component should do one thing. But "one thing" is fuzzy — the skill is developing an intuition for the right granularity. Too coarse and components become hard to reuse; too fine and the component tree becomes a maze.

**Sub-skills to master:**
- The component decomposition process: identify repeated UI patterns, identify distinct responsibility boundaries
- Naming components: clear, noun-first names that describe what is rendered (`UserCard`, `FilterBar`, `PaginationControls`)
- Component boundaries: where does one component's responsibility end and another's begin?
- "Reuse" as a design criterion: would this chunk be useful in more than one place?
- Start coarse, refactor fine: begin with a few large components, extract only when pain arises

**Exercise:** Given a full-page mockup of a job listing page (search bar, filters sidebar, results list with cards, pagination), decompose it into a component tree on paper. Name every component, draw the parent-child relationships, and indicate which component owns each piece of state.

---

### Topic 2 — Presentational vs Container Components

**The why:** The "smart/dumb" or "container/presentational" pattern separates data fetching and business logic (container) from rendering (presentational). Presentational components are easy to test (pure functions of props), easy to use in Storybook, and reusable across different data sources. The pattern is less strict today with hooks, but the underlying principle — separating concerns — is still valuable.

**Sub-skills to master:**
- Presentational component: receives all data via props, emits events via callback props, has no data fetching, minimal state (only UI state)
- Container component: fetches data, manages state, passes data down to presentational components
- Why this matters: presentational components are independently testable and reusable
- How hooks blur this: custom hooks can extract the container logic out of components entirely
- When not to over-apply: not every component needs this split; apply where it buys you something

---

### Topic 3 — Render Props Pattern

**The why:** Render props were the primary code-reuse pattern before hooks. You will encounter them in older codebases and in some libraries (React Router's `<Route render={...}>`, Formik, Downshift). Understanding them helps you read existing code and understand why hooks replaced most of their use cases.

**Sub-skills to master:**
- The pattern: a component that accepts a function as a prop and calls it to render its output
- `children` as a function: `{children => <div>{children(data)}</div>}` — the most common form
- What problem it solved: sharing stateful logic without HOCs
- Why hooks mostly replaced it: hooks achieve the same reuse without JSX nesting overhead
- Where render props still appear: headless component libraries (Radix, Headless UI)

---

### Topic 4 — Higher-Order Components (HOC)

**The why:** HOCs are functions that take a component and return an enhanced component. `connect()` from React-Redux and `withRouter` are the canonical examples. Like render props, they predate hooks — but many libraries still use them, and understanding them is required to read legacy code.

**Sub-skills to master:**
- `const Enhanced = withAuth(Component)` — the HOC wraps and adds behavior
- Props proxying: the HOC passes through all original props, optionally injecting new ones
- Display name preservation for DevTools: `Enhanced.displayName = \`withAuth(\${Component.displayName})\``
- Composition of HOCs: `compose(withAuth, withTheme, withTracking)(Component)`
- The "wrapper hell" problem that render props and hooks solved
- TypeScript typing of HOCs: notoriously complex — another reason hooks are preferred

---

### Topic 5 — Compound Components Pattern

**The why:** The compound components pattern creates APIs that feel native — like `<select>` and `<option>`, or `<ul>` and `<li>`. Instead of passing complex configuration objects, consumers build up the component declaratively. This gives consumers full control over rendering while the parent component manages shared state. Libraries like Radix UI and Headless UI use this pattern extensively.

**Sub-skills to master:**
- The pattern: a parent component manages shared state; child components implicitly access it via context
- Implementation: parent provides state via context; children consume it
- API design: `<Tabs>`, `<Tabs.List>`, `<Tabs.Tab>`, `<Tabs.Panel>` — composed by the consumer
- Flexibility: consumers can add their own elements between compound components
- TypeScript: typing the subcomponents as static properties of the parent

**Exercise:** Build a compound `<Accordion>` component with `<Accordion.Item>`, `<Accordion.Trigger>`, and `<Accordion.Panel>` subcomponents. The parent manages which item is open. Consumers compose it freely.

---

### Topic 6 — Controlled Component Pattern for Reusable Inputs

**The why:** Building a reusable input component that plays well with any form library or state management approach requires understanding the controlled/uncontrolled duality. A well-designed form input exposes both `value`/`onChange` (for controlled use) and `defaultValue` (for uncontrolled use), just like native inputs.

**Sub-skills to master:**
- Accepting `value` and `onChange` as props to be controlled by the parent
- Accepting `defaultValue` for uncontrolled use
- Forwarding refs so the consumer can access the underlying DOM input
- Using `forwardRef` with TypeScript
- Exposing the right event types (`React.ChangeEvent<HTMLInputElement>` vs custom value types)

---

### Topic 7 — Error Boundaries

**The why:** JavaScript errors in rendering cause the entire React tree to unmount by default — showing the user a blank screen. Error boundaries are React's mechanism for catching these errors gracefully and displaying a fallback UI. Every production app needs them. They are one of the few remaining cases where you must write a class component.

**Sub-skills to master:**
- Error boundaries must be class components implementing `componentDidCatch` and `getDerivedStateFromError`
- Where to place them: at route boundaries (each page gets its own), around widgets that should fail independently
- Error boundary does NOT catch: async errors, event handler errors, server-side rendering errors — only render errors
- Using `react-error-boundary` library: the `ErrorBoundary` component with `fallback` prop — simplifies the class component requirement
- Resetting: providing a "try again" mechanism via `onReset` and `resetKeys`

---

### Topic 8 — Portals

**The why:** Modals, tooltips, and dropdowns need to render outside their parent DOM node — typically as a direct child of `document.body` — to avoid CSS overflow, z-index, and stacking context issues. React Portals let you render a React subtree into a different DOM node while maintaining the React context/event hierarchy.

**Sub-skills to master:**
- `ReactDOM.createPortal(children, domNode)` — renders children into domNode
- The React tree (events, context) is still intact even though the DOM placement is different
- Typical usage: modals, drawers, tooltips, dropdowns, toasts
- Creating the portal target: a `<div id="modal-root">` in index.html, or dynamically via `useEffect`
- Accessibility: the portal target should be after the main content in DOM order for screen readers

---

### Topic 9 — Accessibility Basics

**The why:** Accessibility is not optional — it is a legal requirement in many jurisdictions and a mark of professional quality. Interviewers frequently ask about it. React makes it easy to write accessible UIs if you use semantic HTML and ARIA correctly, but also easy to write inaccessible UIs if you use `<div>` and `<span>` for everything.

**Sub-skills to master:**
- Semantic HTML: use `<button>` for buttons, `<a>` for links, `<nav>`, `<main>`, `<header>`, `<footer>`, headings in order
- ARIA roles: `role="dialog"`, `role="alert"`, `role="status"` — only when semantic HTML is not sufficient
- ARIA labels: `aria-label`, `aria-labelledby`, `aria-describedby` — for context that is visual-only
- Keyboard navigation: every interactive element must be reachable and operable by keyboard
- Focus management: move focus to a modal when it opens, return focus to the trigger when it closes
- Focus trap: when a modal is open, Tab should cycle only within the modal
- Color contrast: WCAG AA requires 4.5:1 ratio for normal text
- Testing: `axe-core` / `jest-axe` for automated checks; keyboard and screen reader testing manually

**Mastery checkpoint:** Build a reusable `<Modal>` component using a portal. Requirements: (1) renders into a portal on `document.body`, (2) traps focus inside when open (Tab cycles through focusable elements within the modal), (3) closes on Escape key press, (4) exposes an `onClose` callback, (5) restores focus to the trigger element when closed, (6) has correct ARIA attributes (`role="dialog"`, `aria-modal`, `aria-labelledby`). Fully keyboard accessible.

---

## PHASE 5 — Performance

### Why this phase exists
React is fast by default for most applications. Performance optimization is only needed when you have a measured problem — never speculatively. This phase teaches you how to think about React's rendering model, how to measure where the real problems are, and which tool to reach for. The most important skill here is restraint: developers who prematurely optimize with `memo`, `useMemo`, and `useCallback` often make their code worse without making it faster.

---

### Topic 1 — React's Rendering Model

**The why:** Before optimizing, you must understand the exact conditions under which React re-renders a component. The rendering model is simple but has consequences that surprise many developers.

**Sub-skills to master:**
- Re-render triggers: `setState` called, `dispatch` called, parent re-renders (by default, all children re-render), context value changes
- Re-rendering ≠ DOM update: React renders (calls the function), then diffs the output, then updates only the changed DOM nodes
- Props do NOT determine re-renders by default: a child re-renders when its parent re-renders, even if its props did not change
- Shallow equality: `React.memo` compares props by shallow equality — same reference means skip
- Referential equality trap: `{}`, `[]`, and `() => {}` are always new references on each render

---

### Topic 2 — React.memo

**The why:** `React.memo` wraps a component to prevent re-rendering when its props are shallowly equal to the previous render's props. It is the right tool when a component is expensive to render AND its parent re-renders frequently AND its props rarely change. Used incorrectly, it costs memory and comparison time for no benefit.

**Sub-skills to master:**
- `export default React.memo(MyComponent)` — wraps the component
- Shallow equality check: primitive values compared by value, objects/arrays/functions compared by reference
- Custom comparator: second argument to `React.memo(Component, (prev, next) => areEqual)` — rarely needed
- When it helps: pure display components that receive stable primitive props
- When it does NOT help: if the parent always passes new object/array/function references, `memo` will always fail the check

---

### Topic 3 — useMemo

**The why:** `useMemo` memoizes the result of an expensive computation, recalculating only when its dependencies change. The critical word is "expensive" — computing a filtered array of 10 items is not expensive, and wrapping it in `useMemo` adds overhead without benefit. Use it when you have a measured performance problem, not speculatively.

**Sub-skills to master:**
- `const result = useMemo(() => expensiveComputation(a, b), [a, b])`
- Cached across renders until a dependency changes
- Also used to stabilize object/array references: `useMemo(() => ({ x, y }), [x, y])` prevents child re-renders when parent re-renders
- Measurement first: profile with DevTools before adding `useMemo`
- Does not prevent re-renders on its own — only `React.memo` prevents component re-renders

---

### Topic 4 — useCallback

**The why:** `useCallback` memoizes a function reference, returning the same function instance across renders as long as its dependencies do not change. This is primarily useful for passing stable function references to memoized child components — if the child is wrapped in `React.memo` and one of its props is a function, that function must be stable or memo will always fail.

**Sub-skills to master:**
- `const fn = useCallback(() => doSomething(a), [a])` — same reference until `a` changes
- Only useful in combination with `React.memo` (or as deps in `useEffect`/`useMemo`)
- Without `React.memo` on the child, `useCallback` does nothing for rendering performance
- Overuse anti-pattern: wrapping every event handler in `useCallback` adds cost with no benefit

---

### Topic 5 — Code Splitting with React.lazy and Suspense

**The why:** Every JavaScript file you import ends up in your bundle. If you import every page of your app in the root file, users download all of it on first load — even pages they never visit. Code splitting loads route-level code on demand. React.lazy and Suspense are the built-in mechanism.

**Sub-skills to master:**
- `const LazyPage = React.lazy(() => import('./pages/LazyPage'))`
- `<Suspense fallback={<LoadingSpinner />}><LazyPage /></Suspense>` — fallback renders while the chunk loads
- Route-level splitting: one lazy import per route — the most impactful level to split
- Preloading: calling `import('./page')` early to start the download before the user navigates
- Bundle analysis: `vite-bundle-visualizer` or `webpack-bundle-analyzer` to see what is in each chunk

---

### Topic 6 — List Virtualization

**The why:** Rendering a list of 10,000 rows creates 10,000 DOM nodes — even if only 20 are visible. The browser must lay out and paint all of them. Virtualization renders only the visible rows (plus a small buffer), dramatically reducing DOM size. This is the correct solution for large lists; `React.memo` alone does not solve this problem.

**Sub-skills to master:**
- The problem: DOM node count directly impacts layout and paint performance
- The solution concept: only render visible items, position them with absolute/transform to simulate full-list height
- `react-window` (lightweight) and `react-virtual` / `@tanstack/react-virtual` (flexible) — know the API of at least one
- Fixed vs variable height rows: fixed height is faster; variable height requires measurement
- Overscan: rendering a few extra rows beyond the viewport to prevent blank flashes on scroll

---

### Topic 7 — React DevTools Profiler

**The why:** The React DevTools Profiler is your primary instrument for React performance work. Before optimizing anything, record a profile, identify which components are re-rendering, why they are re-rendering, and how long each render takes. Optimization without measurement is guesswork.

**Sub-skills to master:**
- Install React DevTools browser extension
- Record a profile: click Record, interact with the app, stop recording
- Flame chart: shows the render time of each component in a commit
- Ranked chart: shows components sorted by render time — find the most expensive
- Why did this render? The profiler shows the prop/state/context that changed to trigger a render
- Commit list: each bar is one React render commit — spiky bars are frame drops

---

### Topic 8 — Key Prop Misuse as a Performance Bug

**The why:** Using array index as a `key` on a list that can be reordered, filtered, or have items added/removed causes React to incorrectly reuse component instances. This causes state to bleed between items and prevents React from optimizing removals. Using a random or unstable key (e.g., `key={Math.random()}`) causes React to unmount and remount every item on every render — a severe performance regression.

**Sub-skills to master:**
- Stable, unique keys: `id` from your data is the right key
- The index-as-key bug: when items are reordered, React associates the wrong state with the wrong item
- The random-key bug: `key={Math.random()}` means every render is a full unmount/remount of the list
- Using key intentionally to reset state: `<Component key={userId} />` — changing the key unmounts and remounts, resetting all state. This is a feature, not a bug, when used intentionally.

**Mastery checkpoint:** Take the Phase 3 data table. Add 10,000 rows of mock data. Profile it with React DevTools. Identify the specific bottleneck (is it the filtering? the sort? the render of each row?). Apply the correct optimization — explain why each choice was made. If row rendering is the bottleneck, apply `React.memo`. If the list is too long to render, apply virtualization. Write a paragraph explaining your diagnosis and decision.

---

## PHASE 6 — Routing & Data Fetching

### Why this phase exists
Real applications have multiple pages and need server data. React Router is the standard routing solution. React Query is the industry-standard data-fetching library — it solves problems that `useEffect`-based fetching creates (race conditions, cache staleness, loading/error states, refetching). Mastering these two libraries means you can build complete, production-quality applications.

---

### Topic 1 — React Router v6

**The why:** React Router v6 introduced a significant API redesign from v5. The new API is more declarative, with nested routes as a first-class concept. Most production React applications use React Router, and fluency with it is expected in React job interviews.

**Sub-skills to master:**
- `<BrowserRouter>` wrapping the app
- `<Routes>` and `<Route path="..." element={<Component />} />`
- `<Link to="...">` and `<NavLink to="...">` (adds active class)
- `useNavigate()` — programmatic navigation: `navigate('/path')`, `navigate(-1)` for back
- `useParams()` — read URL params: `const { id } = useParams()`
- `useSearchParams()` — read/write query string: `const [params, setParams] = useSearchParams()`
- Index routes: the default child route rendered when no other child matches
- `<Outlet />` — where nested route children render inside a layout component

---

### Topic 2 — Nested Routes and Layout Routes

**The why:** Nested routes allow a parent route to render a persistent layout (sidebar, navigation) while child routes render their content inside it via `<Outlet />`. This eliminates repetitive layout code across every page component and enables loading states at the layout level.

**Sub-skills to master:**
- Defining nested routes: a parent Route with children Routes
- The layout component: renders `<Outlet />` where the child route's element should appear
- Shared layouts: a single `AppLayout` component wrapping all authenticated routes
- URL nesting: `/dashboard/settings` matches a `settings` Route nested inside a `dashboard` Route
- Multiple levels of nesting

---

### Topic 3 — Protected Routes

**The why:** Almost every real application has pages that require authentication. The protected route pattern wraps routes with a guard that checks auth state and redirects to login if unauthenticated. This is a pattern, not a library feature — you implement it yourself.

**Sub-skills to master:**
- A `ProtectedRoute` component that reads auth state and either renders `<Outlet />` or `<Navigate to="/login" />`
- Preserving the intended destination: `<Navigate to="/login" state={{ from: location }} replace />`
- Reading the destination after login: `navigate(location.state?.from ?? '/')`
- Role-based protection: extending the pattern to check user roles

---

### Topic 4 — Data Fetching Patterns and the Problems with useEffect

**The why:** Fetching data in `useEffect` seems simple but introduces subtle problems at scale: race conditions when props change faster than responses arrive, no deduplication of identical requests, no caching (every component mount triggers a new fetch), no built-in retry logic. Understanding these problems motivates React Query.

**Sub-skills to master:**
- Basic `useEffect` fetch: `fetch()` → set loading, data, error state
- The race condition bug: a fast second request resolves before a slow first request, leaving stale data
- Fixing with AbortController: cancel the previous request on re-run
- The waterfall problem: sequential effects cause latency; parallel fetches are better
- Why this is hard to do correctly at scale — the case for a data-fetching library

---

### Topic 5 — React Query (TanStack Query)

**The why:** React Query is the industry-standard solution for server state management in React. It provides: automatic caching, background refetching, deduplication, loading/error/success states, pagination, optimistic updates, and cache invalidation — all with minimal boilerplate. Once you use it, writing data fetching in `useEffect` feels like assembling furniture without instructions.

**Sub-skills to master:**
- Install and setup: `QueryClient`, `QueryClientProvider`
- `useQuery({ queryKey: ['users'], queryFn: fetchUsers })` — returns `{ data, isLoading, isError, error }`
- Query keys: arrays like `['user', id]` — used for caching, deduplication, and invalidation
- `useMutation({ mutationFn: createUser })` — returns `{ mutate, isPending, isError }`
- Cache invalidation: `queryClient.invalidateQueries({ queryKey: ['users'] })` — triggers refetch
- Stale-while-revalidate: serve cached data immediately while fetching fresh data in the background
- `staleTime` vs `gcTime` (formerly `cacheTime`): staleTime controls when data is considered outdated; gcTime controls when it is removed from cache
- Optimistic updates: `onMutate` to update cache immediately, `onError` to roll back
- Dependent queries: `useQuery({ ..., enabled: !!userId })` — only fetch when userId exists

---

### Topic 6 — Optimistic Updates

**The why:** For a snappy UX, you want the UI to reflect a mutation immediately — before the server responds. If the server rejects it, you roll back. React Query makes this straightforward with `onMutate`, `onSuccess`, and `onError` callbacks.

**Sub-skills to master:**
- `onMutate`: called before the request fires — update the cache immediately
- Save previous cache state in `onMutate` context for rollback
- `onError`: called on failure — restore the previous cache state
- `onSettled`: called regardless of success/failure — a good place to invalidate and refetch for consistency

---

### Topic 7 — React Hook Form

**The why:** Building forms with controlled `useState` inputs is fine for simple cases. For complex forms with validation, dynamic fields, and performance requirements, React Hook Form is the standard. It uses uncontrolled inputs (refs) under the hood, meaning form state does not cause re-renders on every keystroke — a significant performance advantage for large forms.

**Sub-skills to master:**
- `useForm<FormData>()` — returns `{ register, handleSubmit, formState, watch, setValue, reset }`
- `{...register('fieldName', validationRules)}` — spreads ref and event handlers onto the input
- `handleSubmit(onValid, onInvalid)` — wraps your submit handler; only calls `onValid` if all fields are valid
- `formState.errors` — access validation errors for each field
- Validation rules: `required`, `minLength`, `maxLength`, `pattern`, `validate` (custom function)
- Schema validation with Zod: `zodResolver(schema)` as the `resolver` option
- Controlled inputs with React Hook Form: `<Controller>` component for custom inputs
- `watch('field')` — subscribe to a field's current value (use sparingly — triggers re-renders)

**Mastery checkpoint:** Build a mini CRUD app. Requirements: (1) list page fetches items with `useQuery`; (2) clicking an item navigates to a detail route via React Router; (3) a form page creates/edits items with React Hook Form + Zod validation + React Query `useMutation`; (4) successful create/edit invalidates the list query and navigates back; (5) all routes are protected behind a mock auth check with redirect to `/login`.

---

## PHASE 7 — Styling Systems

### Why this phase exists
Styling is a first-class concern in UI engineering. How you write CSS at scale — scoping, theming, consistency — directly affects maintainability. This phase covers the progression from raw CSS to the tool choices you will encounter in production codebases, with particular focus on Tailwind CSS, which has become the dominant styling approach in new React projects.

---

### Topic 1 — CSS Modules

**The why:** CSS Modules solve the global scope problem of plain CSS by generating unique class names at build time, ensuring styles are scoped to the component that imports them. This was the dominant React styling approach before Tailwind. You will encounter it in many codebases.

**Sub-skills to master:**
- `import styles from './Component.module.css'`
- `<div className={styles.container}>` — the class name is automatically scoped
- Composing classes: `className={[styles.base, isActive && styles.active].filter(Boolean).join(' ')}`
- The `clsx` / `classnames` utility for cleaner conditional class composition
- Global styles: `:global(.className)` inside a module, or a separate `global.css`

---

### Topic 2 — Tailwind CSS

**The why:** Tailwind is the most popular styling approach in new React projects. Its utility-first model — composing styles from small, single-purpose classes — eliminates the need to name things, prevents CSS from growing unboundedly, and makes the responsive/dark mode design system systematic. The learning curve is the class name vocabulary; the mental model is straightforward once you internalize it.

**Sub-skills to master:**
- The utility-first mental model: every class does one thing (`flex`, `p-4`, `text-lg`, `bg-blue-500`)
- Responsive modifiers: `sm:flex-row`, `md:grid-cols-2`, `lg:hidden` — all mobile-first
- State modifiers: `hover:bg-blue-600`, `focus:ring-2`, `disabled:opacity-50`, `active:scale-95`
- Dark mode: `dark:bg-gray-900`, `dark:text-white` — with `class` or `media` strategy
- `tailwind.config.js`: extending the theme, custom colors, custom spacing, custom breakpoints
- `@apply` in CSS files: extracting repeated utility combinations into a semantic class — use sparingly
- The `cn()` utility pattern with `clsx` + `tailwind-merge` for conditional class application without conflicts
- Arbitrary values: `w-[347px]`, `bg-[#1a2b3c]` — escape hatches for one-off values

---

### Topic 3 — CSS-in-JS Overview

**The why:** CSS-in-JS libraries (styled-components, Emotion) allow you to write CSS inside JavaScript files, with full access to props and themes. They have excellent DX but come with a runtime cost — styles are generated and injected at runtime, adding to JS bundle size and execution time. Modern applications increasingly move away from runtime CSS-in-JS for this reason. Understand the tradeoff.

**Sub-skills to master:**
- styled-components API: `` styled.div`css rules here` ``
- Dynamic styles via props: `` styled.div`color: ${p => p.primary ? 'blue' : 'black'}` ``
- Theming with `ThemeProvider`
- The runtime cost: styles are computed and injected during render
- Zero-runtime alternatives: Linaria, vanilla-extract — CSS-in-JS at build time, no runtime cost
- When to use: when theme-based dynamic styles and colocated component styles are the priority

---

### Topic 4 — Design Tokens

**The why:** A design token is a named design decision: `color-brand-500`, `spacing-4`, `font-size-lg`. Using a consistent token system means your UI has visual rhythm and consistency — components feel like they belong together. Tailwind's design system is essentially a set of design tokens with a systematic scale.

**Sub-skills to master:**
- Spacing scale: 4px base unit, powers of 2 (4, 8, 16, 24, 32, 48, 64)
- Color system: primary, neutral, semantic (success, warning, error), with light/dark variants
- Typography scale: a limited set of sizes, weights, and line heights — not arbitrary pixel values
- CSS custom properties (`--color-brand-500: #3b82f6`) as a token implementation
- Why consistency matters: visual rhythm is perceived, even if not consciously noticed

---

### Topic 5 — Component Library Consumption

**The why:** Most React projects use a component library as their foundation. Understanding how to consume, compose, and extend headless/primitive libraries (Radix UI, Headless UI) gives you unstyled, accessible building blocks to apply your own design system to. shadcn/ui combines Radix primitives with Tailwind and is the most popular approach in 2024–2025.

**Sub-skills to master:**
- Radix UI primitives: unstyled, fully accessible, composable — you bring the styles
- shadcn/ui: a collection of copy-paste components built on Radix + Tailwind — you own the code
- The copy-paste model vs dependency model: shadcn gives you source, not a package to upgrade
- Extending primitive components: wrapping Radix components with your design system's styles
- Theming with CSS custom properties: how shadcn/ui implements its theme system

---

### Topic 6 — Building Consistent UI Without a Designer

**The why:** As a developer working without a designer, you need a systematic approach to visual design. This is not about being a designer — it is about following rules that produce consistent, professional-looking UIs without aesthetic decisions on every element.

**Sub-skills to master:**
- 8px spacing grid: use multiples of 8 for all spacing decisions
- Typography hierarchy: one display size, one heading size, body, small — do not use more
- Color contrast: use a checker to ensure WCAG AA compliance
- Alignment and grouping: related items are closer together (Gestalt proximity)
- Whitespace as a design element: generous padding reads as premium; cramped padding reads as cheap

**Mastery checkpoint:** Re-implement the Phase 6 CRUD app UI with Tailwind CSS. Requirements: consistent spacing (8px grid), responsive (mobile-first, functional on all screen sizes), dark mode support (toggle button, `dark:` variants), professional typographic hierarchy, no default-browser-ugly styling anywhere.

---

## PHASE 8 — TypeScript in React (Deepened)

### Why this phase exists
You are already a TypeScript engineer. This phase is not about TypeScript fundamentals — it is about the specific patterns and challenges that arise when combining TypeScript with React's component model: generic components, event types, discriminated unions for variants, forwardRef, and the common pitfalls that lead developers to reach for `any`.

---

### Topic 1 — Typing Props

**The why:** A well-typed component's props interface is its contract. It documents what the component expects, makes misuse a compiler error, and enables IDE autocomplete. Getting prop typing right — especially optional props, children, and callback types — is foundational.

**Sub-skills to master:**
- `interface Props` vs `type Props` — prefer `interface` for component props (extensible), `type` for unions and computed types
- Optional props with defaults: `{ label?: string }` with `= 'Default'` in destructuring
- `children` typing: `React.ReactNode` (most permissive), `React.ReactElement` (only React elements), `string`, or specific component types
- Callback props: `onClose: () => void`, `onSelect: (id: string) => void`
- `React.ComponentProps<'div'>` — extending native element props: `interface Props extends React.ComponentProps<'div'> { ... }`
- `React.CSSProperties` for inline style objects

---

### Topic 2 — Typing useState, useRef, useReducer

**The why:** TypeScript can often infer the type from the initial value — but for cases where the initial value is `null` or an empty array, explicit typing is required. Getting these right prevents a category of runtime errors and removes unnecessary null checks.

**Sub-skills to master:**
- `useState<User | null>(null)` — explicitly type the union when initial value is null
- `useState<string[]>([])` — type the array element when initial is empty
- `useRef<HTMLInputElement>(null)` — type the DOM node; `current` is `HTMLInputElement | null`
- `useRef<number>(0)` — type mutable refs; `current` is `number` (not null, since you initialize with a value)
- `useReducer<Reducer<State, Action>>(reducer, initialState)` — explicit typing for complex state

---

### Topic 3 — Typing Event Handlers

**The why:** React's synthetic events are generic over the element type. Using the correct event type gives you access to the right properties on `event.target` — for example, `event.target.value` is only available on `React.ChangeEvent<HTMLInputElement>`, not on a generic `Event`.

**Sub-skills to master:**
- `React.ChangeEvent<HTMLInputElement>` — for text input onChange
- `React.ChangeEvent<HTMLSelectElement>` — for select onChange
- `React.MouseEvent<HTMLButtonElement>` — for button onClick
- `React.FormEvent<HTMLFormElement>` — for form onSubmit
- `React.KeyboardEvent<HTMLInputElement>` — for keyboard events
- Typing inline handlers: `onClick={(e: React.MouseEvent<HTMLButtonElement>) => ...}`
- Naming standalone handlers: `const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => ...`

---

### Topic 4 — Typing Custom Hooks

**The why:** A custom hook's return type is its public API. TypeScript can usually infer it, but explicit return types prevent accidental API changes and document intent. Generic hooks need explicit type parameters to be properly reusable.

**Sub-skills to master:**
- Return type inference vs explicit annotation: `function useCount(): [number, () => void]`
- Tuple return types: annotate as `const` assertions or explicit tuple type to prevent widening to `(number | (() => void))[]`
- Generic hooks: `function useLocalStorage<T>(key: string, initial: T): [T, (v: T) => void]`
- Overload signatures for hooks with multiple calling signatures

---

### Topic 5 — Generic Components

**The why:** Generic components — components parameterized by a type variable — eliminate duplication for patterns like `<List>`, `<Table>`, `<Select>`, or `<Combobox>`. Instead of writing a separate component for each data type, you write one that works with all of them while preserving type safety throughout.

**Sub-skills to master:**
- `function List<T>({ items, renderItem }: { items: T[]; renderItem: (item: T) => React.ReactNode })`
- Generic constraints: `function List<T extends { id: string }>(...)`
- The `extends` trick in arrow functions: `<T extends unknown>(...)` to disambiguate `<T>` from JSX in `.tsx` files
- Generic components with `forwardRef` — the most complex TypeScript in React

---

### Topic 6 — Discriminated Unions for Component Variants

**The why:** Components often have mutually exclusive variants — a Button that is either `primary`, `secondary`, or `danger`. More powerfully, a component might have props that only make sense together: if `variant="icon"`, then `icon` is required; otherwise it is not. Discriminated unions model this perfectly.

**Sub-skills to master:**
- Union of interfaces: `type ButtonProps = PrimaryProps | DangerProps | GhostProps`
- Discriminant field: `variant: 'primary' | 'danger' | 'ghost'` shared across all branches
- Exhaustive narrowing: `switch (props.variant)` with TypeScript enforcing all branches are handled
- Conditional required props: `type A = { variant: 'icon'; icon: IconName } | { variant: 'text'; children: string }`

---

### Topic 7 — forwardRef with TypeScript

**The why:** `forwardRef` is needed when a parent component needs to access a child's DOM node via a ref. The TypeScript typing is non-obvious and is a common source of confusion. With React 19, `ref` is a regular prop — but you need to understand the forwardRef pattern for all pre-19 codebases.

**Sub-skills to master:**
- `React.forwardRef<HTMLInputElement, Props>((props, ref) => <input ref={ref} {...props} />)`
- The two type parameters: first is the ref type (the DOM element or component instance), second is the props type
- Exporting: `export const Input = React.forwardRef<HTMLInputElement, Props>(...)` and the type inference

---

### Topic 8 — Common TypeScript Pitfalls

**The why:** TypeScript is easy to misuse in ways that technically compile but defeat the purpose — `as` casts everywhere, `any` creeping in, type assertions instead of type narrowing. These patterns make the codebase harder to trust.

**Sub-skills to master:**
- `as` casting: a sign that you are outsmarting the compiler — usually indicates a design problem
- `any`: avoid entirely; use `unknown` and narrow instead
- Type narrowing: `typeof`, `instanceof`, `in` operator, type guards (`function isUser(x: unknown): x is User`)
- Non-null assertion `!`: only use when you are certain and can explain why
- `strict: true` in tsconfig: enables `noImplicitAny`, `strictNullChecks`, `strictFunctionTypes` — always use it

**Mastery checkpoint:** Rewrite the Phase 6 CRUD app with strict TypeScript. Zero `any`. All props explicitly typed. All hooks typed. Event handlers typed. Generic components where applicable. The compiler must pass with `"strict": true` in tsconfig.

---

## PHASE 9 — Testing

### Why this phase exists
Tested code is deployable code. In React, testing means testing behavior — what the user sees and can do — not implementation details (which hooks are called, which state variables hold which values). The testing philosophy in this phase is the Kent C. Dodds approach: test your components the way users use them.

---

### Topic 1 — Testing Philosophy

**The why:** The most common React testing mistake is testing implementation details — asserting that a specific function was called, that a state variable has a specific value, or that a specific component was rendered. These tests break when you refactor and provide false confidence. The right tests assert on observable behavior: text is visible, buttons are clickable, forms submit.

**Sub-skills to master:**
- "Test behavior, not implementation" — assert on what the user sees and does
- The Testing Trophy: most tests should be integration tests (component + hooks together), some unit tests (pure functions), few E2E tests
- What NOT to test: internal state, specific function calls, component structure details
- Testing accessibility by default: querying by role and label forces you to write accessible components
- Confidence vs coverage: 100% coverage with bad tests gives false confidence; fewer well-designed tests are better

---

### Topic 2 — Vitest or Jest Setup

**The why:** You need a test runner to run tests. Vitest is the modern choice for Vite-based projects (same config, much faster). Jest is the legacy standard still widely used.

**Sub-skills to master:**
- Vitest config in `vite.config.ts`: `test: { environment: 'jsdom', globals: true }`
- `jsdom` environment: simulates a browser DOM for React component testing
- `@testing-library/jest-dom` matchers: `toBeInTheDocument`, `toHaveValue`, `toBeDisabled`, `toHaveClass`
- Setup file: `setupTests.ts` importing `@testing-library/jest-dom`
- Running tests: `vitest`, `vitest --watch`, `vitest --coverage`

---

### Topic 3 — React Testing Library

**The why:** React Testing Library (RTL) is the standard for React component testing. Its philosophy: render a component into a real DOM (via jsdom), interact with it as a user would, and assert on what the user sees. It deliberately makes it difficult to access internals, nudging you toward behavior-based tests.

**Sub-skills to master:**
- `render(<Component />)` — renders into jsdom
- `screen` object: `screen.getByRole`, `screen.getByText`, `screen.getByLabelText`, `screen.queryByText`, `screen.findByRole`
- `userEvent` from `@testing-library/user-event`: simulates real user interactions — `userEvent.click`, `userEvent.type`, `userEvent.selectOptions`
- Prefer `userEvent` over `fireEvent`: userEvent triggers the full browser interaction chain (mousedown, mouseup, click, focus, etc.)
- `within(element)`: scope queries to a subtree — for finding elements inside a specific container

---

### Topic 4 — Querying by Role, Label, Text

**The why:** RTL's query priority deliberately pushes you toward accessible queries. `getByRole` finds elements by their ARIA role, which is how screen readers find them too. If you can't find your element by role, you probably need to add an aria-label — which makes the component more accessible.

**Sub-skills to master:**
- `getByRole('button', { name: 'Submit' })` — find by role and accessible name
- `getByLabelText('Email')` — find an input by its associated label
- `getByText('Hello world')` — find by visible text content
- `getByPlaceholderText('Search...')` — last resort for inputs without labels
- `getByTestId('my-id')` — only when nothing else works (avoid over-reliance)
- `queryBy*` vs `getBy*` vs `findBy*`: query returns null (use for asserting absence), get throws if not found (use for asserting presence), find returns a Promise (use for async)

---

### Topic 5 — Testing Async Behavior

**The why:** Data fetching, loading states, and delayed UI updates require async testing patterns. Getting these wrong leads to flaky tests or tests that pass before the assertion is ready.

**Sub-skills to master:**
- `findBy*` queries: `await screen.findByText('Loaded')` — waits for the element to appear
- `waitFor(() => assertion)` — retries the assertion until it passes or times out
- `act()`: React requires state updates to be wrapped in `act` — RTL and userEvent handle this automatically, but manual state updates in tests need it
- Mocking fetch: `vi.fn()` or `msw` (Mock Service Worker) for intercepting HTTP requests at the network level
- Async `userEvent`: `await userEvent.click(button)` — the setup method requires `await`

---

### Topic 6 — Mocking

**The why:** Tests should be isolated from external systems — network, localStorage, browser APIs. Mocking replaces real implementations with controlled fakes that you can inspect and configure per test.

**Sub-skills to master:**
- `vi.mock('./module')` — replace an entire module with auto-mocked version
- `vi.fn()` — create a mock function that records calls
- `vi.spyOn(object, 'method')` — spy on (and optionally mock) an existing method
- Mock Service Worker (MSW): intercepts `fetch` calls at the Service Worker level — the most realistic way to mock APIs
- Mocking React Query: wrapping tests in `QueryClientProvider` with a fresh `QueryClient`
- `vi.useFakeTimers()` and `vi.runAllTimers()` — for testing debounce, setTimeout behavior

---

### Topic 7 — Integration vs Unit Tests

**The why:** Component integration tests render a component with all its hooks and verify the full behavior from render to user interaction to state update. Unit tests test pure functions in isolation. Both have a place, but integration tests provide more confidence for UI code.

**Sub-skills to master:**
- Integration test: render `<FilterableList data={mockData} />`, type in the filter input, assert filtered rows are visible
- Unit test: test a `formatCurrency(amount, locale)` utility function — no React involved
- When to unit test: pure utility functions, complex reducers, custom hooks (via `renderHook`)
- `renderHook(() => useMyHook())` from RTL — test a hook's behavior without a wrapping component

**Mastery checkpoint:** Write a full test suite for the Phase 6 CRUD app. Tests must cover: (1) the list renders all items on load; (2) the text filter correctly shows/hides items; (3) clicking an item navigates to the detail route; (4) the form submission calls the mutation with the correct data; (5) error states display an error message to the user. Use MSW to mock the API.

---

## PHASE 10 — Real-World Readiness

### Why this phase exists
The gap between "I can build a React app" and "I can work on a production React codebase at a professional level" is mostly about context: project structure conventions, build tooling, Next.js, CI/CD, code review, and interview performance. This phase closes that gap.

---

### Topic 1 — Project Structure Conventions

**The why:** You will be dropped into an existing codebase from day one. Understanding common folder conventions — and the reasoning behind each — lets you navigate quickly and contribute without breaking conventions.

**Sub-skills to master:**
- Feature-based structure: `src/features/auth/`, `src/features/products/` — each feature owns its components, hooks, API calls, and types
- Layer-based structure: `src/components/`, `src/hooks/`, `src/api/`, `src/types/` — organized by technical role
- Feature-based is preferred for large apps; layer-based for small apps
- Colocation: tests, stories, and styles live next to the component they belong to
- Barrel files: `index.ts` per folder for cleaner imports — understand the tree-shaking tradeoff
- Naming conventions: `PascalCase` for components, `camelCase` for hooks and utilities, `SCREAMING_SNAKE_CASE` for constants

---

### Topic 2 — Environment Variables in Vite / Next.js

**The why:** API keys, base URLs, and feature flags are configured via environment variables. Mishandling them — committing secrets, using the wrong prefix — is a common mistake.

**Sub-skills to master:**
- Vite: variables must be prefixed `VITE_` to be exposed to the client: `VITE_API_URL`
- Access in code: `import.meta.env.VITE_API_URL`
- Next.js: `NEXT_PUBLIC_` prefix for client-side, unprefixed for server-only
- `.env`, `.env.local`, `.env.production` — file loading priority
- Never commit `.env.local` — add to `.gitignore`
- TypeScript: extend `ImportMetaEnv` interface to type your env variables

---

### Topic 3 — Next.js Fundamentals

**The why:** Next.js is the most widely used React framework for production applications. Its file-system routing, server rendering capabilities, and deployment model are things you will encounter in almost every React job.

**Sub-skills to master:**
- Pages Router vs App Router: App Router is the modern standard (React Server Components)
- File-system routing: `app/page.tsx` → `/`, `app/users/[id]/page.tsx` → `/users/:id`
- Server Components vs Client Components: server components render on the server, have no interactivity, can access databases directly; client components (`'use client'`) have hooks and event handlers
- The default is Server Component — you opt into client with `'use client'`
- Rendering strategies: SSR (per request), SSG (at build time), ISR (revalidate after N seconds)
- Data fetching in Server Components: `async` components with `fetch()` (extended with caching options)
- `useRouter`, `usePathname`, `useSearchParams` — client-side navigation hooks
- `next/image`: automatic optimization, lazy loading, size hints
- `next/font`: self-hosted, zero layout shift font loading

---

### Topic 4 — CI/CD Basics for a React App

**The why:** A React job means working in a team with a deployment pipeline. You need to understand what runs in CI, why each step exists, and how to keep the pipeline green.

**Sub-skills to master:**
- Typical pipeline steps: `lint` (ESLint) → `typecheck` (tsc --noEmit) → `test` (vitest) → `build` (vite build)
- GitHub Actions: `.github/workflows/ci.yml` with a `push`/`pull_request` trigger
- Why the pipeline runs before merge: catch errors before they hit main
- Environment variables in CI: set as repository secrets, not in the workflow file
- Build output: Vite produces `dist/`, Next.js produces `.next/` — deployed to a CDN or serverless functions
- Preview deployments: Vercel/Netlify create a unique URL for every PR — test before merging

---

### Topic 5 — Code Review Literacy

**The why:** Reading and writing good PR comments is a professional skill. You need to give feedback that is specific, actionable, and respectful — and you need to receive feedback without defensiveness.

**Sub-skills to master:**
- What to look for in a React PR: missing cleanup in useEffect, index keys, unhandled loading/error states, missing accessibility attributes, over-engineering
- Comment types: blocking (must fix), non-blocking (suggestion), nitpick (style, mark as nit)
- Writing feedback: "This could cause a memory leak if the component unmounts before the promise resolves — consider using AbortController in the cleanup" — specific, explains the why, suggests the fix
- Responding to feedback: "Fixed in latest commit" with a description of what changed
- Approving thoughtfully: approve means you are confident the code is correct and maintainable

---

### Topic 6 — Interview Preparation

**The why:** Knowing React and performing well in a React interview are related but different skills. Interviews test your ability to explain concepts clearly, reason about problems you have not seen before, and write code under observation. Preparation is practice, not luck.

**The 10 most common React interview questions (with depth required):**

1. **What is the virtual DOM and how does reconciliation work?** — Describe the diffing algorithm, the role of keys, and what triggers a re-render.
2. **What are React hooks and why were they introduced?** — Explain the problems class components had (logic reuse, wrapper hell, complex lifecycle methods) and how hooks solve them.
3. **Explain the rules of hooks.** — Only call at top level, only call from React functions. Explain WHY: React tracks hook call order, and conditional/loop hooks would break that tracking.
4. **What is the difference between useEffect and useLayoutEffect?** — useEffect runs asynchronously after paint; useLayoutEffect runs synchronously after DOM mutation but before paint. Use useLayoutEffect for DOM measurements.
5. **How do you optimize a slow React application?** — Describe the measurement-first approach (Profiler), then the tools: React.memo, useMemo, useCallback, code splitting, virtualization. Emphasize profiling before optimizing.
6. **What is prop drilling and how do you solve it?** — Describe the problem, then give the solutions in order of preference: component composition, context, external state manager. Explain when each is appropriate.
7. **Explain the useCallback hook.** — Function reference stabilization. Only useful with React.memo on the child. Explain why it does nothing on its own.
8. **What is the difference between controlled and uncontrolled components?** — State ownership. When to use each. Why React Hook Form uses uncontrolled.
9. **How does React Context work and what are its performance implications?** — Provider/consumer model, all consumers re-render on any value change, context splitting as mitigation.
10. **What happens when you call setState?** — Schedules a re-render with a new state snapshot. Does not mutate current state. Updates are batched in React 18. The component function re-executes with the new state values.

---

### Topic 7 — Live Coding Practice

**The why:** Live coding under observation is a distinct skill from coding alone. You must vocalize your thinking, handle interruptions, and produce working code faster than your normal pace. The only way to get better is practice.

**Sub-skills to master:**
- Read the requirements aloud and ask clarifying questions before writing a line
- Start with the data model (types), then the component structure, then the behavior
- Vocalize your reasoning: "I'm using useCallback here because this will be passed to a memoized child"
- Handle hints gracefully: "That's a good point, let me adjust..."
- Finish something working rather than nothing perfect

**Mastery checkpoint:** Take any real open-source React project on GitHub (Next.js, Cal.com, Plane, or similar). Read the codebase for 2 hours. Write a structured document covering: (1) how state is managed and at what levels; (2) what data-fetching pattern is used and why; (3) how routing is structured; (4) what the folder/module organization strategy is; (5) one specific thing you would improve and a concrete technical proposal for how.

---

## Quick Reference: Phase Checkpoints

| Phase | Checkpoint Summary |
|-------|-------------------|
| 0 | Responsive two-column layout, sticky header, card grid — HTML/CSS only |
| 1 | Pure TypeScript functions: filter, sort, map, reduce on nested user data — no mutation |
| 2 | Filterable, sortable data table — TypeScript, useState, controlled inputs, no libraries |
| 3 | Refactor table with useReducer + useTableState hook + useContext theme toggle |
| 4 | Accessible modal with portal, focus trap, Escape key, aria attributes |
| 5 | Profile 10,000-row table, identify bottleneck, apply correct optimization, explain choices |
| 6 | Mini CRUD app: React Query + React Router + React Hook Form + protected routes |
| 7 | Re-implement Phase 6 UI with Tailwind, responsive, dark mode, professional quality |
| 8 | Strict TypeScript rewrite: zero any, all hooks typed, generic components, strict: true |
| 9 | Full test suite for Phase 6 app: render, filter, navigation, mutation, error states |
| 10 | OSS codebase analysis: state management, data fetching, routing, folder structure, one improvement |
