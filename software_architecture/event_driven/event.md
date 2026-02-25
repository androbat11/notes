# Event-Driven Architecture

## What is an Event?

An **event** is a record that something happened. Past tense, immutable fact.

```
NOT a command:   "ProcessPayment"    ← telling someone what to do
NOT a query:     "GetOrderStatus"    ← asking for current state

An event:        "PaymentProcessed"  ← something that already occurred
                 "OrderPlaced"
                 "UserSignedUp"
```

An event has three characteristics:

```
┌─────────────────────────────────────────────────────┐
│  Event: OrderPlaced                                 │
│                                                     │
│  1. WHAT happened   → type: "OrderPlaced"           │
│  2. WHEN it happened→ timestamp: 2026-02-20T10:00Z  │
│  3. DATA about it   → { orderId, userId, items[] }  │
└─────────────────────────────────────────────────────┘
```

> An event describes a **fact about the past**. It cannot be undone, only reacted to.

---

## What is Event-Driven Architecture (EDA)?

A system where components communicate by **producing** and **consuming** events —
rather than calling each other directly.

### Traditional: Direct Calls (Request/Response)

```
User places order
      │
      ▼
  Order Service ──── calls ────► Payment Service
                                       │
                 ◄── response ─────────┘
      │
      ▼
  Order Service ──── calls ────► Inventory Service
                                       │
                 ◄── response ─────────┘
      │
      ▼
  Order Service ──── calls ────► Notification Service
                                       │
                 ◄── response ─────────┘
```

Problems:
- Order Service must **know about** every downstream service
- If Notification Service is down, the order fails
- Adding a new service means changing Order Service

---

### Event-Driven: Publish / Subscribe

```
User places order
      │
      ▼
  Order Service
      │
      │  publishes event: "OrderPlaced" { orderId, userId, items }
      │
      ▼
┌─────────────────┐
│   Event Broker  │  (Kafka, RabbitMQ, AWS EventBridge...)
└────────┬────────┘
         │
         ├──────────────► Payment Service    (subscribed to "OrderPlaced")
         │
         ├──────────────► Inventory Service  (subscribed to "OrderPlaced")
         │
         └──────────────► Notification Service (subscribed to "OrderPlaced")
```

Now:
- Order Service knows nothing about downstream services
- Each service reacts independently
- Adding a new service = just subscribe to the event, no changes elsewhere
- If Notification Service is down, it catches up when it comes back

---

## The Two Roles

```
┌────────────────┐         event          ┌────────────────┐
│   Producer     │  ─────────────────►    │   Consumer     │
│  (Publisher)   │                        │  (Subscriber)  │
│                │                        │                │
│ emits events   │    via Event Broker    │ reacts to      │
│ doesn't care   │                        │ events         │
│ who listens    │                        │ doesn't care   │
└────────────────┘                        │ who sent them  │
                                          └────────────────┘
```

**Producers** and **consumers** are **decoupled** — they don't know each other exist.
The broker is the only shared contract.

---

## Events vs Commands vs Queries

```
Type        Direction         Example                 Who decides what happens?
─────────   ───────────────   ─────────────────────   ─────────────────────────
Command     sender → receiver  ProcessPayment          The sender
Query       sender → receiver  GetOrderById            The sender
Event       broadcast          PaymentProcessed        The consumer (reacts freely)
```

This distinction matters: an event gives **consumers autonomy**. The producer
doesn't dictate what should happen next — it just reports what did happen.

---

## Why EDA? The Core Benefits

```
Benefit             Why
──────────────────  ────────────────────────────────────────────────────
Decoupling          Services don't call each other → easier to change
Scalability         Each consumer scales independently
Resilience          A slow/down consumer doesn't affect the producer
Extensibility       New feature = new consumer, zero changes elsewhere
Auditability        Event log = history of everything that happened
```

---

## The Trade-offs (be honest with yourself)

```
Challenge               Description
──────────────────────  ──────────────────────────────────────────────────
Eventual consistency    After "OrderPlaced", inventory isn't updated yet
Harder to debug         No single call stack — events flow asynchronously
Duplicate events        Consumers must handle receiving the same event twice
Ordering guarantees     Events may arrive out of order across partitions
Complexity              A broker is another piece of infrastructure to run
```

EDA is not always the right tool. A simple CRUD app doesn't need it.

---

## Mental Model: The Newspaper Analogy

```
                  ┌──────────────────┐
  Something       │   The Newspaper  │    Anyone who
  happens ──────► │   (Event Broker) │ ──► subscribed
  in the world    │                  │     reads it
                  └──────────────────┘

- The journalist (producer) writes what happened
- The newspaper doesn't care who reads it
- The reader (consumer) reacts in their own way
- If you miss today's paper, you can read the archive (event log)
```

---

## Key Vocabulary

| Term | Meaning |
|---|---|
| Event | Immutable record that something happened |
| Producer | Emits events |
| Consumer | Reacts to events |
| Event Broker | The middleware that routes events (Kafka, RabbitMQ, etc.) |
| Topic / Queue | Where events are published and consumed from |
| Subscription | A consumer's declaration of interest in a topic |
| Event log | Ordered, durable history of events |
| Idempotency | Ability to process the same event twice without side effects |

---

## What's Next

- `broker.md` — how event brokers work (Kafka vs RabbitMQ vs SQS)
- `patterns.md` — Saga, Event Sourcing, CQRS
- `idempotency.md` — handling duplicate events safely
- `schema.md` — designing event payloads (versioning, schema registry)
