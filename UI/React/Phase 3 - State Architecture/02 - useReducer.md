# useReducer

> Phase 3 | Topic 2

## Why this matters
When state logic becomes complex — multiple sub-values, transitions that depend on multiple pieces of current state — `useReducer` brings the clarity of an explicit state machine. As a TypeScript engineer, discriminated union action types make all valid transitions explicit and compiler-checked. The reducer is a pure function you can test independently.

## Sub-skills to master
```typescript
// Shape
const [state, dispatch] = useReducer(reducer, initialState);

// Define state and action types
interface State {
  count: number;
  step: number;
  history: number[];
}

type Action =
  | { type: 'INCREMENT' }
  | { type: 'DECREMENT' }
  | { type: 'SET_STEP'; payload: number }
  | { type: 'RESET' };

// Pure reducer function — no side effects, no async, returns new state
function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'INCREMENT':
      return {
        ...state,
        count: state.count + state.step,
        history: [...state.history, state.count + state.step],
      };
    case 'DECREMENT':
      return { ...state, count: state.count - state.step };
    case 'SET_STEP':
      return { ...state, step: action.payload };
    case 'RESET':
      return initialState;
    default:
      // TypeScript exhaustiveness check
      const _exhaustive: never = action;
      return state;
  }
}

// Dispatching
dispatch({ type: 'INCREMENT' });
dispatch({ type: 'SET_STEP', payload: 5 });
```

### useState vs useReducer decision
| Use `useState` when | Use `useReducer` when |
|---|---|
| Simple primitive values | Multiple related fields |
| Independent pieces of state | Next state depends on multiple current values |
| Simple toggle / counter | Named transitions are clearer than setter calls |
| < 2 state transitions | Complex transitions (form steps, async states) |

## Exercise
Build a multi-step checkout form using `useReducer`:

**State:**
```typescript
type Step = 'cart' | 'shipping' | 'payment' | 'confirmation';
interface CheckoutState {
  step: Step;
  cart: { id: string; name: string; qty: number }[];
  shipping: { name: string; address: string; city: string } | null;
  payment: { cardLast4: string } | null;
}
```

**Actions:**
- `NEXT_STEP` / `PREV_STEP`
- `SET_SHIPPING` with payload
- `SET_PAYMENT` with payload
- `RESET`

Requirements:
- `NEXT_STEP` from `'payment'` goes to `'confirmation'` only if `shipping` and `payment` are set
- Reducer is pure — no side effects
- Exhaustive switch (TypeScript `never` check)
- Extract the reducer and types to a separate file

## Mastery checkpoint
1. The reducer is a pure function. What does that mean, and why does it matter for testing and debugging?
2. Why can't you do async work (like `await fetch(...)`) inside a reducer?
3. `dispatch` always returns `void`. How do you perform a side effect (e.g. navigate to a new route) after a successful state transition?
4. Compare: `setUser({ ...user, name: 'Alice' })` vs `dispatch({ type: 'UPDATE_NAME', payload: 'Alice' })`. When is the latter worth the extra code?
