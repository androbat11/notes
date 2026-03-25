# State Colocation Principle

> Phase 3 | Topic 5

## Why this matters
State lives at the wrong level in most large React codebases — usually too high. When state is higher than it needs to be, more components re-render when it changes. This is the first thing a senior engineer checks in a code review, and it is the principle behind "pushing state down."

## Sub-skills to master

### The Principle
> Keep state as close to where it is used as possible.

### Recognizing state that is too high
```typescript
// BAD — isMenuOpen is in App, but only used by Navbar
function App() {
  const [isMenuOpen, setIsMenuOpen] = useState(false); // too high
  const [user, setUser] = useState(null);               // correct level

  return (
    <>
      <Navbar isMenuOpen={isMenuOpen} onMenuToggle={() => setIsMenuOpen(p => !p)} />
      <Main user={user} />
      <Footer />  {/* re-renders on every menu toggle — unnecessary */}
    </>
  );
}

// GOOD — move isMenuOpen down to Navbar
function Navbar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false); // colocated
  // Only Navbar re-renders on toggle
}
```

### Recognizing state that is too low
```typescript
// BAD — selectedId is in ItemList, but DetailPanel is a sibling that needs it
function Page() {
  return (
    <>
      <ItemList />       {/* selectedId stuck here */}
      <DetailPanel />    {/* can't see selectedId */}
    </>
  );
}

// GOOD — lift to the nearest common ancestor
function Page() {
  const [selectedId, setSelectedId] = useState<string | null>(null);
  return (
    <>
      <ItemList selectedId={selectedId} onSelect={setSelectedId} />
      <DetailPanel id={selectedId} />
    </>
  );
}
```

### Server state vs UI state
- **Server state** (data from API): belongs in React Query, not component state
- **UI state** (open/closed, selected tab, filter value): belongs in components, as locally as possible
- Mixing these in the same `useState` causes confusion — they have different lifetimes and update patterns

## Exercise
Given this component tree (a dashboard page):
```
DashboardPage
├── Sidebar
│   └── NavMenu
│       └── NavItem (×5)
├── MainContent
│   ├── FilterBar
│   │   ├── SearchInput
│   │   └── CategorySelect
│   └── DataGrid
│       └── DataRow (×N)
└── DetailsPanel
```

For each of these state pieces, identify the correct component level:
1. Which category is selected in `CategorySelect`?
2. The search query typed in `SearchInput`?
3. Which row in `DataGrid` is selected (needed by `DetailsPanel`)?
4. Whether `Sidebar` is collapsed?
5. The data loaded from the API displayed in `DataGrid`?

## Mastery checkpoint
1. `useState` is in a parent that renders 50 child components. Only 1 child uses the state. What is the performance consequence, and how do you fix it?
2. You move state down to colocate it. But now two distant sibling components need it. What are the two solutions and when do you use each?
3. What is the difference between "lifting state up" and "using Context"? When is each appropriate?
