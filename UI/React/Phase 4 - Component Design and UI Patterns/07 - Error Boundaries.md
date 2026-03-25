# Error Boundaries

> Phase 4 | Topic 7

## Why this matters
JavaScript errors in rendering cause the entire React tree to unmount by default — showing the user a blank screen. Error boundaries catch rendering errors and display a fallback UI. Every production app needs them. They are one of the few remaining cases requiring a class component.

## Sub-skills to master
```typescript
// Class component — the only way to implement an error boundary (as of React 18)
interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

class ErrorBoundary extends React.Component<
  { children: React.ReactNode; fallback?: React.ReactNode },
  ErrorBoundaryState
> {
  state: ErrorBoundaryState = { hasError: false, error: null };

  // Called during rendering when a child throws — used to update state
  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  // Called after the error is caught — used for logging
  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, info.componentStack);
    // logErrorToService(error, info);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback ?? <p>Something went wrong.</p>;
    }
    return this.props.children;
  }
}

// Using react-error-boundary library (recommended — much simpler)
import { ErrorBoundary } from 'react-error-boundary';

function ErrorFallback({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <div role="alert">
      <p>Something went wrong: {error.message}</p>
      <button onClick={resetErrorBoundary}>Try again</button>
    </div>
  );
}

<ErrorBoundary
  FallbackComponent={ErrorFallback}
  onReset={() => queryClient.clear()}  // called when user clicks "try again"
  onError={(error, info) => logError(error, info)}
>
  <Widget />
</ErrorBoundary>
```

### What error boundaries DO NOT catch
- Async errors (inside `setTimeout`, `fetch` callbacks, event handlers)
- Errors in the error boundary itself
- Server-side rendering errors
- **Only:** errors thrown during rendering, lifecycle methods, constructors

### Placement strategy
```
App
├── ErrorBoundary (route-level: page crashes show an error page)
│   └── Router
│       ├── ErrorBoundary (widget-level: a broken widget doesn't crash the whole page)
│       │   └── SomeWidget
│       └── MainContent
```

## Exercise
1. Implement an error boundary manually (class component) that:
   - Shows a "Reload page" button for route-level boundaries
   - Shows "Try again" for widget-level boundaries
   - Logs the error and component stack to the console

2. Intentionally throw an error inside a child component and verify the boundary catches it

3. Install `react-error-boundary` and rewrite the above using `<ErrorBoundary>` with `FallbackComponent`

## Mastery checkpoint
1. A component makes a `fetch` call and the promise rejects. Will an error boundary catch this? How do you handle async errors instead?
2. You want different error UIs for different parts of the page. How many error boundaries do you need and where do you place them?
3. Why can't you implement an error boundary as a function component using hooks?
