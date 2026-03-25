# Rendering: Conditional and Lists

> Phase 2 | Topic 4

## Why this matters
React rendering is just JavaScript. Conditional rendering uses `&&`, ternary, or early return — not special syntax. List rendering uses `.map()`. The `key` prop on list items is not optional — it is how React's diffing algorithm maintains identity across renders.

## Sub-skills to master

### Conditional rendering patterns
```jsx
// && shorthand — for "show if true, nothing otherwise"
{isLoggedIn && <UserMenu />}
// WARNING: {count && <X />} renders "0" when count is 0 — always prefer:
{count > 0 && <X />}

// Ternary — for "show A or B"
{isLoading ? <Spinner /> : <Content data={data} />}

// Early return — for complex conditions
function Profile({ user }: { user: User | null }) {
  if (!user) return <p>Not logged in</p>;
  if (user.isBanned) return <p>Account suspended</p>;
  return <div>{user.name}</div>;
}

// Returning null renders nothing (valid in React)
function Badge({ count }: { count: number }) {
  if (count === 0) return null;
  return <span className="badge">{count}</span>;
}

// Storing JSX in a variable for complex conditionals
const actionButton = user.canEdit
  ? <button onClick={handleEdit}>Edit</button>
  : user.canView
  ? <button onClick={handleView}>View</button>
  : null;
return <div>{actionButton}</div>;
```

### List rendering
```jsx
// Basic list — key is required on the top-level element returned from map
{items.map(item => (
  <li key={item.id}>{item.name}</li>
))}

// Multi-element list items — Fragment with key
{items.map(item => (
  <React.Fragment key={item.id}>
    <dt>{item.term}</dt>
    <dd>{item.description}</dd>
  </React.Fragment>
))}

// Conditional item rendering inside list
{items.map(item => item.isVisible ? (
  <ListItem key={item.id} item={item} />
) : null)}

// Empty state
{items.length === 0
  ? <p className="empty">No items found</p>
  : items.map(item => <Item key={item.id} {...item} />)
}
```

### Keys
- Must be **stable**: same item always gets the same key across renders
- Must be **unique among siblings** (not globally)
- Use the item's `id` from your data — not array index
- Array index as key: only safe if list is static and never reordered/filtered

## Exercise
Build a `StatusList` component:
```typescript
interface StatusItem {
  id: string;
  label: string;
  status: 'active' | 'inactive' | 'pending';
  timestamp: string;
}
interface StatusListProps {
  items: StatusItem[];
  showInactive: boolean;
}
```

Requirements:
1. Filter out inactive items when `showInactive` is false
2. Render a different visual badge for each status (`active` = green, `pending` = yellow, `inactive` = grey)
3. Show "No items to display" when the filtered list is empty
4. Each item rendered with key on the correct element

## Mastery checkpoint
1. Why is using array index as a key dangerous when items can be **reordered or deleted**? Describe the concrete bug it causes with a text input inside each list item.
2. You have a notification that should show/hide based on a boolean. You write `{hasError && <Alert message={errorMessage} />}`. Your designer says: show a success state too. Rewrite using a ternary.
3. Why does `{0 && <Component />}` render `0` instead of nothing? How does JavaScript's `&&` operator work here?
