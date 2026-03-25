# Responsive Design

> Phase 0 | Topic 6 | Phase Checkpoint

## Why this matters
Every React app runs on screens from 320px to 2560px wide. Mobile-first responsive design is not optional. Tailwind's `sm:`, `md:`, `lg:` modifiers are just CSS media queries with a systematic API — understanding the underlying mechanism makes you better at both.

## Sub-skills to master

### Units
| Unit | Relative to | Best for |
|---|---|---|
| `px` | nothing (absolute) | borders, shadows, min-widths |
| `rem` | root font-size (usually 16px) | font sizes, spacing — scales with user preferences |
| `em` | parent font-size | component-level spacing that should scale with the component's own font |
| `%` | parent dimension | fluid widths, positioning |
| `vw` / `vh` | viewport width / height | full-screen sections, hero elements |
| `svh` | small viewport height | mobile-safe full-screen (excludes browser chrome) |

### Mobile-first media queries
```css
/* Base: mobile styles (no query needed) */
.container { flex-direction: column; }

/* Tablet and up */
@media (min-width: 640px) { .container { flex-direction: row; } }

/* Desktop and up */
@media (min-width: 1024px) { .container { max-width: 1200px; } }
```
**Mobile-first = start with the smallest screen, add complexity upward.**

### Viewport meta tag (required)
```html
<meta name="viewport" content="width=device-width, initial-scale=1">
```
Without this, mobile browsers render at desktop width and scale down — your media queries won't work.

### Fluid typography
```css
/* Scales from 1rem at 320px to 1.5rem at 1200px — no breakpoints needed */
font-size: clamp(1rem, 0.5rem + 1.5vw, 1.5rem);
```

### Responsive images
```css
img { max-width: 100%; height: auto; }
```

## Exercise
Take the card grid from Topic 4 and:
1. Make it **single column on mobile** (< 640px), **two columns on tablet** (640–1024px), **three columns on desktop** (> 1024px) — use media queries
2. Try the same result **without media queries** using: `grid-template-columns: repeat(auto-fill, minmax(280px, 1fr))`
3. Add a sidebar that **hides on mobile** and appears on desktop

## Phase 0 Checkpoint
Build a fully responsive page in pure HTML/CSS — no framework, no JavaScript:

**Requirements:**
- **Sticky header** — stays at top on scroll, contains a logo and nav links
- **Two-column layout** below the header — sidebar (240px) + main content area (fluid)
- **Card grid** in the main content — cards with image, title, body text, and a footer button. Cards must have equal height; the button aligns to the bottom of each card (use Flexbox inside the card)
- **Mobile behavior** (< 768px): sidebar hides, single-column card grid, header links collapse
- No `!important`, no inline styles for layout, no JavaScript
