# ES Modules

> Phase 1 | Topic 4

## Why this matters
Every React file is an ES module. Every import of a component, hook, utility, or type uses ES module syntax. Understanding named vs default exports affects how you structure files, how tree-shaking works in production builds, and how to avoid circular dependency bugs.

## Sub-skills to master
```typescript
// Named exports
export const formatDate = (d: Date) => d.toISOString();
export interface User { id: string; name: string; }
export { formatDate, User }; // equivalent

// Default export
export default function MyComponent() {}

// Named imports
import { formatDate, type User } from './utils';

// Default import
import MyComponent from './MyComponent';

// Rename import
import { formatDate as fmt } from './utils';

// Namespace import
import * as utils from './utils';

// Re-export (barrel file)
export { formatDate } from './utils';
export { default as MyComponent } from './MyComponent';
export * from './types';

// Type-only import (TypeScript — erased at compile time, no runtime cost)
import type { User } from './types';

// Dynamic import (used by React.lazy)
const { default: Chart } = await import('./Chart');
// or
const LazyChart = React.lazy(() => import('./Chart'));
```

## Exercise
Create this module structure (in TypeScript):

```
src/
  types.ts          — exports interfaces: User, Post
  utils.ts          — exports named functions: formatName(user), truncate(str, len)
  components/
    UserCard.tsx    — default export component
    PostCard.tsx    — default export component
  index.ts          — barrel file re-exporting everything cleanly
```

Rules:
- `UserCard` imports `User` type with `import type`
- `PostCard` imports `Post` type with `import type`
- Both use the utils functions
- `index.ts` re-exports all components and all utils with a single clean API

Then answer: what is the tradeoff of barrel files for tree-shaking?

## Mastery checkpoint
1. What is the difference between a named export and a default export? When does each make sense?
2. When you write `import type { User } from './types'`, what does TypeScript do with this at compile time?
3. In a Vite project with React, do you need `import React from 'react'` at the top of every component file? Why or why not?
4. How does `React.lazy(() => import('./Page'))` relate to dynamic imports and code splitting?
