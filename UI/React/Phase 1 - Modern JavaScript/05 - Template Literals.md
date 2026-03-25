# Template Literals and Tagged Templates

> Phase 1 | Topic 5

## Why this matters
Template literals appear constantly in React for dynamic class names, ARIA labels, error messages, and URL construction. Tagged templates power styled-components and other CSS-in-JS libraries — you need to recognize the pattern even if you do not write it often.

## Sub-skills to master
```typescript
// Basic template literal
const greeting = `Hello, ${user.name}!`;

// Multiline (no \n needed)
const html = `
  <div class="${cls}">
    ${content}
  </div>
`;

// Expressions inside ${}
const label = `${count} item${count !== 1 ? 's' : ''}`;
const url = `${BASE_URL}/users/${userId}/posts?page=${page}`;

// Function calls inside ${}
const summary = `Total: ${formatCurrency(total, 'USD')}`;

// Tagged templates — fn receives string parts and interpolated values separately
function highlight(strings: TemplateStringsArray, ...values: unknown[]) {
  return strings.reduce((result, str, i) =>
    result + str + (values[i] !== undefined ? `<mark>${values[i]}</mark>` : ''),
    ''
  );
}
const output = highlight`Hello ${name}, you have ${count} messages`;
// → "Hello <mark>Alice</mark>, you have <mark>3</mark> messages"

// styled-components tagged template (recognition pattern)
const Button = styled.button`
  color: ${props => props.primary ? 'white' : 'black'};
  background: ${props => props.primary ? 'blue' : 'grey'};
`;
```

## Exercise
**Part 1:** Write a utility function:
```typescript
function buildApiUrl(
  base: string,
  path: string,
  params: Record<string, string | number>
): string
```
- Use a template literal for path construction: `` `${base}${path}` ``
- Use `URLSearchParams` to encode the query string
- Return the full URL

Example: `buildApiUrl('https://api.example.com', '/users', { page: 2, limit: 10 })`
→ `'https://api.example.com/users?page=2&limit=10'`

**Part 2:** Write a tagged template function `sql` that:
- Takes a template literal with interpolated values
- Returns `{ query: string, params: unknown[] }` where `?` replaces each interpolation
- This is the pattern used by SQL libraries to prevent injection

```typescript
const { query, params } = sql`SELECT * FROM users WHERE id = ${userId} AND active = ${true}`;
// → { query: 'SELECT * FROM users WHERE id = ? AND active = ?', params: [userId, true] }
```

## Mastery checkpoint
When styled-components writes `` styled.div`color: ${p => p.primary ? 'blue' : 'red'}` ``, what is `styled.div` from the JavaScript perspective? What does it receive as arguments? Explain how it turns a template literal with function interpolations into a CSS string.
