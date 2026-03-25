# Portals

> Phase 4 | Topic 8

## Why this matters
Modals, tooltips, and dropdowns need to render outside their parent DOM node — typically as a direct child of `document.body` — to escape CSS `overflow: hidden`, `z-index` stacking contexts, and `transform` side effects from ancestors. React Portals let you render into a different DOM node while keeping the React context hierarchy intact.

## Sub-skills to master
```typescript
import { createPortal } from 'react-dom';

// Basic portal — renders children into document.body
function Modal({ children }: { children: React.ReactNode }) {
  return createPortal(
    <div className="modal-overlay">{children}</div>,
    document.body  // the target DOM node
  );
}

// Dedicated portal root (better practice)
// In index.html: <div id="modal-root"></div>
function Modal({ children }: { children: React.ReactNode }) {
  const portalRoot = document.getElementById('modal-root')!;
  return createPortal(children, portalRoot);
}

// Dynamic portal root (for SSR safety and cleanup)
function Modal({ children }: { children: React.ReactNode }) {
  const [container] = useState(() => {
    const el = document.createElement('div');
    document.body.appendChild(el);
    return el;
  });

  useEffect(() => {
    return () => document.body.removeChild(container); // cleanup on unmount
  }, [container]);

  return createPortal(children, container);
}
```

### What stays intact through a portal
- **React event system:** events bubble through the React tree, not the DOM tree
  - A click inside a portal modal **does** trigger a parent React component's `onClick`
- **Context:** portal children can still consume context from above in the React tree
- **State:** portal children participate in the normal React lifecycle

### What changes
- **DOM position:** the portal renders as a child of its target, not its React parent
- **CSS:** the portal content inherits styles from the portal target (document.body), not its logical parent

## Exercise
Build a `Portal` utility component:
```typescript
function Portal({ children, target = document.body }: {
  children: React.ReactNode;
  target?: HTMLElement;
}) { ... }
```

Then use it to build a `Tooltip` component:
- Renders at the cursor position (use `useRef` + mouse events to track position)
- Renders via a portal so it is never clipped by `overflow: hidden` containers
- Shows on `mouseenter`, hides on `mouseleave`
- Wraps its children as the trigger element

Test it by placing the trigger inside a `<div style={{ overflow: 'hidden', height: '50px' }}>` — the tooltip should still be fully visible.

## Mastery checkpoint
1. A click inside a portal modal closes the modal because a parent component has `onClick={() => setIsOpen(false)}`. Why does this happen even though the portal is outside that parent in the DOM? How do you fix it?
2. A parent component has `transform: scale(0.9)`. A tooltip using absolute positioning inside that parent is offset incorrectly. How does a portal fix this?
3. You render a portal into `document.body`. The component that creates it unmounts. What happens to the portal's DOM node if you don't clean up?
