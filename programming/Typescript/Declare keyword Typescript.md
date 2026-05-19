Useful libraries ship without type definitions, build tools inject globals at compile time, and legacy scripts populate `window` with values TypeScript has never seen. In all these cases, you need a way to tell the compiler what's available at runtime without reimplementing it. That's what `declare` is for.

*Important: *`When a library doesn't ship with TypeScript definitions, you can write your own using `declare`.`

## The Mental Model

TypeScript has two distinct jobs:
1. **Type-check** your source code
2. **Emit** JavaScript output

`declare` participates in job 1 only. It contributes **zero lines** to the compiled `.js` file. It is a type-system annotation — not a value, not an assignment, not a runtime instruction.

```
TypeScript source  →  [type-check]  →  [emit JS]  →  Runtime
                           ↑
                     declare lives here only
                     (disappears before emit)
```

## The Promise Model

When you write `declare const API_KEY: string`, you are making a promise to the compiler:

> "Trust me — this value exists somewhere in the runtime environment. I take responsibility for it."

TypeScript accepts the promise and moves on. It will type-check all your usages of `API_KEY` as if it were a real `string` — but it will never verify that the value actually exists.

**The compiler's job ends at the `.js` file. The runtime's job begins there.**

If you broke the promise (the value never actually lands in memory), TypeScript will not warn you. The runtime will throw — and that bug is entirely on you, the developer.

---

## Experiment 1 — Zero JS output

Write this in a `.ts` file and compile it:

```ts
declare const API_KEY: string;
```

Compiled `.js` output:
```js
// (empty)
```

Now compare with a regular `const`:

```ts
const API_KEY: string = "abc123";
```

Compiled `.js` output:
```js
const API_KEY = "abc123";
```

`declare` disappears. `const` survives. That's the architectural difference.

---

## Experiment 2 — The broken promise

This compiles without errors. Run it and watch what happens:

```ts
declare const MISSING_VALUE: string;

console.log(MISSING_VALUE.toUpperCase()); // compiles fine
```

Runtime output:
```
ReferenceError: MISSING_VALUE is not defined
```

TypeScript trusted your promise. The runtime had no idea what you were talking about.
The type-checker is not to blame — you are. You declared something that never existed.

---

## Experiment 3 — The correct pattern (keeping the promise)

The most common pattern: a build tool or HTML script tag injects the value before your JS runs. TypeScript needs to know its shape. You keep the promise by ensuring the value is injected.

```html
<!-- index.html: injects the value before your bundle loads -->
<script>
  window.API_KEY = "my-secret-key";
</script>
<script src="bundle.js"></script>
```

```ts
// TypeScript side: describes the shape, emits nothing
declare const API_KEY: string;

console.log(API_KEY); // runtime finds it on the global scope
```

---

## Experiment 4 — Extending the Window object

When a third-party script adds a property to `window`, TypeScript doesn't know about it. Accessing `window.Stripe` will error at compile time. `declare global` lets you extend the Window type:

```ts
// Without this, TypeScript errors: "Property 'analytics' does not exist on type 'Window'"
declare global {
  interface Window {
    analytics: {
      track: (event: string, props?: object) => void;
    };
  }
}

// Now TypeScript is satisfied
window.analytics.track("page_view", { path: "/home" });
```

This file must be a module for `declare global` to work — add an empty export if needed:

```ts
export {}; // makes this file a module

declare global {
  interface Window {
    analytics: {
      track: (event: string, props?: object) => void;
    };
  }
}
```

---
```ts
// file: mylib.d.ts  

declare module 'my-js-library' {  

export function doSomething(value: string): number;  

export function processData(data: object): void;  

export const VERSION: string;  

}
```

```ts
import { doSomething, VERSION } from 'my-js-library';  

console.log(doSomething("test")); // TypeScript knows this returns a number  

console.log(VERSION); // TypeScript knows this is a string
```

```ts
{  

"compilerOptions": {  

"typeRoots": ["./node_modules/@types", "./types"]  

},  

"include": ["src/**/*", "types/**/*"]  

}
```
## When to reach for declare

| Situation | Tool |
|---|---|
| CDN-loaded library (e.g. Stripe, Google Maps) | `declare const` or `declare global` |
| Build tool injects a global (e.g. Webpack `DefinePlugin`) | `declare const` |
| Third-party package ships without `.d.ts` files | `declare module` |
| Legacy script adds properties to `window` | `declare global { interface Window {} }` |

## The one-sentence summary

`declare` tells the TypeScript compiler "this value exists at runtime — I promise" and emits nothing to JavaScript, making the developer solely responsible for keeping that promise.

* Reference: https://www.convex.dev/typescript/advanced/type-operators-manipulation/typescript-declare
