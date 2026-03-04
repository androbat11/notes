# Distributed Monolith

## What Is It?

A **distributed monolith** is a system that has been split into multiple services (like microservices) but still behaves as a single tightly-coupled unit. It takes on the **complexity of a distributed system** while retaining the **rigidity of a monolith** — the worst of both worlds.

You can identify it when:
- Services cannot be deployed independently (you must deploy several at once)
- Services share a database or a common data model
- A change in one service requires changes in several others
- Services call each other synchronously in long chains to fulfill a single request

## Why It Is an Anti-pattern

A distributed monolith violates the core promise of microservices: **independent deployability and isolation of failure**. Instead of gaining loose coupling, teams end up with:

- **Tight logical coupling** hidden behind network calls
- **Distributed transactions** that are hard to reason about and roll back
- **Deployment coupling** — a release requires coordinating multiple teams/services simultaneously
- **Shared data ownership** — no single service fully owns its data, leading to implicit contracts

It is the result of decomposing a monolith by **technical layer** (auth service, data service, UI service) rather than by **business capability** (order management, payment, inventory).

## Implications

### Operational
- **Higher latency**: logic that was an in-process function call is now several network hops
- **Cascading failures**: a slow or unavailable service blocks all services that depend on it
- **Complex debugging**: a single user request spans multiple services, making tracing and log correlation difficult

### Development
- **Slow releases**: deploying one feature requires coordinating multiple services and their teams
- **Integration hell**: services must be versioned together, negating independent development
- **Increased cognitive load**: developers must understand the full service graph to reason about any single change

### Data
- **Distributed transactions**: achieving consistency across services requires patterns like Saga or 2PC, both of which add significant complexity
- **Shared schema coupling**: if two services read the same database table, a schema change breaks both

## Example

```
Client → API Gateway → OrderService → InventoryService → PaymentService → NotificationService
                                           ↓
                                     (shared DB)
```

If `InventoryService` is slow, the entire chain stalls. If you need to change the order schema, all four services need updating and redeploying together. This is a monolith — it just runs over HTTP.

## How to Avoid It

- Define **bounded contexts**: each service owns its domain and data exclusively
- Prefer **async communication** (events/messages) over synchronous chained calls
- Apply the **Strangler Fig** pattern when decomposing an existing monolith — migrate by business capability, not by layer
- Use the **"independently deployable"** test: if you can't deploy a service without touching another, the boundary is wrong
