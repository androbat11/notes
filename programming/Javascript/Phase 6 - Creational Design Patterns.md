# Phase 6 — Creational Design Patterns

> Factory, Builder, Singleton, Object Pool — object creation at scale
> **Week:** 6 | **Status:** [ ] Complete

---

## Why This Phase Exists

Object creation is not just `new Foo()`. In production systems, how you create objects determines whether your code is testable, whether dependencies can be swapped, whether you control resource usage, and whether your API surface exposes implementation details. Getting object creation wrong at the design level creates systems that are rigid, hard to test, and leaky.

This phase maps directly to your backend work: service instantiation, database connection pooling, query construction, and environment-switching.

---

## Core Concepts

### Factory Function

A factory function is a plain function that returns an object. It uses closures for true private state and returns only the public interface.

**When to prefer factory functions over classes:**
- You want true private state (not `#privateField` which is still visible in DevTools)
- You don't need inheritance
- You want a clean interface — callers receive an object, not a class instance
- You want easy mocking and testing (return any object with the right shape)

```javascript
function createUserService(db, emailService) {
  // Private: not accessible from outside
  const cache = new Map();

  async function findById(id) {
    if (cache.has(id)) return cache.get(id);
    const user = await db.users.findOne({ _id: id });
    cache.set(id, user);
    return user;
  }

  async function sendWelcome(userId) {
    const user = await findById(userId);
    await emailService.send({ to: user.email, template: 'welcome' });
  }

  // Public interface only
  return { findById, sendWelcome };
}

// Usage:
const userService = createUserService(mongoDb, mailer);
userService.cache; // undefined — truly private
```

**Key advantage:** `createUserService` takes its dependencies as parameters. In tests, pass mock objects. No mocking frameworks needed.

### Abstract Factory

Creates families of related objects without specifying their concrete types. Useful for:
- Theme/environment switching (production vs test vs staging)
- Plugin systems where the plugin provides a set of related implementations
- Multi-tenant systems where behavior varies by tenant

```javascript
// Abstract factory: a function that returns a "family" of related creators
function createDatabaseFactory(env) {
  if (env === 'production') {
    return {
      createConnection: () => new MongoConnection(PROD_URI),
      createRepository: (model) => new MongoRepository(model),
      createTransaction: () => new MongoTransaction(),
    };
  }
  if (env === 'test') {
    return {
      createConnection: () => new InMemoryConnection(),
      createRepository: (model) => new InMemoryRepository(model),
      createTransaction: () => new InMemoryTransaction(),
    };
  }
  throw new Error(`Unknown environment: ${env}`);
}

const factory = createDatabaseFactory(process.env.NODE_ENV);
const conn = factory.createConnection();
const repo = factory.createRepository(UserModel);
```

### Builder Pattern

Constructs complex objects step by step with a fluent interface. The builder accumulates configuration and validates at the final `.build()` call.

**When to use:** When an object has many optional parameters, when invalid combinations must be caught, when the construction sequence matters.

```javascript
class QueryBuilder {
  #collection = null;
  #conditions = {};
  #fields     = null;
  #sortField  = null;
  #sortDir    = 1;
  #limitVal   = null;
  #skipVal    = 0;

  collection(name) { this.#collection = name; return this; }
  where(conds)     { Object.assign(this.#conditions, conds); return this; }
  select(fields)   { this.#fields = fields; return this; }
  sort(field, dir = 'asc') {
    this.#sortField = field;
    this.#sortDir   = dir === 'asc' ? 1 : -1;
    return this;
  }
  limit(n)  { this.#limitVal = n; return this; }
  skip(n)   { this.#skipVal  = n; return this; }

  build() {
    if (!this.#collection) throw new Error('Collection is required');
    return {
      collection: this.#collection,
      filter:     this.#conditions,
      projection: this.#fields,
      sort:       this.#sortField ? { [this.#sortField]: this.#sortDir } : null,
      limit:      this.#limitVal,
      skip:       this.#skipVal,
    };
  }
}

// Usage — fluent, readable, validated:
const query = new QueryBuilder()
  .collection('patients')
  .where({ status: 'active', arsCode: 'HUMANO' })
  .select(['name', 'cedula', 'plan'])
  .sort('name', 'asc')
  .limit(50)
  .skip(100)
  .build();
```

### Singleton

A class or module that ensures only one instance exists globally.

**In Node.js:** The module cache already makes this implicit — `require()` or `import` a module once; every subsequent import gets the cached instance. You can just export an instance:

```javascript
// db.js — implicit Singleton via module cache
import { MongoClient } from 'mongodb';
const client = new MongoClient(process.env.MONGO_URI);
await client.connect();
export default client; // same instance everywhere it's imported
```

**Explicit Singleton with lazy instantiation:**
```javascript
class ConfigService {
  static #instance = null;

  #config;

  constructor() {
    if (ConfigService.#instance) return ConfigService.#instance;
    this.#config = loadConfig();
    ConfigService.#instance = this;
  }

  get(key)    { return this.#config[key]; }
  set(key, v) { this.#config[key] = v; }

  static getInstance() {
    if (!ConfigService.#instance) new ConfigService();
    return ConfigService.#instance;
  }
}
```

**Warning:** Singletons are hard to test — they carry state across tests. Prefer dependency injection of a shared instance over true Singletons when testability matters.

### Object Pool

Reuse expensive-to-create objects instead of creating and destroying them on each use. Tracks available (idle) and in-use (acquired) objects.

**Use cases:** Database connections, Worker threads, HTTP connections, canvas rendering contexts.

```javascript
class PoolExhaustedError extends Error {
  constructor() { super('Object pool exhausted'); this.name = 'PoolExhaustedError'; }
}

class ObjectPool {
  #factory;
  #maxSize;
  #available = [];
  #inUse     = new Set();
  #waiters    = [];

  constructor(factory, maxSize) {
    this.#factory = factory;
    this.#maxSize = maxSize;
  }

  acquire() {
    if (this.#available.length > 0) {
      const obj = this.#available.pop();
      this.#inUse.add(obj);
      return obj;
    }
    if (this.#inUse.size < this.#maxSize) {
      const obj = this.#factory();
      this.#inUse.add(obj);
      return obj;
    }
    throw new PoolExhaustedError();
  }

  release(obj) {
    if (!this.#inUse.has(obj)) throw new Error('Object not owned by this pool');
    this.#inUse.delete(obj);

    if (this.#waiters.length > 0) {
      const resolve = this.#waiters.shift();
      this.#inUse.add(obj);
      resolve(obj);
    } else {
      this.#available.push(obj);
    }
  }

  waitForAvailable() {
    return new Promise((resolve) => this.#waiters.push(resolve));
  }

  drain() {
    this.#available = [];
    this.#inUse.clear();
    this.#waiters.forEach(resolve => resolve(null));
    this.#waiters = [];
  }

  stats() {
    return {
      available: this.#available.length,
      inUse:     this.#inUse.size,
      total:     this.#available.length + this.#inUse.size,
    };
  }
}

// Always release in finally:
const pool = new ObjectPool(() => createExpensiveResource(), 10);
const resource = pool.acquire();
try {
  await resource.doWork();
} finally {
  pool.release(resource); // never skip this
}
```

### Factory Function vs Class Constructor

| | Factory Function | Class Constructor |
|---|---|---|
| Privacy | Closure-based (true private) | `#field` (private but visible in tooling) |
| `instanceof` | Does NOT work (returns plain object) | Works |
| Inheritance | Composition (mixins) | `extends` chain |
| Interface | Returns object — implementation hidden | Returns class instance |
| `this` | Not needed inside the factory | Required; susceptible to loss |
| Testability | Swap any dependency via parameter | Requires mocking tools or DI container |

---

## Checkpoint

You must demonstrate ALL of the following before moving to Phase 7.

**Checkpoint 1 — HTTP client factory**
Build `createHttpClient(baseUrl, defaultHeaders)` that returns:
```
{ get(path, options), post(path, body, options), put(path, body, options),
  delete(path, options), addInterceptor(fn), removeInterceptor(fn) }
```
Requirements:
- All internal implementation is private — only the returned object is the interface
- Interceptors are applied to every request in the order added: `interceptor(request) → request`
- Supports cancellation via `AbortController` (each request method accepts an `options.signal`)
- `addInterceptor` and `removeInterceptor` work at any time, even mid-flight

**Checkpoint 2 — MongoDB-style QueryBuilder**
Build a `QueryBuilder` using the Builder pattern:
- Methods: `.collection(name)`, `.where(conditions)`, `.select(fields)`, `.sort(field, direction)`, `.limit(n)`, `.skip(n)`, `.build()`
- `.build()` throws a typed `QueryError` if no collection is set
- Fully chainable — every method returns `this`
- `.build()` returns a plain descriptor object (not the builder)
- Include at least one invalid-state validation beyond missing collection

**Checkpoint 3 — Generic `ObjectPool<T>`**
Build `ObjectPool` with:
- `constructor(factory, maxSize)` — `factory` is a function that creates one instance
- `acquire()` — returns an available object or throws `PoolExhaustedError` if pool is full
- `release(obj)` — returns it to the pool; throws if the object was not acquired from this pool
- `drain()` — releases all objects and resets state
- `waitForAvailable(): Promise<T>` — resolves with the next object that is released
- `stats()` — returns `{ available, inUse, total }`

Demonstrate correct behavior with a test that acquires all slots, then waits for one to be released.

---

## Connection to Your Background

- **Factory = service instantiation:** Every backend service you write in Node.js is effectively a factory function — you create services with injected dependencies and return them. The pattern is the same; this phase gives it a name and makes the design explicit.
- **Builder = query construction:** MongoDB aggregation pipelines, SISALRIL report parameters, complex filter objects — these are all Builder patterns. Making the Builder explicit (with `.build()` validation) prevents invalid queries from reaching the database.
- **Object Pool = connection pooling:** Every database driver (Mongoose, the Node.js MongoDB driver) uses an object pool internally for connections. Understanding the pool pattern explains why you set `maxPoolSize` in your connection URI, what happens when all connections are in use, and why `finally { release() }` is critical.
- **Singleton = module cache:** You've been using implicit Singletons every time you `require()` a module in Node.js. Understanding explicit Singletons explains when the implicit version is insufficient (lazy initialization, teardown logic, testing isolation).

---

## After Completing This Phase

1. What was the hardest part of Phase 6, and what specifically made it hard?
2. How would you explain the difference between a factory function and a class to a developer who defaults to `class` for everything?

Then move to [[Phase 7 - Structural Design Patterns]].
