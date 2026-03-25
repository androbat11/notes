# Render Props Pattern

> Phase 4 | Topic 3

## Why this matters
Render props were the primary code-reuse pattern before hooks. You will encounter them in older codebases and in some libraries (Downshift, React Window, some Formik APIs). Understanding them helps you read existing code and understand why hooks replaced most of their use cases.

## Sub-skills to master
```typescript
// The pattern: a component accepts a function prop and calls it to produce its output

// Classic render prop
interface MouseTrackerProps {
  render: (position: { x: number; y: number }) => React.ReactNode;
}
function MouseTracker({ render }: MouseTrackerProps) {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  return (
    <div onMouseMove={e => setPosition({ x: e.clientX, y: e.clientY })}>
      {render(position)}  {/* calls the consumer's function with the data */}
    </div>
  );
}

// Usage
<MouseTracker render={({ x, y }) => <p>Mouse is at {x}, {y}</p>} />

// children as a function (most common form in libraries)
interface MouseTrackerProps {
  children: (position: { x: number; y: number }) => React.ReactNode;
}
// Usage
<MouseTracker>
  {({ x, y }) => <p>Mouse is at {x}, {y}</p>}
</MouseTracker>

// This same logic as a custom hook (the hooks replacement):
function useMousePosition() {
  const [position, setPosition] = useState({ x: 0, y: 0 });
  useEffect(() => {
    const handler = (e: MouseEvent) => setPosition({ x: e.clientX, y: e.clientY });
    window.addEventListener('mousemove', handler);
    return () => window.removeEventListener('mousemove', handler);
  }, []);
  return position;
}
// Much simpler at the call site — no JSX nesting
const { x, y } = useMousePosition();
```

### Where render props still appear
- **Headless UI / Radix UI:** components that expose state and let you render whatever you want
- **React Window:** `FixedSizeList` uses a render prop for each row
- **Downshift:** exposes combobox state via render props
- **React Router v5:** `<Route render={...}>` (replaced with `element=` in v6)

### The "wrapper hell" problem
```typescript
// Multiple render props compose poorly — "callback hell" but for JSX
<DataProvider render={data =>
  <AuthProvider render={auth =>
    <ThemeProvider render={theme =>
      <App data={data} auth={auth} theme={theme} />
    } />
  } />
} />

// The same thing with custom hooks — flat and readable
function App() {
  const data  = useData();
  const auth  = useAuth();
  const theme = useTheme();
  return <AppUI data={data} auth={auth} theme={theme} />;
}
```

## Exercise
1. Implement a `DataFetcher` component using the render props pattern:
```typescript
interface DataFetcherProps<T> {
  url: string;
  children: (state: {
    data: T | null;
    loading: boolean;
    error: Error | null;
  }) => React.ReactNode;
}
```

2. Use it to render a user profile:
```jsx
<DataFetcher<User> url="/api/users/1">
  {({ data, loading, error }) => {
    if (loading) return <Spinner />;
    if (error) return <ErrorMsg error={error} />;
    return <UserProfile user={data!} />;
  }}
</DataFetcher>
```

3. Now rewrite `DataFetcher` as a custom hook `useFetch<T>`. Compare the two at the call site.

## Mastery checkpoint
1. What problem did render props solve that HOCs had (hint: look at DevTools component tree)?
2. Why did custom hooks make render props largely unnecessary?
3. When would you still choose a render prop over a custom hook today?
