# Higher-Order Components (HOC)

> Phase 4 | Topic 4

## Why this matters
HOCs are functions that take a component and return an enhanced component. `connect()` from React-Redux and `withRouter` are the canonical examples. They predate hooks — but many libraries still use them, and understanding HOCs is required to read legacy code and work with libraries that expose them.

## Sub-skills to master
```typescript
// A HOC is: (Component) => EnhancedComponent
function withLoading<P extends object>(
  Component: React.ComponentType<P>
) {
  // Return a new component that wraps the original
  function WithLoading({ isLoading, ...props }: P & { isLoading: boolean }) {
    if (isLoading) return <LoadingSpinner />;
    return <Component {...(props as P)} />;
  }
  // Preserve display name for DevTools
  WithLoading.displayName = `withLoading(${Component.displayName ?? Component.name})`;
  return WithLoading;
}

// Usage
const UserCardWithLoading = withLoading(UserCard);
<UserCardWithLoading isLoading={loading} name="Alice" email="alice@example.com" />

// Authentication HOC
function withAuth<P extends object>(Component: React.ComponentType<P>) {
  return function WithAuth(props: P) {
    const { isAuthenticated } = useAuth(); // hooks work inside HOCs
    if (!isAuthenticated) return <Navigate to="/login" />;
    return <Component {...props} />;
  };
}

// Composing HOCs
const EnhancedPage = compose(
  withAuth,
  withErrorBoundary,
  withAnalytics('page_view')
)(DashboardPage);
```

### Problems with HOCs
```typescript
// 1. Prop collision — the HOC and wrapped component may use the same prop name
// 2. Wrapper hell in DevTools — every HOC adds a layer:
//    withAuth(withErrorBoundary(withTheme(Component)))
// 3. Unclear where props come from — the component receives injected props it didn't declare
// 4. TypeScript is notoriously hard to type correctly

// Modern equivalent with hooks — all problems solved
function DashboardPage() {
  const { isAuthenticated } = useAuth();
  const { theme } = useTheme();
  // no wrappers, no prop injection, no naming collision
}
```

## Exercise
**Part 1:** Implement `withErrorBoundary<P>(Component, FallbackComponent)` — a HOC that wraps the component in an error boundary. If the wrapped component throws, render `FallbackComponent` instead.

**Part 2:** Implement `withLogging<P>(Component, eventName)` — a HOC that logs `eventName` to the console every time the component renders (use `useEffect` inside the HOC).

**Part 3:** Now implement the same behavior using custom hooks. Compare:
- How many lines is each approach?
- What does the DevTools component tree look like for each?
- How does TypeScript handle each?

## Mastery checkpoint
1. You receive a codebase using `connect(mapStateToProps, mapDispatchToProps)(Component)` from legacy React-Redux. What is `connect` returning? What are `mapStateToProps` and `mapDispatchToProps`?
2. Why do HOCs make TypeScript difficult? (Think about how props flow through multiple wrapping layers.)
3. A HOC injects a `userId` prop into every wrapped component. The wrapped component also has a prop named `userId` for a different purpose. What happens?
