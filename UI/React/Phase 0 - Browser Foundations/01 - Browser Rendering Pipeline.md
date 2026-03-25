# Browser Rendering Pipeline

> Phase 0 | Topic 1

## Why this matters
React's virtual DOM and reconciliation are optimizations against the browser's rendering pipeline. You cannot understand why React batches updates, avoids unnecessary re-renders, or why certain CSS properties are cheap vs expensive without knowing what the browser does on every frame.

## Sub-skills to master
- **Critical rendering path:** HTML → DOM, CSS → CSSOM, DOM + CSSOM → Render Tree → Layout → Paint → Composite
- **Layout (reflow):** computing the position and size of every element — expensive
- **Paint:** filling in pixels for a given geometry
- **Composite:** assembling GPU-accelerated layers into the final frame
- **Cheap vs expensive CSS:** `transform` and `opacity` are composite-only (cheap); changing `width`, `height`, `top`, `left` triggers layout (expensive)
- **Render-blocking resources:** a `<script>` in `<head>` without `defer` pauses HTML parsing and blocks the first render
- **Layout thrashing:** reading a layout property (e.g. `offsetHeight`) immediately after a DOM write forces a synchronous layout

## Exercise
Open Chrome DevTools → Performance tab. Record a page load of any site. In the flame chart:
1. Identify at least one **Layout** event and one **Paint** event
2. Find a **layout thrash**: a JS read (`getBoundingClientRect`, `offsetWidth`) immediately after a DOM write — look for "Forced reflow" warnings
3. Note how long the Layout event takes vs the Paint event

## Mastery checkpoint
Answer in writing:
1. What is the difference between a **repaint** and a **reflow**? Give one CSS property change that causes each.
2. Why does React try to minimize direct DOM mutations? Connect your answer to the rendering pipeline.
3. Why is animating `transform: translateX()` smoother than animating `left`?
