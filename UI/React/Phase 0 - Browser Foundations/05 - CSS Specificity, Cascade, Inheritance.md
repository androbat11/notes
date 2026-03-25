# CSS Specificity, Cascade, Inheritance

> Phase 0 | Topic 5

## Why this matters
Styles breaking unexpectedly — a component's style being overridden by something unrelated — is one of the most time-consuming debugging experiences in UI work. CSS Modules and Tailwind exist precisely because specificity at scale is hard. You need to understand the underlying rules before you use tools that abstract them.

## Sub-skills to master

### Specificity (scored as a,b,c,d)
| Selector type | Score |
|---|---|
| Inline style (`style="..."`) | 1,0,0,0 |
| ID (`#app`) | 0,1,0,0 |
| Class, attribute, pseudo-class (`.active`, `[type]`, `:hover`) | 0,0,1,0 |
| Element, pseudo-element (`div`, `::before`) | 0,0,0,1 |

- Higher score wins. Compare left-to-right: `0,1,0,0` beats `0,0,99,0`
- `!important` overrides all — it is a specificity nuclear option, not a tool

### The Cascade (conflict resolution order)
1. Origin and importance (user-agent < author < inline < `!important`)
2. Specificity score
3. Source order (later rule wins on a tie)

### Inheritance
- **Inherits by default:** mostly typographic — `color`, `font-size`, `font-family`, `line-height`, `text-align`
- **Does not inherit:** mostly box model — `margin`, `padding`, `border`, `width`, `background`
- Force inheritance: `property: inherit`
- Block inheritance: `property: initial` (resets to browser default)

### Useful selectors to know
- `:is(h1, h2, h3)` — matches any of the list; specificity = highest item in the list
- `:where(h1, h2)` — like `:is()` but specificity is always 0 — safe for resets
- `:not(.active)` — matches elements not matching the argument

## Exercise
1. Calculate the specificity score for each selector:
   - `#app .card button.primary`
   - `div > ul li:first-child`
   - `[data-active="true"]`
   - `body #main .container > p.lead`

2. Given this CSS, explain which rule wins and why:
```css
/* Rule A */
.card .title { color: red; }

/* Rule B */
#sidebar .title { color: blue; }

/* Rule C */
.title { color: green !important; }
```

3. In DevTools, open any site and find a property shown with a strikethrough (overridden). Explain what overrode it.

## Mastery checkpoint
A component library styles `button.primary` with `color: white`. A consuming page adds `#app button { color: black }` which overrides it.

1. Calculate the specificity of both selectors
2. Explain exactly why the override happens
3. Propose two fixes at the **library** level — without using `!important` and without touching the consumer's code
