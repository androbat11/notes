# Accessibility Basics

> Phase 4 | Topic 9 | Phase Checkpoint

## Why this matters
Accessibility is not optional — it is a legal requirement in many jurisdictions and a professional quality bar. React makes it easy to write accessible UIs with semantic HTML and ARIA, but also easy to build inaccessible ones with `div`s and `span`s for everything. Interviewers ask about this.

## Sub-skills to master

### Semantic HTML first
```html
<!-- BAD: div soup -->
<div class="button" onclick="submit()">Submit</div>
<div class="nav">...</div>

<!-- GOOD: semantic elements have built-in roles, keyboard support, and screen reader behavior -->
<button type="button" onClick={submit}>Submit</button>
<nav>...</nav>
<main>...</main>
<header>...</header>
<footer>...</footer>
<article>...</article>
<section aria-labelledby="section-title">...</section>
```

### ARIA — only when semantic HTML is not sufficient
```jsx
// role: override or add semantic meaning
<div role="dialog" aria-modal="true" aria-labelledby="dialog-title">

// aria-label: for elements with no visible text
<button aria-label="Close dialog"><XIcon /></button>

// aria-labelledby: point to another element's text
<h2 id="dialog-title">Confirm deletion</h2>
<div aria-labelledby="dialog-title">...</div>

// aria-describedby: additional context
<input aria-describedby="email-hint" />
<p id="email-hint">Enter your work email address</p>

// aria-expanded: for toggles
<button aria-expanded={isOpen} onClick={toggle}>Menu</button>

// aria-invalid + aria-errormessage: for form errors
<input aria-invalid={!!error} aria-errormessage="email-error" />
<p id="email-error" role="alert">{error}</p>

// Live regions: announce dynamic content to screen readers
<div aria-live="polite">{statusMessage}</div>
<div aria-live="assertive">{errorMessage}</div>
```

### Keyboard navigation
```typescript
// Focus management — move focus when something appears
const modalHeadingRef = useRef<HTMLHeadingElement>(null);
useEffect(() => {
  if (isOpen) modalHeadingRef.current?.focus();
}, [isOpen]);

// Focus trap inside modal
function useFocusTrap(containerRef: RefObject<HTMLElement>, isActive: boolean) {
  useEffect(() => {
    if (!isActive) return;
    const focusable = containerRef.current?.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    const first = focusable?.[0] as HTMLElement;
    const last  = focusable?.[focusable.length - 1] as HTMLElement;

    const handleTab = (e: KeyboardEvent) => {
      if (e.key !== 'Tab') return;
      if (e.shiftKey) {
        if (document.activeElement === first) { last.focus(); e.preventDefault(); }
      } else {
        if (document.activeElement === last) { first.focus(); e.preventDefault(); }
      }
    };
    document.addEventListener('keydown', handleTab);
    return () => document.removeEventListener('keydown', handleTab);
  }, [isActive, containerRef]);
}

// Escape key to close
useEffect(() => {
  const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose(); };
  document.addEventListener('keydown', handler);
  return () => document.removeEventListener('keydown', handler);
}, [onClose]);
```

### Color contrast
- WCAG AA: 4.5:1 ratio for normal text, 3:1 for large text (18px+ or 14px+ bold)
- Tool: [coolors.co/contrast-checker](https://coolors.co/contrast-checker) or browser DevTools

## Phase 4 Checkpoint
Build a reusable `<Modal>` component:

**Requirements:**
1. Renders via a portal into `document.body`
2. `role="dialog"`, `aria-modal="true"`, `aria-labelledby={titleId}`
3. Focus moves to the modal heading when it opens
4. Focus returns to the trigger element when it closes
5. **Focus trap:** Tab cycles only within the modal while it's open
6. **Escape key** closes the modal (calls `onClose`)
7. Backdrop click calls `onClose`
8. TypeScript props: `isOpen: boolean`, `onClose: () => void`, `title: string`, `children: ReactNode`

```typescript
function Modal({ isOpen, onClose, title, children }: ModalProps) {
  // your implementation
}
```
