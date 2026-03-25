# Custom Hooks

> Phase 3 | Topic 4

## Why this matters
Custom hooks are the **primary mechanism for code reuse in React**. They let you extract stateful logic — data fetching, form management, subscriptions, any behavior involving hooks — into a reusable function. This is a major interview topic. A developer who writes good custom hooks writes much cleaner, more testable React code.

## Sub-skills to master
```typescript
// Custom hook = any function starting with `use` that calls other hooks
// Rules of hooks still apply: only call at top level, only from React functions

// Pattern 1: tuple return (like useState)
function useToggle(initial = false): [boolean, () => void] {
  const [value, setValue] = useState(initial);
  const toggle = useCallback(() => setValue(v => !v), []);
  return [value, toggle];
}
const [isOpen, toggleOpen] = useToggle();

// Pattern 2: object return (for multiple values)
function useFetch<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    fetch(url, { signal: controller.signal })
      .then(r => r.json())
      .then(data => { setData(data); setLoading(false); })
      .catch(e => { if (e.name !== 'AbortError') { setError(e); setLoading(false); } });
    return () => controller.abort();
  }, [url]);

  return { data, loading, error };
}

// Generic custom hook
function useLocalStorage<T>(key: string, initialValue: T): [T, (value: T) => void] {
  const [stored, setStored] = useState<T>(() => {
    try {
      const item = localStorage.getItem(key);
      return item ? (JSON.parse(item) as T) : initialValue;
    } catch {
      return initialValue;
    }
  });

  const setValue = useCallback((value: T) => {
    setStored(value);
    localStorage.setItem(key, JSON.stringify(value));
  }, [key]);

  return [stored, setValue];
}

// Composing custom hooks
function useUserProfile(userId: string) {
  const { data: user, loading, error } = useFetch<User>(`/api/users/${userId}`);
  const [isEditing, toggleEditing] = useToggle(false);
  return { user, loading, error, isEditing, toggleEditing };
}
```

## Exercise
Build these two hooks with full TypeScript generics:

**`useDebounce<T>(value: T, delayMs: number): T`**
- Returns a debounced version of `value`
- Updates only after `delayMs` ms of no changes
- Uses `useRef` for the timer ID, `useState` for the debounced value
- Clean up the timer on unmount

**`useLocalStorage<T>(key: string, initialValue: T): [T, (value: T) => void]`**
- Reads initial value from localStorage on mount
- Writes to localStorage on every update
- Falls back to `initialValue` if nothing is stored or parsing fails
- Return type must be a proper tuple (not widened to array union)

Then compose them: `useSearchWithPersistence(key: string)` that returns a `{ query, debouncedQuery, setQuery }` where `query` persists in localStorage and `debouncedQuery` is debounced 300ms.

## Mastery checkpoint
1. What makes a function a "custom hook" vs a regular utility function? Why does the naming convention `use*` matter?
2. Can a custom hook be called conditionally (`if (condition) useMyHook()`)? Why?
3. How do you test a custom hook in isolation, without rendering a component?
4. Your `useFetch` hook is called in 5 different components with the same URL simultaneously. Without any caching layer, how many network requests happen? How does React Query solve this?
