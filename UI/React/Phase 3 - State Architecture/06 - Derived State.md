# Derived State

> Phase 3 | Topic 6

## Why this matters
One of the most common React anti-patterns is **syncing state to state** — storing a value in `useState` that could be computed from existing state. This creates bugs (the derived copy can go out of sync), requires extra `useEffect` to maintain, and makes the state harder to reason about. The rule: **if you can compute it, do not store it**.

## Sub-skills to master
```typescript
// ANTI-PATTERN — derived state stored in state, synced via useEffect
const [items, setItems] = useState<Item[]>([]);
const [filter, setFilter] = useState('');
const [filteredItems, setFilteredItems] = useState<Item[]>([]); // unnecessary!

useEffect(() => {
  setFilteredItems(items.filter(i => i.name.includes(filter)));
}, [items, filter]); // extra render, can get out of sync

// CORRECT — compute during render
const [items, setItems] = useState<Item[]>([]);
const [filter, setFilter] = useState('');
const filteredItems = items.filter(i => i.name.includes(filter)); // zero cost for small arrays

// CORRECT with useMemo for expensive computation
const sortedAndFiltered = useMemo(() => {
  return items
    .filter(i => i.name.toLowerCase().includes(filter.toLowerCase()))
    .sort((a, b) => a.name.localeCompare(b.name));
}, [items, filter]); // only recomputes when items or filter changes

// Derived from props — do NOT copy props into state
// BAD
function Input({ value }: { value: string }) {
  const [localValue, setLocalValue] = useState(value); // doesn't update when prop changes!
}
// The only time it is valid to initialize state from props is for "uncontrolled with initial value"
function Input({ defaultValue }: { defaultValue: string }) {
  const [value, setValue] = useState(defaultValue); // fine — prop is initial only
}
```

### Quick checklist before adding `useState`
1. Can I compute this from existing state or props?  → compute it, don't store it
2. Is this derived from props but needs local overrides?  → `useState(prop)` with `defaultValue` naming
3. Is it truly independent state?  → `useState` is correct

## Exercise
Given a component with:
```typescript
const [products, setProducts] = useState<Product[]>([]);
const [searchQuery, setSearchQuery] = useState('');
const [sortField, setSortField] = useState<keyof Product>('name');
const [sortDir, setSortDir] = useState<'asc' | 'desc'>('asc');
const [selectedCategory, setSelectedCategory] = useState<string>('all');
```

Compute all derived values **without adding any more `useState`**:
1. `filteredProducts` — filtered by `searchQuery` and `selectedCategory`
2. `sortedProducts` — `filteredProducts` sorted by `sortField` and `sortDir`
3. `totalCount` — count of `filteredProducts`
4. `categories` — unique categories from `products` for the filter dropdown

Which of these (if any) deserve `useMemo`?

## Mastery checkpoint
1. You use `useEffect` to sync `filteredItems` whenever `items` or `filter` changes. What is the extra render this causes and why is it wasteful?
2. A component receives a `user` prop. It needs a formatted display name (`firstName + ' ' + lastName`). Should you store this in state? Why?
3. When is it appropriate to copy a prop value into state? Give a concrete example.
