# Controlled vs Uncontrolled Components

> Phase 2 | Topic 10 | Phase Checkpoint

## Why this matters
Forms are the most common source of confusion for React beginners. Controlled components — where React state is the single source of truth for every input value — are the React-idiomatic approach. Uncontrolled components use refs to read DOM values directly. You need both, and you need to know when to use each. React Hook Form uses uncontrolled inputs for performance.

## Sub-skills to master
```typescript
// CONTROLLED — React owns the value
const [name, setName] = useState('');
<input
  value={name}                              // React drives the value
  onChange={e => setName(e.target.value)}   // React updates state on every keystroke
/>
// Without onChange, the input is read-only — React enforces this with a warning

// UNCONTROLLED — DOM owns the value, you read via ref
const nameRef = useRef<HTMLInputElement>(null);
<input ref={nameRef} defaultValue="Alice" />
// Read value when needed (e.g. on submit):
const value = nameRef.current?.value;

// defaultValue vs value
<input defaultValue="Alice" />   // uncontrolled: initial value, DOM owns it after
<input value="Alice" />          // controlled: React locks it to 'Alice' (read-only unless onChange)

// Controlled checkbox
const [checked, setChecked] = useState(false);
<input type="checkbox" checked={checked} onChange={e => setChecked(e.target.checked)} />

// Controlled select
const [role, setRole] = useState<'admin' | 'user'>('user');
<select value={role} onChange={e => setRole(e.target.value as 'admin' | 'user')}>
  <option value="user">User</option>
  <option value="admin">Admin</option>
</select>

// File input — always uncontrolled (you can't set its value programmatically)
const fileRef = useRef<HTMLInputElement>(null);
<input type="file" ref={fileRef} />
const file = fileRef.current?.files?.[0];
```

### When to use each
| Scenario | Use |
|---|---|
| Validation on every keystroke | Controlled |
| Conditionally enable/disable submit | Controlled |
| Dynamic field values (computed from another field) | Controlled |
| Large forms where re-render on every keystroke hurts | Uncontrolled (React Hook Form) |
| File upload | Uncontrolled (always) |
| Simple one-off form, no validation | Either |

## Exercise
Build a registration form with these fields: `username`, `email`, `password`, `confirmPassword`, `role` (select), `agreedToTerms` (checkbox).

**Requirements:**
1. All fields controlled (except a bonus file upload for avatar — uncontrolled)
2. Inline validation:
   - `username`: required, min 3 chars
   - `email`: required, must contain `@`
   - `password`: required, min 8 chars
   - `confirmPassword`: must match `password`
3. Submit button disabled if any field is invalid
4. On submit, prevent default and log all values
5. TypeScript strict — no `any`

## Phase 2 Checkpoint
Build a **filterable, sortable data table** component in TypeScript:

```typescript
interface Column<T> {
  key: keyof T;
  label: string;
  sortable?: boolean;
}
interface DataTableProps<T extends { id: string }> {
  data: T[];
  columns: Column<T>[];
}
```

Requirements:
- Renders rows with `.map()` using `id` as key
- A controlled text input filters rows (matches any string field)
- Clicking a column header sorts by that column (toggle asc/desc)
- All state managed with `useState`
- No external libraries
- TypeScript strict — no `any`
