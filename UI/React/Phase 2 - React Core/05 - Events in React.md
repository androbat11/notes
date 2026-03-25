# Events in React

> Phase 2 | Topic 5

## Why this matters
React's event system is a synthetic layer over native browser events. All events are delegated to the root container — React then dispatches synthetic event objects to your handlers. Understanding this explains how event handler props work, why you pass a function reference (not a call), and the TypeScript types for each event.

## Sub-skills to master
```typescript
// Pass the function reference — do NOT call it
<button onClick={handleClick}>    // correct
<button onClick={handleClick()}>  // WRONG: calls on every render, passes return value

// Inline arrow function — creates a new function each render (usually fine)
<button onClick={() => handleDelete(item.id)}>

// Typed handler
function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
  setValue(e.target.value);
}

// Common event types
React.MouseEvent<HTMLButtonElement>     // onClick, onMouseEnter, etc.
React.ChangeEvent<HTMLInputElement>     // onChange on input
React.ChangeEvent<HTMLSelectElement>    // onChange on select
React.ChangeEvent<HTMLTextAreaElement>  // onChange on textarea
React.FormEvent<HTMLFormElement>        // onSubmit
React.KeyboardEvent<HTMLInputElement>   // onKeyDown, onKeyUp
React.FocusEvent<HTMLInputElement>      // onFocus, onBlur
React.DragEvent<HTMLDivElement>         // onDragStart, onDrop

// Preventing default behavior
function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
  e.preventDefault(); // stops page reload
  // process form data
}

// event.target vs event.currentTarget
// target: the element that was actually clicked
// currentTarget: the element the handler is attached to
// In a delegated handler on a parent: target is the child, currentTarget is the parent

// onChange fires on every keystroke in React (unlike native which fires on blur)
<input onChange={e => setValue(e.target.value)} value={value} />
```

## Exercise
Build a form with:
1. A text input for a username (controlled)
2. A select dropdown for a role (`'admin' | 'editor' | 'viewer'`)
3. A textarea for a bio
4. A submit button

Requirements:
- All inputs are controlled (value + onChange)
- `onChange` handlers must be properly typed
- `onSubmit` prevents default and logs `{ username, role, bio }`
- The submit button is disabled if `username` is empty
- Pressing Enter in the username field should NOT submit the form (use `onKeyDown` to prevent it)

## Mastery checkpoint
1. Why does `<button onClick={handleClick()}>` not work as intended? What does it do instead?
2. A parent `<ul>` has a click handler. A user clicks a `<button>` inside a `<li>`. What are `event.target` and `event.currentTarget` respectively?
3. In native HTML, the `change` event on an input fires when the input **loses focus**. In React, `onChange` fires on every **keystroke**. Why does React change this behavior, and what does it enable?
4. You need to call `handleClick(item.id)` when a button is clicked. Write two ways to do this and note the performance difference between them.
