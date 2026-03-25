# External State Management Overview

> Phase 3 | Topic 7 | Phase Checkpoint

## Why this matters
When your application grows beyond what component state and context can handle cleanly — multiple routes sharing state, complex async state machines, optimistic updates — you need an external store. You do not need to master both Zustand and Redux Toolkit. You need to understand the problem they solve and the mental model of each.

## Sub-skills to master

### When local state + context is not enough
- Multiple unrelated components reading the same state that changes frequently (context causes too many re-renders)
- State that outlives any single route or component lifecycle
- Complex async state machines (loading, polling, optimistic updates)
- Need for **selectors**: subscribing to only a slice of state (context lacks this)

### Zustand — lightweight, un-opinionated
```typescript
import { create } from 'zustand';

interface CartStore {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  removeItem: (id: string) => void;
  total: number; // derived
}

const useCartStore = create<CartStore>((set, get) => ({
  items: [],
  addItem: (item) => set(state => ({ items: [...state.items, item] })),
  removeItem: (id) => set(state => ({ items: state.items.filter(i => i.id !== id) })),
  get total() { return get().items.reduce((sum, i) => sum + i.price, 0); },
}));

// In a component — selector prevents re-render unless items.length changes
const itemCount = useCartStore(state => state.items.length);
const addItem   = useCartStore(state => state.addItem);
```

### Redux Toolkit — batteries-included for large apps
```typescript
// createSlice encapsulates actions + reducer + initial state
const userSlice = createSlice({
  name: 'user',
  initialState: { data: null, loading: false },
  reducers: {
    setUser: (state, action) => { state.data = action.payload; }, // Immer inside
    clearUser: (state) => { state.data = null; },
  },
});
// createAsyncThunk for async actions
// createEntityAdapter for normalized collections
```

### Key concepts
| Concept | Zustand | Redux Toolkit |
|---|---|---|
| Setup | Minimal | More boilerplate |
| Best for | Medium apps, UI state | Large apps, complex async |
| Devtools | Basic | Excellent (Redux DevTools) |
| Selectors | Inline `state =>` | `createSelector` (reselect) |
| Async | Manual | `createAsyncThunk` |

### Selectors — the critical concept
A selector is a function that reads only the part of the store a component needs. Components only re-render when their selector's return value changes. This is what context lacks.

## Exercise
Build a shopping cart using Zustand:
1. Store: `items: CartItem[]`, `discount: number` (0–100%)
2. Actions: `addItem`, `removeItem`, `updateQuantity`, `setDiscount`, `clearCart`
3. Derived: `subtotal`, `discountAmount`, `total`
4. Three separate components that each subscribe to only what they need via selectors:
   - `CartItemList` — subscribes to `items`
   - `CartSummary` — subscribes to `subtotal`, `discount`, `total`
   - `CartBadge` (in the header) — subscribes only to `items.length`

## Phase 3 Checkpoint
Refactor the Phase 2 data table:
1. Replace `useState` with `useReducer` for all table state (filter, sortField, sortDir)
2. Extract that logic into `useTableState<T>(data: T[])` returning `{ rows, filterQuery, setFilterQuery, sortField, setSortField, sortDir }`
3. Add a `useContext`-based theme toggle (light/dark) that wraps the app
4. The hook's public API should hide `dispatch` — consumers use named setter functions only
