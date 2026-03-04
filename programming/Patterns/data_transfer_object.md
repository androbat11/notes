# Data Transfer Object (DTO)

## What is a DTO?

A **DTO** is an object that carries data between layers or systems. Nothing more.

No business logic. No methods. No behavior. Just the shape of data moving from one place to another.

```
Layer A                  DTO                   Layer B
───────────────          ──────────────────    ───────────────
Database row     ──►     { id, name, email }   ──►   HTTP response
HTTP request     ──►     { username, pass  }   ──►   Service function
Service result   ──►     { status, data    }   ──►   Controller
```

The key constraint: **the DTO matches what that layer needs, not what the database has**.

---

## Why Does It Exist?

Without DTOs, your internal data leaks everywhere:

```
// BAD — returning the raw DB document directly
const user = await db.users.findOne({ id })
return user
// Now the client sees: passwordHash, __v, createdAt, internalFlags...
// The client shape is coupled to your DB schema forever
```

With a DTO you control exactly what crosses each boundary:

```
DB Model            DTO (what client sees)
────────────────    ──────────────────────
id                  id
email               email
passwordHash        (stripped — never sent)
role                role
createdAt           (stripped — internal)
internalFlags       (stripped — internal)
__v                 (stripped — Mongoose artifact)
```

---

## DTO in TypeScript — Just Types

The simplest form of a DTO is a plain type. No logic, just a shape contract:

```ts
// What lives in the database
type UserEntity = {
  id: string
  email: string
  passwordHash: string
  role: "admin" | "user"
  createdAt: Date
  internalFlags: string[]
}

// What the HTTP response returns
type UserDTO = {
  id: string
  email: string
  role: "admin" | "user"
}
```

---

## The Mapper Function

The DTO type defines the shape. The mapper function does the transformation:

```ts
type UserEntity = {
  id: string
  email: string
  passwordHash: string
  role: "admin" | "user"
  createdAt: Date
}

type UserDTO = {
  id: string
  email: string
  role: "admin" | "user"
}

function toUserDTO(user: UserEntity): UserDTO {
  return {
    id: user.id,
    email: user.email,
    role: user.role,
    // passwordHash and createdAt are deliberately not included
  }
}
```

Usage:

```ts
const user = await db.findUser(id)     // UserEntity — internal shape
const dto = toUserDTO(user)            // UserDTO    — outbound shape
res.json(dto)                          // only safe fields leave the system
```

---

## Inbound DTO — Validating What Comes In

DTOs work in both directions. An inbound DTO shapes what you accept from the client:

```ts
// What the client sends
type CreateUserDTO = {
  email: string
  password: string
  username: string
}

// What your service actually creates (different shape)
type UserEntity = {
  id: string
  email: string
  passwordHash: string   // never accept this from outside
  username: string
  createdAt: Date
  role: "admin" | "user"
}

function fromCreateUserDTO(dto: CreateUserDTO): Omit<UserEntity, "id" | "createdAt"> {
  return {
    email: dto.email.toLowerCase().trim(),
    passwordHash: hash(dto.password),   // transform here, not in the handler
    username: dto.username,
    role: "user",                       // default — client can't set this
  }
}
```

The client cannot set `role`, `createdAt`, or `passwordHash` — they aren't in the inbound DTO.

---

## Multiple DTOs for the Same Entity

One entity often needs different shapes for different consumers:

```ts
type UserEntity = {
  id: string
  email: string
  passwordHash: string
  role: "admin" | "user"
  address: string
  phone: string
}

// Public profile — minimal info
type UserPublicDTO = {
  id: string
  email: string
}

// Admin view — more info, still no password
type UserAdminDTO = {
  id: string
  email: string
  role: "admin" | "user"
  address: string
  phone: string
}

const toUserPublicDTO = (user: UserEntity): UserPublicDTO => ({
  id: user.id,
  email: user.email,
})

const toUserAdminDTO = (user: UserEntity): UserAdminDTO => ({
  id: user.id,
  email: user.email,
  role: user.role,
  address: user.address,
  phone: user.phone,
})
```

Same source, different shapes, different audiences.

---

## Mapping Arrays

```ts
const users: UserEntity[] = await db.findAllUsers()

const dtos: UserDTO[] = users.map(toUserDTO)

res.json(dtos)
```

---

## Nested DTOs

When the entity has relations, the DTO flattens or reshapes them too:

```ts
type OrderEntity = {
  id: string
  userId: string
  items: Array<{ productId: string; quantity: number; priceAtPurchase: number }>
  createdAt: Date
  internalStatus: "queued" | "processing" | "done" | "error"
}

type OrderItemDTO = {
  productId: string
  quantity: number
  price: number          // renamed for clarity
}

type OrderDTO = {
  id: string
  items: OrderItemDTO[]
  status: "processing" | "done" | "error"   // "queued" is internal
}

function toOrderDTO(order: OrderEntity): OrderDTO {
  return {
    id: order.id,
    items: order.items.map(item => ({
      productId: item.productId,
      quantity: item.quantity,
      price: item.priceAtPurchase,
    })),
    status: order.internalStatus === "queued" ? "processing" : order.internalStatus,
  }
}
```

---

## Where DTOs Live in a Typical Flow

```
HTTP Request
    │
    ▼
┌───────────────────────────────────┐
│  Controller                       │
│  parse body → CreateUserDTO       │  ← inbound DTO (validate shape)
└──────────────────┬────────────────┘
                   │
                   ▼
┌───────────────────────────────────┐
│  Service                          │
│  fromCreateUserDTO(dto)           │  ← map to internal shape
│  → create UserEntity in DB        │
│  → return UserEntity              │
└──────────────────┬────────────────┘
                   │
                   ▼
┌───────────────────────────────────┐
│  Controller                       │
│  toUserDTO(entity)                │  ← outbound DTO (strip internals)
│  res.json(dto)                    │
└───────────────────────────────────┘
```

The service never deals with HTTP shapes. The controller never deals with raw DB entities. DTOs are the contract at each boundary.

---

## Key Takeaways

- A DTO is just a typed shape — no logic, no methods, no behavior
- It defines what data crosses a boundary, not how to process it
- Mapper functions (`toDTO`, `fromDTO`) do the translation
- Inbound DTOs protect your internals from client input
- Outbound DTOs protect your internals from leaking out
- One entity can have many DTOs — different shapes for different consumers
