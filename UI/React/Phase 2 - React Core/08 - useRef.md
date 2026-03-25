# useRef

> Phase 2 | Topic 8

## Why this matters
`useRef` serves two distinct purposes: (1) accessing a real DOM node imperatively, and (2) storing a mutable value that persists across renders without causing re-renders. Knowing when to use `ref` vs `state` prevents both unnecessary re-renders (ref when you don't need to display the value) and missed renders (state when you do).

## Sub-skills to master
```typescript
// Purpose 1: DOM access
const inputRef = useRef<HTMLInputElement>(null);
// ref.current is null until after mount
// Attach with ref prop:
<input ref={inputRef} type="text" />
// After mount:
inputRef.current?.focus();
inputRef.current?.select();
const width = inputRef.current?.getBoundingClientRect().width;

// Purpose 2: mutable value without re-renders
const timerRef = useRef<ReturnType<typeof setTimeout>>();
const prevValueRef = useRef<string>('');
const renderCountRef = useRef(0);

// Updating ref does NOT trigger re-render
renderCountRef.current++;

// Key rule: ref.current is null on first render (before mount)
useEffect(() => {
  // Safe to use ref here — after mount
  inputRef.current?.focus();
}, []);

// Stale closure workaround with ref
const callbackRef = useRef(onClose);
callbackRef.current = onClose; // always the latest prop
useEffect(() => {
  window.addEventListener('keydown', e => {
    if (e.key === 'Escape') callbackRef.current?.(); // reads latest, not stale
  });
}, []); // safe with empty deps because we read through the ref
```

### State vs Ref: decision guide
| Question | Use |
|---|---|
| Do I need to display this value in the UI? | `useState` |
| Does changing this value need to trigger a re-render? | `useState` |
| Do I need to access a DOM node? | `useRef` |
| Is this a timer ID, subscription, or mutable counter? | `useRef` |
| Do I need the latest version of a prop inside a stable callback? | `useRef` |

## Exercise
Build a `SearchInput` component:

1. **Auto-focus:** Accepts a `autoFocus?: boolean` prop. When true, focus the input after mount using a ref.

2. **Debounce:** The input has an `onChange` prop (called with debounced value). Implement the debounce using a `useRef` to store the timer ID. The debounce delay is 300ms. Do not use any external library.

3. **Render count:** Display in small text "Rendered N times" — but this count should NOT include renders caused by the debounce timer. Use a ref for the count and update it on every render without using state.

```typescript
interface SearchInputProps {
  autoFocus?: boolean;
  onChange: (value: string) => void;
  placeholder?: string;
}
```

## Mastery checkpoint
1. Why does `useRef` not cause a re-render when its `.current` changes, while `useState` does?
2. You call `inputRef.current.focus()` during rendering (outside useEffect). What happens?
3. You need to store the *previous* value of a prop so you can compare it to the current value. Is `useState` or `useRef` more appropriate? Write the implementation.
4. `useImperativeHandle` is used with `forwardRef`. What does it let you do, and when would you need it?
