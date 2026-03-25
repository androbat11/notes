# CSS Layout: Box Model, Flexbox, Grid

> Phase 0 | Topic 4

## Why this matters
You will spend a significant fraction of your React career fighting layout bugs. CSS layout is not a "nice to have" — it is the foundation of every UI you build. Flexbox and Grid are the two layout systems used in ~95% of React UIs. Knowing them deeply means you stop fighting the browser and start composing layouts intentionally.

## Sub-skills to master

### Box Model
- Content → Padding → Border → Margin (inside-out)
- `box-sizing: border-box` — padding and border are included in the declared width/height. Use it everywhere (`* { box-sizing: border-box }`)
- Block elements stack vertically; inline elements flow horizontally
- Margin collapsing: adjacent vertical margins collapse to the larger one

### Flexbox (one-dimensional)
- `display: flex` on the container
- `flex-direction`: `row` (default) | `column`
- `justify-content`: main axis alignment (`flex-start`, `center`, `space-between`, `space-around`)
- `align-items`: cross axis alignment (`flex-start`, `center`, `stretch`)
- `flex-wrap: wrap` — allows items to wrap to next line
- `gap`: spacing between items (no need for margins)
- On items: `flex-grow`, `flex-shrink`, `flex-basis` (shorthand: `flex: 1`)
- `align-self`: override `align-items` for a single item

### Grid (two-dimensional)
- `display: grid` on the container
- `grid-template-columns: repeat(3, 1fr)` — three equal columns
- `fr` unit: fraction of available space
- `auto-fill` vs `auto-fit`: both fill available space; `auto-fit` collapses empty tracks
- `minmax(min, max)`: e.g. `repeat(auto-fill, minmax(200px, 1fr))` — responsive without media queries
- `gap`: row and column gaps
- On items: `grid-column: span 2`, `grid-row: 1 / 3`

### Positioning
- `static` (default), `relative` (offset without leaving flow), `absolute` (out of flow, relative to nearest positioned ancestor), `fixed` (viewport), `sticky` (hybrid)
- `z-index` only works on positioned elements (anything but `static`)

## Exercise
Build these three layouts in pure HTML/CSS — no framework:

**Layout 1 — Navbar (Flexbox)**
Logo on the left, nav links centered, a CTA button on the right. Stays in a single row.

**Layout 2 — Responsive Card Grid (Grid)**
Cards that are at least 200px wide, fill the row, and automatically wrap. Use `repeat(auto-fill, minmax(200px, 1fr))` — no media queries needed.

**Layout 3 — Sidebar + Content**
Left sidebar fixed at 260px, right content fills remaining space. Use Grid: `grid-template-columns: 260px 1fr`.

## Mastery checkpoint
Build a **holy grail layout** in pure CSS Grid:
- Sticky header (stays at top on scroll)
- Sticky footer (stays at bottom)
- Left sidebar: 220px fixed width
- Right sidebar: 220px fixed width
- Center content: fluid, fills remaining space
- On mobile (< 768px): single column, sidebars stack above/below content

No JavaScript. No framework.
