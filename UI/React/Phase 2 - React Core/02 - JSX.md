# JSX

> Phase 2 | Topic 2

## Why this matters
JSX is not HTML. It is syntactic sugar that compiles to function calls. Understanding the compilation output explains the rules, why you can use JSX in expressions, what Fragments are really doing, and helps you debug JSX errors meaningfully.

## Sub-skills to master

### What JSX compiles to
```jsx
// This JSX:
<button className="btn" onClick={handleClick}>Click me</button>

// Compiles to (classic transform):
React.createElement('button', { className: 'btn', onClick: handleClick }, 'Click me')

// Compiles to (modern react-jsx transform, React 17+):
import { jsx as _jsx } from 'react/jsx-runtime';
_jsx('button', { className: 'btn', onClick: handleClick, children: 'Click me' })
// No explicit `import React` needed with the new transform
```

### Rules
| HTML | JSX |
|---|---|
| `class="foo"` | `className="foo"` |
| `for="id"` | `htmlFor="id"` |
| `<br>` | `<br />` (self-closing required) |
| `onclick="..."` | `onClick={fn}` (camelCase, function ref) |
| Multiple root elements allowed | Must have a single root element (or Fragment) |
| `<!-- comment -->` | `{/* comment */}` |

### Fragments
```jsx
// When you need to return multiple elements without a wrapping div:
return (
  <>
    <h1>Title</h1>
    <p>Paragraph</p>
  </>
);

// Fragment with key (for lists):
items.map(item => (
  <React.Fragment key={item.id}>
    <dt>{item.term}</dt>
    <dd>{item.definition}</dd>
  </React.Fragment>
))
```

### JSX is an expression
```jsx
// Store in a variable
const header = <h1>Title</h1>;

// Return from a function
const renderBadge = (count: number) => count > 0 ? <span>{count}</span> : null;

// Pass as a prop
<Modal title={<span className="bold">Alert</span>} />

// Spread attributes
const inputProps = { type: 'text', placeholder: 'Search' };
<input {...inputProps} className="search-input" />
```

### Expression pitfall
```jsx
// This renders the number 0 — a common bug!
{items.length && <List items={items} />}  // ← renders "0" when empty

// Fix: use boolean coercion or ternary
{items.length > 0 && <List items={items} />}
{!!items.length && <List items={items} />}
{items.length ? <List items={items} /> : null}
```

## Exercise
Convert this HTML to correct JSX. It contains: multiple elements (needs Fragment or wrapper), wrong attribute names, a conditional element, a dynamic class, a list with keys, and an event handler.

```html
<form class="form" onsubmit="handleSubmit()">
  <label for="email">Email</label>
  <input id="email" type="email" class="input" />
  <!-- Show error only when invalid -->
  <span class="error active">Invalid email</span>
  <ul class="tag-list">
    <li>React</li>
    <li>TypeScript</li>
  </ul>
  <button type="submit" disabled>Submit</button>
</form>
```

## Mastery checkpoint
Write the explicit `React.createElement` calls for this JSX (without using JSX syntax at all):
```jsx
<ul className="list">
  {items.map(item => (
    <li key={item.id} className={item.done ? 'done' : ''}>
      {item.label}
    </li>
  ))}
</ul>
```
