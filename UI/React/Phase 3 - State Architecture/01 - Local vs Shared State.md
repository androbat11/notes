# Local vs Shared State

> Phase 3 | Topic 1

## Why this matters
The number one state management mistake is putting everything in a global store. The right default is to keep state as local as possible — inside the component that owns it. Only lift it when two components genuinely need to share it. Lifting too high causes unnecessary re-renders and tight coupling.

## Sub-skills to master

### The Rule
> State lives at the **lowest component** that can satisfy all consumers.

```typescript
// LOCAL — only SearchBar needs the search query
function SearchBar() {
  const [query, setQuery] = useState('');  // correct: local
  return <input value={query} onChange={e => setQuery(e.target.value)} />;
}

// LIFTED — both FilterBar and ResultList need the same query
function SearchPage() {
  const [query, setQuery] = useState('');  // lifted to common ancestor
  return (
    <>
      <FilterBar query={query} onQueryChange={setQuery} />
      <ResultList query={query} />
    </>
  );
}

// The cost of lifting too high:
// Every state change in the parent re-renders ALL children
// Even ones that don't use the state (unless memoized)
```

### Pushing state down
```typescript
// BAD — expander state is in the parent, forces parent re-render on every toggle
function Dashboard() {
  const [isPanelOpen, setIsPanelOpen] = useState(false);
  return <Panel isOpen={isPanelOpen} onToggle={() => setIsPanelOpen(p => !p)} />;
}

// GOOD — Panel owns its own open state, only Panel re-renders
function Panel() {
  const [isOpen, setIsOpen] = useState(false);
  return <div onClick={() => setIsOpen(p => !p)}>{isOpen && <Content />}</div>;
}
```

### Derived state — do not store what you can compute
```typescript
// BAD — syncing state to state via useEffect
const [items, setItems] = useState<Item[]>([]);
const [filteredItems, setFilteredItems] = useState<Item[]>([]);
useEffect(() => {
  setFilteredItems(items.filter(i => i.active));
}, [items]); // extra render, sync risk

// GOOD — compute during render
const [items, setItems] = useState<Item[]>([]);
const filteredItems = items.filter(i => i.active); // free, no state needed
```

## Exercise
Given this component tree for a product page:
```
ProductPage
├── ProductGallery    (needs: selectedImageIndex)
├── ProductThumbnails (needs: selectedImageIndex, setSelectedImageIndex)
└── ProductInfo       (needs: selectedImageIndex for showing a "viewing image N" label)
```

1. Identify where `selectedImageIndex` state should live
2. Implement it — pass state and setter to only the components that need them
3. Identify 3 values that should be **derived** (not stored as state) from `selectedImageIndex` and the image array

## Mastery checkpoint
1. A component tree has `App → Page → Section → Widget`. Only `Widget` uses a piece of state. Where should the state live? What changes if `Section` also needs to read it?
2. You have `const [isExpanded, setIsExpanded] = useState(false)` in a parent. Only the child toggle button and its content use it. What is the refactor?
3. Why does "push state down" improve performance? Which React mechanism does it make unnecessary?
