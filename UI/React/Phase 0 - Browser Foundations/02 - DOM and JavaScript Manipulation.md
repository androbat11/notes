# DOM and JavaScript Manipulation

> Phase 0 | Topic 2

## Why this matters
React's JSX compiles down to `React.createElement()` calls, which React then syncs to the real DOM via `document.createElement`, `appendChild`, `setAttribute`. If you have never written raw DOM manipulation, you will not appreciate what React is automating — and you will struggle to step outside React when you need to (integrating a canvas library, managing focus imperatively, working with third-party widgets).

## Sub-skills to master
- **Querying:** `document.querySelector`, `getElementById`, `querySelectorAll`
- **Creating/inserting:** `createElement`, `appendChild`, `insertBefore`, `replaceChild`, `removeChild`
- **Reading/writing attributes:** `getAttribute`, `setAttribute`, `removeAttribute`, `element.dataset`
- **Reading/writing styles:** `element.style.property` vs toggling CSS classes via `classList`
- **Event listeners:** `addEventListener(type, handler)`, `removeEventListener(type, handler)` — always save a reference to remove it
- **Event object:** `event.target` (element that triggered), `event.currentTarget` (element listener is on), `preventDefault()`, `stopPropagation()`
- **Event bubbling:** events propagate from target → up through ancestors → document
- **Event delegation:** attach one listener on a parent, check `event.target` to identify which child triggered it

## Exercise
In a single HTML file (no framework), build a dynamic todo list:
1. An input + button to add items — use `createElement` and `appendChild`
2. Each item has a delete button — use `removeChild`
3. Use **event delegation**: attach a single `click` listener on the `<ul>`, not one per item
4. When clicking delete, identify the item via `event.target.closest('[data-id]')` and remove it

```html
<!DOCTYPE html>
<html>
<body>
  <input id="input" type="text" placeholder="New todo" />
  <button id="add">Add</button>
  <ul id="list"></ul>
  <script>
    // Your implementation here
  </script>
</body>
</html>
```

## Mastery checkpoint
1. What is **event delegation** and why is it a performance optimization over adding one listener per list item?
2. React attaches all event listeners to the root container (`#root`) rather than individual elements. What pattern from raw DOM programming is this?
3. When would you need to call `removeEventListener`, and what is the common mistake that makes it fail?
