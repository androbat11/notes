# Components, Props, and TypeScript Interfaces

> Phase 2 | Topic 3

## Why this matters
Components are typed functions from props to UI. Props are the function's parameters: immutable, owned by the parent, typed. A component that respects its prop contract and produces predictable output from the same inputs is easy to test, reuse, and reason about.

## Sub-skills to master
```typescript
// Basic component with typed props
interface CardProps {
  title: string;
  subtitle?: string;               // optional
  variant?: 'default' | 'danger';  // union literal type
  children: React.ReactNode;        // anything React can render
  onDismiss?: () => void;          // optional callback
}

// Prefer plain function over React.FC (FC has issues with generics)
function Card({ title, subtitle, variant = 'default', children, onDismiss }: CardProps) {
  return (
    <div className={`card card--${variant}`}>
      <h2>{title}</h2>
      {subtitle && <p className="subtitle">{subtitle}</p>}
      {children}
      {onDismiss && <button onClick={onDismiss}>✕</button>}
    </div>
  );
}

// Extending native element props
interface ButtonProps extends React.ComponentProps<'button'> {
  variant: 'primary' | 'ghost';
  loading?: boolean;
}
// Now ButtonProps has all native button props (type, disabled, onClick, etc.) + our custom ones

// Passing unknown extra props through (prop forwarding)
function Input({ className, ...rest }: React.ComponentProps<'input'>) {
  return <input className={`input ${className ?? ''}`} {...rest} />;
}

// Children typing options
React.ReactNode          // most permissive: string, number, JSX, array, null, boolean
React.ReactElement       // only a JSX element (not string/number)
React.PropsWithChildren<Props>  // shorthand to add children?: ReactNode to any interface
```

## Exercise
Build a `Card` component with this interface:
```typescript
interface CardProps {
  title: string;
  subtitle?: string;
  variant: 'default' | 'highlighted' | 'danger';
  children: React.ReactNode;
  footer?: React.ReactNode;  // consumer provides the footer content
  onClose?: () => void;      // optional close button
}
```

Requirements:
- Renders no close button if `onClose` is not provided
- Renders no footer if `footer` is not provided
- Applies a CSS class based on `variant`
- `subtitle` renders below the title when provided
- `children` renders in the card body
- TypeScript strict mode — no `any`

## Mastery checkpoint
1. What is the difference between `React.ReactNode` and `React.ReactElement` as a children type? When would you use each?
2. Why is `React.FC<Props>` generally avoided in modern TypeScript React? What does it add that a plain function does not have?
3. You want a `Panel` component that accepts all native `<div>` props plus a `title: string` prop. Write the interface using `React.ComponentProps`.
4. What does it mean that props are "immutable" in React? What happens at runtime if you mutate a prop?
