# Phase 4 — Prototypes & The Object Model

> What classes actually are and how the engine looks up properties
> **Week:** 4 | **Status:** [ ] Complete

---

## Why This Phase Exists

The `class` keyword was introduced in ES2015. Before that, JavaScript had prototypes, and prototypes still power everything the `class` keyword does. Every time you write `class Foo extends Bar`, the engine creates a prototype chain. Every method call is a prototype chain lookup. Every `instanceof` check walks the chain.

Developers who only know `class` syntax hit walls: they cannot debug inheritance issues, they misunderstand `this`, they cannot integrate with code that uses constructor functions, and they cannot explain what their class actually compiles to. This phase builds the real mental model.

---

## Core Concepts

### The `[[Prototype]]` Internal Slot

Every JavaScript object has an internal slot called `[[Prototype]]`. It contains either a reference to another object or `null`. This is the fundamental mechanism of inheritance in JavaScript.

```javascript
const obj = {};
// obj.[[Prototype]] → Object.prototype → null
```

### Property Lookup: The Prototype Chain

When you access `obj.property`, the engine:
1. Checks the object itself for an own property named `property`
2. If not found, follows `[[Prototype]]` to the next object and checks there
3. Repeats until found or until `[[Prototype]]` is `null`
4. Returns `undefined` if not found

```javascript
const animal = { breathes: true };
const dog = Object.create(animal); // dog.[[Prototype]] = animal
dog.name = 'Rex';

dog.name;     // 'Rex' — own property
dog.breathes; // true — found on animal via prototype chain
dog.flies;    // undefined — not found anywhere in the chain
```

### `Object.create(proto)`

Creates a new object with `proto` as its `[[Prototype]]`. This is the primitive operation. Everything else (`new`, `class extends`) uses this under the hood.

```javascript
const vehicleProto = {
  start() { return `${this.make} started`; }
};

const car = Object.create(vehicleProto);
car.make = 'Toyota';
car.start(); // 'Toyota started' — found via prototype chain
```

### Constructor Functions and `new`

The `new` keyword does exactly four steps:

1. Creates a new empty object: `const instance = {}`
2. Sets the object's `[[Prototype]]` to `Constructor.prototype`: `instance.[[Prototype]] = Constructor.prototype`
3. Calls `Constructor` with `this` set to the new object: `Constructor.call(instance, ...args)`
4. Returns the new object (unless the constructor explicitly returns a different object)

```javascript
function Person(name) {
  this.name = name; // step 3: this = the new object
}
Person.prototype.greet = function() {
  return `Hi, I'm ${this.name}`;
};

const p = new Person('Manuel');
// p.[[Prototype]] === Person.prototype
// p.greet() found via prototype chain
```

### `.prototype` vs `[[Prototype]]`

These are completely different things that beginners (and many mid-level developers) conflate:

| | `.prototype` | `[[Prototype]]` |
|---|---|---|
| What it is | A property on **functions** | An internal slot on **all objects** |
| Purpose | The object that becomes `[[Prototype]]` of instances created with `new` | The actual inheritance link |
| Access | `fn.prototype` | `Object.getPrototypeOf(obj)` or `obj.__proto__` (deprecated) |
| Set by | You, when defining the function/class | The engine, when creating the object |

```javascript
function Foo() {}
const f = new Foo();

Foo.prototype          // the prototype object — has a .constructor back-link
f.__proto__            // same object as Foo.prototype — the actual [[Prototype]] link
Object.getPrototypeOf(f) === Foo.prototype // true
```

### Class Syntax Desugaring

`class` is syntactic sugar over prototype-based inheritance. The engine does the same thing:

```javascript
// Class syntax:
class Animal {
  constructor(name) { this.name = name; }
  speak() { return `${this.name} makes a sound`; }
}

// What the engine actually creates:
function Animal(name) { this.name = name; }
Animal.prototype.speak = function() { return `${this.name} makes a sound`; };
```

Methods go on `.prototype` (shared by all instances). Properties assigned in the constructor go on the instance (own properties).

### The Four `this`-Binding Rules

In priority order (highest to lowest):

**1. `new` binding:** When called with `new`, `this` = the new object being created.
```javascript
const obj = new Foo(); // this inside Foo = obj
```

**2. Explicit binding:** `.call(ctx)`, `.apply(ctx)`, or `.bind(ctx)` — `this` = `ctx`.
```javascript
fn.call(obj);  // this = obj
fn.apply(obj); // this = obj
const bound = fn.bind(obj); bound(); // this = obj, always
```

**3. Implicit binding:** Method call via dot notation — `this` = the object before the dot.
```javascript
obj.method(); // this = obj
```

**4. Default binding:** Plain function call — `this` = `undefined` (strict mode) or the global object (non-strict).
```javascript
fn(); // this = undefined (strict) or window/global (non-strict)
```

### Arrow Functions and `this`

Arrow functions have **no own `this`**. They inherit `this` lexically from the enclosing scope at the time they are defined. They cannot be bound, called with `new`, or have their `this` changed.

```javascript
class Timer {
  constructor() {
    this.seconds = 0;
  }

  start() {
    // Arrow function: this is lexically inherited from start()'s this
    setInterval(() => {
      this.seconds++; // works correctly — this = Timer instance
    }, 1000);

    // Regular function would fail:
    // setInterval(function() { this.seconds++; }, 1000); // this = undefined in strict mode
  }
}
```

### `instanceof` Operator

`instanceof` walks the prototype chain checking if `Constructor.prototype` appears anywhere:

```javascript
class Animal {}
class Dog extends Animal {}
const d = new Dog();

d instanceof Dog;    // true — Dog.prototype is in the chain
d instanceof Animal; // true — Animal.prototype is also in the chain
d instanceof Object; // true — Object.prototype is always at the end
```

### `hasOwnProperty` vs `in`

```javascript
const proto = { inherited: true };
const obj = Object.create(proto);
obj.own = true;

'own' in obj;       // true — checks the chain
'inherited' in obj; // true — found in prototype

obj.hasOwnProperty('own');       // true — only own properties
obj.hasOwnProperty('inherited'); // false — not an own property
```

### Property Descriptors

Every property has hidden attributes beyond its value:

```javascript
Object.defineProperty(obj, 'name', {
  value: 'Manuel',
  writable: false,    // cannot be reassigned
  enumerable: false,  // does not appear in for...in or Object.keys()
  configurable: false // cannot be deleted or reconfigured
});
```

### Mixins

Composing behavior without inheritance — copying properties from multiple sources:

```javascript
const Serializable = (Base) => class extends Base {
  serialize()   { return JSON.stringify(this); }
  deserialize(s){ return Object.assign(this, JSON.parse(s)); }
};

const Timestamped = (Base) => class extends Base {
  constructor(...args) {
    super(...args);
    this.createdAt = new Date();
  }
};

class Entity {}
class User extends Serializable(Timestamped(Entity)) {
  constructor(name) { super(); this.name = name; }
}
```

---

## Go Deep On

### Methods on prototype vs methods on instance

```javascript
// Method on prototype (correct)
class Dog {
  bark() { return 'woof'; } // shared — ONE function object in memory
}

// Method on instance (wrong for shared behavior)
class Dog {
  constructor() {
    this.bark = () => 'woof'; // each instance gets its OWN function — N copies
  }
}
```

With 10,000 Dog instances: prototype approach = 1 function; instance approach = 10,000 functions. The prototype exists for memory efficiency and behavior sharing.

### The three ways to access `[[Prototype]]`

```javascript
// 1. __proto__ — deprecated, but widely supported; direct access to the [[Prototype]] slot
obj.__proto__

// 2. Object.getPrototypeOf() — the correct way to read [[Prototype]]
Object.getPrototypeOf(obj)

// 3. Constructor.prototype — the object that WILL BECOME [[Prototype]] of new instances
// (only meaningful on constructor functions/classes, before new is called)
Array.prototype
```

Never use `__proto__` in production code. Use `Object.getPrototypeOf()` to read and `Object.create()` to set.

### What `new` does — full detail

```javascript
function myNew(Constructor, ...args) {
  // Step 1: create an empty object
  const instance = {};

  // Step 2: set [[Prototype]] to Constructor.prototype
  Object.setPrototypeOf(instance, Constructor.prototype);

  // Step 3: call Constructor with this = instance
  const returned = Constructor.apply(instance, args);

  // Step 4: if Constructor returned an object, use it; otherwise use instance
  return (typeof returned === 'object' && returned !== null) ? returned : instance;
}
```

### Why arrow functions cannot be constructors

Arrow functions:
1. Have no own `this` — `this` would be the outer scope's `this`, not the new instance
2. Have no `.prototype` property — so `new ArrowFn()` cannot set `[[Prototype]]` on the instance

```javascript
const ArrowFn = () => {};
ArrowFn.prototype; // undefined
new ArrowFn();     // TypeError: ArrowFn is not a constructor
```

---

## Checkpoint

You must demonstrate ALL of the following before moving to Phase 5.

**Checkpoint 1 — Three-level prototype chain with no class keyword**
Build a complete three-level inheritance chain: `Vehicle → Car → ElectricCar`.
- Use only `Object.create()` and constructor functions — NO `class`, NO `extends`
- Each level must have at least one own method
- Override a method at the `Car` level and call `super` manually (via `Vehicle.prototype.method.call(this)`)
- Demonstrate that `instanceof` correctly identifies all three levels

**Checkpoint 2 — Implement `myNew(Constructor, ...args)`**
Replicate all four steps of the `new` keyword. Your implementation must:
- Work for any constructor function
- Correctly handle constructors that return plain objects (use that return value instead)
- Correctly handle constructors that return primitives or undefined (use the created instance)
- Set the correct `[[Prototype]]`

**Checkpoint 3 — Predict `this` for 10 scenarios**
Without running the code, predict `this` for:
1. Plain function call in strict mode
2. Plain function call in non-strict mode
3. Method call via dot notation
4. `setTimeout(obj.method, 0)` — the classic `this`-loss bug
5. Arrow function inside a class method called via `setTimeout`
6. `.call(explicitCtx)`
7. Factory function (no `new`) — what is `this`?
8. Constructor called with `new`
9. `.bind(ctx)` — called later with different arguments
10. Arrow function returned from a regular method

**Checkpoint 4 — Mixin pattern**
Compose three separate behavior mixins onto any base class — no inheritance, pure composition:
- `Serializable`: adds `toJSON()` and `fromJSON(str)`
- `Timestamped`: adds `createdAt` in constructor, `updatedAt` updated on any mutation method
- `Validatable`: adds `validate()` that checks required fields defined by a static `schema`

**Checkpoint 5 — Explain the three prototype access mechanisms**
What is the difference between `obj.__proto__`, `Object.getPrototypeOf(obj)`, and `Constructor.prototype`? When is each used, why is `__proto__` deprecated, and what is the risk of using it?

---

## Connection to Your Background

- **Rust traits vs prototypes:** Rust traits are resolved at compile time — the compiler knows exactly which implementation to call. JavaScript prototype lookups happen at runtime — the engine walks the chain on every access (with inline caching to optimize repeated access, covered in Phase 5). Traits are a static dispatch mechanism; prototypes are dynamic.
- **TypeScript interfaces:** TypeScript's structural typing checks at compile time. Prototype chains are checked at runtime by `instanceof`. These are orthogonal: TypeScript's type system is erased; prototypes live in the runtime.
- **`this`-loss in callbacks:** This is the JS equivalent of capturing `self` in Rust. When you pass `obj.method` to `setTimeout`, you are detaching the function from its receiver — exactly like moving a method reference without its `self`. The solutions (`.bind()`, arrow functions) re-attach the receiver explicitly or lexically.

---

## After Completing This Phase

1. What was the hardest part of Phase 4, and what specifically made it hard?
2. How would you explain the prototype chain to a developer who has written JavaScript for two years but only used `class` syntax?

Then move to [[Phase 5 - Memory Model & V8 Internals]].
