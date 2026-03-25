# Presentational vs Container Components

> Phase 4 | Topic 2

## Why this matters
Separating data-fetching logic (container) from rendering (presentational) makes components easier to test, reuse, and preview in tools like Storybook. Presentational components are pure functions of props — you can test them without mocking anything. The pattern is less strict today with hooks, but the underlying principle (separate concerns) is always valuable.

## Sub-skills to master

### The split
```typescript
// PRESENTATIONAL (dumb) — receives everything via props, emits events via callbacks
interface UserCardProps {
  name: string;
  email: string;
  avatarUrl: string;
  isOnline: boolean;
  onMessage: () => void;
}
function UserCard({ name, email, avatarUrl, isOnline, onMessage }: UserCardProps) {
  // No fetching, no state (except maybe local UI state like hover)
  // Just renders what it's given
  return (
    <div className="user-card">
      <img src={avatarUrl} alt={name} />
      <span className={isOnline ? 'online' : 'offline'} />
      <h3>{name}</h3>
      <p>{email}</p>
      <button onClick={onMessage}>Message</button>
    </div>
  );
}

// CONTAINER (smart) — fetches, manages state, passes data down
function UserCardContainer({ userId }: { userId: string }) {
  const { data: user, loading } = useQuery(['user', userId], () => fetchUser(userId));

  if (loading) return <UserCardSkeleton />;
  if (!user) return null;

  return (
    <UserCard
      name={user.name}
      email={user.email}
      avatarUrl={user.avatarUrl}
      isOnline={user.isOnline}
      onMessage={() => openMessageDialog(userId)}
    />
  );
}
```

### With hooks, the split shifts
```typescript
// Custom hooks extract the "container" logic entirely
function useUser(userId: string) {
  return useQuery(['user', userId], () => fetchUser(userId));
}

// The component can be "smart" without mixing data logic into JSX
function UserCard({ userId }: { userId: string }) {
  const { data: user, loading } = useUser(userId);
  if (loading) return <Skeleton />;
  return <div>{user?.name}</div>;
}
// Test UserCard by mocking useUser — no real network needed
```

### Why it still matters
- Presentational components are easy to use in **Storybook** (no context/fetching required)
- Presentational components are trivially testable with `render(<UserCard {...mockProps} />)`
- The principle: **don't mix fetching and rendering in the same function**

## Exercise
Take a `PostList` component that currently:
- Fetches `/api/posts` in `useEffect`
- Stores `posts`, `loading`, `error` in `useState`
- Renders a list of post cards inline

**Refactor it into:**
1. `PostCard` — presentational, typed props, no fetching
2. `PostList` — presentational, receives `posts: Post[]`, renders `PostCard` items
3. `PostListContainer` — fetches data with React Query, renders `PostList` with loading/error states

**Bonus:** Write a test for `PostList` that passes in mock data and asserts the correct number of items renders — notice how easy it is because there's no fetching involved.

## Mastery checkpoint
1. What makes a presentational component easy to test that a container is not?
2. A colleague argues: "Custom hooks make the container/presentational split obsolete." Do you agree? What does the split still give you that hooks alone do not?
3. A `Button` component has a local `isHovered` state for a visual hover effect. Is it still "presentational"? Why?
