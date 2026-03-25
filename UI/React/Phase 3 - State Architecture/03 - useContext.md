# useContext

> Phase 3 | Topic 3

## Why this matters
Context solves prop drilling — passing data through many layers of components that do not use it, just to reach a deeply nested consumer. The canonical use cases are: current user, theme, locale. The critical warning: **any component that calls `useContext` re-renders whenever the context value changes**, even if that component only uses part of the value.

## Sub-skills to master
```typescript
// 1. Create context with a typed default
interface ThemeContextValue {
  theme: 'light' | 'dark';
  toggleTheme: () => void;
}
const ThemeContext = createContext<ThemeContextValue | null>(null);
// Using null as default forces consumers to check for null (better than a fake default)

// 2. Build the provider
function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');
  const toggleTheme = useCallback(() => setTheme(t => t === 'light' ? 'dark' : 'light'), []);

  // IMPORTANT: memoize the value to avoid re-creating it on every parent render
  const value = useMemo(() => ({ theme, toggleTheme }), [theme, toggleTheme]);

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

// 3. Custom hook wrapper (with null check)
function useTheme(): ThemeContextValue {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
}

// 4. Consume anywhere in the tree
function DarkModeButton() {
  const { theme, toggleTheme } = useTheme();
  return <button onClick={toggleTheme}>{theme === 'dark' ? '☀️' : '🌙'}</button>;
}
```

### The performance trap
```typescript
// BAD: splitting user and theme into one context
const AppContext = createContext({ user, theme, cart });
// Any change to cart re-renders EVERY consumer, even components that only use theme

// GOOD: split by update frequency
const UserContext  = createContext(user);    // changes rarely
const ThemeContext = createContext(theme);   // changes on toggle
const CartContext  = createContext(cart);    // changes frequently
// Each consumer only re-renders when its specific context changes
```

### Context is dependency injection, not a state manager
- Context passes a value down the tree — it doesn't manage the state itself
- Combine with `useState` or `useReducer` for the actual state management

## Exercise
Build a theme system:

1. Create a `ThemeContext` providing `{ theme: 'light' | 'dark', toggleTheme: () => void }`
2. Persist the theme choice in `localStorage` (read on init, write on change)
3. Wrap the app in `ThemeProvider`
4. A deeply nested `ThemeToggle` component (3+ levels deep) consumes it via `useTheme()`
5. Open React DevTools → Profiler, record clicking the toggle, and note which components re-render

## Mastery checkpoint
1. The default value passed to `createContext(defaultValue)` — when is it used? (Hint: it is NOT the initial state of the provider.)
2. You have a context with `{ user, notifications, cart }`. Clicking "add to cart" causes the entire app to re-render. What is wrong and how do you fix it?
3. Someone suggests: "Just put all global state in Context, it's basically a free Redux." What are the two problems with this?
4. When should you reach for Zustand or Redux Toolkit instead of Context?
