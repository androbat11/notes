# Controlled Component Pattern for Reusable Inputs

> Phase 4 | Topic 6

## Why this matters
Building a reusable input that plays well with any form library or state management approach requires exposing both controlled and uncontrolled interfaces — just like native HTML inputs. A well-designed custom input works seamlessly with React Hook Form, manual state, and Formik without special cases.

## Sub-skills to master
```typescript
// A reusable input that supports both controlled and uncontrolled usage
interface TextInputProps extends Omit<React.ComponentProps<'input'>, 'onChange'> {
  label: string;
  error?: string;
  onChange?: (value: string) => void;  // note: string, not event (cleaner API)
}

const TextInput = React.forwardRef<HTMLInputElement, TextInputProps>(
  ({ label, error, onChange, ...rest }, ref) => {
    const id = useId(); // React 18 — generates a stable unique ID

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
      onChange?.(e.target.value); // expose string, not event
    };

    return (
      <div className="field">
        <label htmlFor={id}>{label}</label>
        <input
          id={id}
          ref={ref}
          onChange={handleChange}
          aria-describedby={error ? `${id}-error` : undefined}
          aria-invalid={!!error}
          {...rest}  // passes value, defaultValue, disabled, placeholder, etc.
        />
        {error && <span id={`${id}-error`} role="alert">{error}</span>}
      </div>
    );
  }
);
TextInput.displayName = 'TextInput';

// Controlled usage
const [name, setName] = useState('');
<TextInput label="Name" value={name} onChange={setName} error={nameError} />

// Uncontrolled usage (with React Hook Form)
const { register } = useForm();
<TextInput label="Name" {...register('name')} />
// register spreads ref, onChange (as event), onBlur, name

// Uncontrolled with default
<TextInput label="Name" defaultValue="Alice" />
```

### The `forwardRef` requirement
React Hook Form and other form libraries need access to the underlying DOM input via a `ref` to manage focus and read values. Without `forwardRef`, your custom input can't be used with these libraries.

### `useId` for accessibility
```typescript
// React 18 — generates a unique ID stable across server and client renders
const id = useId(); // e.g. ':r1:'
// Use for: label/input association, aria-describedby, etc.
```

## Exercise
Build a reusable `Select` component:
```typescript
interface SelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}
interface SelectProps extends Omit<React.ComponentProps<'select'>, 'onChange'> {
  label: string;
  options: SelectOption[];
  error?: string;
  onChange?: (value: string) => void;
}
```

Requirements:
- Works controlled: `value` + `onChange`
- Works uncontrolled: `defaultValue` only
- Has a visible label linked via `htmlFor`/`id` (use `useId`)
- Shows an error message below when `error` is set
- `forwardRef` so it works with React Hook Form
- Renders disabled options correctly

## Mastery checkpoint
1. Why does React Hook Form need a `ref` on your custom input?
2. What is `useId()` for and why is it better than `Math.random()` or a counter for generating input IDs?
3. Your `TextInput` exposes `onChange: (value: string) => void` instead of `React.ChangeEvent<HTMLInputElement>`. What is the UX benefit? What do you lose?
