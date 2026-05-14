---
title: Microservice Patterns
description: ''
author: generic-claude-agent
created: 2026-04-06T20:29:53.466605+00:00
remargin_pending: 9
remargin_pending_for:
- <unassigned>
- generic-claude-agent
remargin_last_activity: 2026-05-14T14:19:56.633313+00:00
sandbox:
- user@2026-05-14T14:19:56.633313+00:00
---

# Microservice Patterns

> A structured reference of the most important microservice patterns and the guidelines to design, build, and operate real microservices.

---

## What is a Microservice?

A microservice is an independently deployable unit of software that:
- Owns a single bounded domain of business capability
- Has its own data store (no shared databases)
- Communicates over the network via well-defined interfaces
- Can be deployed, scaled, and failed independently of all other services

```remargin
---
id: 0mp
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:29:53.465920+00:00
ack:
  - user@2026-05-14T14:19:56.633313+00:00
checksum: sha256:e3e480ae3c02ea0ef1f0471762d13f16761b8c20237200e615b6b0c38d735273
---
The "distributed monolith" warning is the most important line in this document. Most teams that fail at microservices don't fail because they picked the wrong messaging pattern — they fail because they decomposed by technical layer or duplicated shared state without enforcing ownership. The litmus test here is concrete: deployment independence. If you need to coordinate a release across two repos, you have a monolith spread across a network, which is strictly worse than a regular monolith.
```

```remargin
---
id: raa
author: user
type: human
ts: 2026-05-14T14:19:56.633313+00:00
to: [generic-claude-agent]
reply-to: 0mp
thread: 0mp
checksum: sha256:d61373dc43a36e68ff5787cd208a1cf21b0f2914c0ff51d66613a4eeab6b344a
---
Would like to explore more on this part.
```


If you can't deploy it without coordinating with another team, it's not a microservice — it's a distributed monolith.

---

## Part I — Decomposition Patterns

How to break a system into services.

### 1. Decompose by Business Capability
Split services around what the business *does*, not around technical layers.

- Map the business domain first: identify capabilities (e.g., Order Management, Inventory, Payments, Notifications)
- Each capability becomes a service boundary
- Organizational alignment: one team owns one service end-to-end (Conway's Law)

**Anti-pattern**: Decomposing by technical layer (a "UI service", a "database service") creates tight coupling and chatty calls.

### 2. Decompose by Subdomain (Domain-Driven Design)
Use DDD to find natural service boundaries.

- **Core domain** — the competitive differentiator; build it yourself
- **Supporting subdomain** — necessary but not differentiating; can be simpler
- **Generic subdomain** — commodity functionality; buy or use OSS
- **Bounded Context** — the explicit boundary within which a model applies; maps 1:1 to a service
- **Ubiquitous Language** — each service speaks its own language; translation happens at the boundary
```remargin
---
id: 0ff
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:29:53.466128+00:00
checksum: sha256:aef728a826aecf2742d5957416356e5977959dcfe8e20e37a34b0c1c20523076
---
The Strangler Fig is underused in practice. Most teams default to a big-bang rewrite when the monolith becomes painful, which is almost always a mistake. The Strangler Fig requires more discipline — maintaining the facade, managing two codepaths, resisting the urge to "just finish the migration" — but it keeps the system shippable at every point. The key insight is that the facade isn't temporary scaffolding; it's the migration strategy itself. Teams that treat it as a short-term hack tend to collapse it too early.
```


### 3. Strangler Fig Pattern
Incrementally migrate a monolith to microservices without a big-bang rewrite.

```
Client → [Facade/Proxy] → legacy monolith
                        ↘ new microservice (for migrated capability)
```

- Route traffic for new or migrated capabilities to the new service
- Legacy code shrinks over time until it can be decommissioned
- Safe, reversible, no downtime required

### 4. Anti-Corruption Layer (ACL)
When integrating with legacy systems or external APIs, never let their model pollute yours.

- Add a translation layer at the boundary
- Your service speaks its own domain model internally
- The ACL converts to/from the foreign model at the edge

> **Reading — Decomposition & DDD**
> - *Building Microservices* — Sam Newman (Ch. 2–3) — the definitive guide to finding service boundaries
> - *Domain-Driven Design* — Eric Evans — the source of Bounded Contexts, Ubiquitous Language, and subdomains
> - *Implementing Domain-Driven Design* — Vaughn Vernon — more practical than Evans; covers Bounded Contexts in depth
> - *Team Topologies* — Skelton & Pais — how team structure shapes service boundaries (Conway's Law in practice)
> - *Monolith to Microservices* — Sam Newman — entirely focused on the Strangler Fig and safe migration strategies

---

## Part II — Communication Patterns

How services talk to each other.

### 5. Synchronous Communication — REST / gRPC

**REST (HTTP/JSON)**
- Simple, universal, human-readable
- Use for external-facing APIs and request/response where the client needs an immediate answer
- Design around resources, not RPCs
```remargin
---
id: 0ws
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:29:53.466355+00:00
checksum: sha256:bd3d9a77823cafb7fd0813c2d39b45182c9441391d5d652c5c5c511f438ffb7e
---
The distinction between commands and events deserves emphasis beyond what the table captures. Commands imply intent directed at a specific receiver and carry an expectation of action. Events are facts — they describe what happened, not what should happen next. Conflating them leads to brittle systems: if an "event" is actually a disguised command to one specific consumer, adding a second consumer breaks the semantic contract. The discipline of naming — OrderPlaced vs. PlaceOrder — forces the right thinking at design time.
```

- Stateless: no session state on the server

**gRPC (HTTP/2 + Protobuf)**
- Strongly typed contracts via `.proto` files
- Lower latency and payload size than REST/JSON
- Bidirectional streaming
- Better for internal service-to-service calls with high throughput requirements
- Generates client/server code automatically

**When NOT to use synchronous calls**:
- When the called service can be down (creates cascading failures)
- When you don't need the result immediately
- When the operation is long-running

### 6. Asynchronous Messaging
Services communicate by publishing and consuming messages/events.

**Message broker** (Kafka, RabbitMQ, NATS):
- Producer publishes a message and moves on
- Consumer processes at its own pace
- Decouples services in time and availability

**Two styles**:
- **Commands**: directed at one service, expect an action (`PlaceOrder` → Order Service)
- **Events**: broadcast what happened, anyone can react (`OrderPlaced` → Inventory, Notifications, Analytics)

**Guarantee levels**:
- At-most-once: fast, may lose messages
- At-least-once: safe default; consumers must be idempotent
- Exactly-once: complex, usually avoided; use idempotency instead

### 7. Event-Driven Architecture
Services react to domain events rather than being called directly.

```
Order Service publishes → "OrderPlaced"
  ↳ Inventory Service (reserve stock)
  ↳ Notification Service (send confirmation email)
  ↳ Analytics Service (record metric)
```

- Loose coupling: Order Service has no knowledge of downstream consumers
- Easy to add new consumers without modifying the publisher
- Trade-off: harder to trace end-to-end flow; requires good observability

### 8. API Gateway
Single entry point for all clients; sits in front of all services.

Responsibilities:
- Request routing to the correct service
- Authentication and authorization
- Rate limiting and throttling
- SSL termination
- Request/response transformation
- Caching

```
Client → [API Gateway] → Service A
                       → Service B
                       → Service C
```

**Do not**: put business logic in the gateway. It should be a thin routing/policy layer.

### 9. Backend for Frontend (BFF)
A dedicated API gateway per client type (mobile, web, third-party).

```
Mobile App  → [Mobile BFF]  → services
Web App     → [Web BFF]     → services
Partner API → [Partner BFF] → services
```

- Each BFF is tailored to the needs of its client
- Avoids a bloated general-purpose gateway
- Owned by the frontend team

```remargin
---
id: 56k
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:30:10.226812+00:00
checksum: sha256:8645ad1fafe0d620662d8e220cf7f2682b132fd755c10bf3855d0a1f25786bf2
---
The choreography vs. orchestration tradeoff deserves more weight than the table gives it. Choreography feels clean at first — no central coordinator, pure loose coupling — but debugging a distributed saga stuck mid-way is extremely hard without purpose-built tooling. You end up reconstructing the orchestration logic in your head from event logs. Orchestration adds coupling to the orchestrator, but makes the business process visible and testable as a unit. Practical rule: use orchestration for anything involving money, inventory, or user-visible state. Choreography is fine for analytics pipelines and notification side-effects where a missed step isn't catastrophic.
```

### 10. Service Mesh
Infrastructure layer that handles all service-to-service communication concerns.

- Sidecar proxy (e.g., Envoy) deployed alongside each service instance
- Handles: mTLS encryption, retries, timeouts, circuit breaking, load balancing, observability
- Services themselves are unaware of the mesh
- Examples: Istio, Linkerd, Consul Connect

> **Reading — Communication**
> - *Building Microservices* — Sam Newman (Ch. 4–5) — REST vs messaging, sync vs async tradeoffs
> - *Enterprise Integration Patterns* — Hohpe & Woolf — the canonical catalog of messaging patterns (commands, events, channels, routers)
> - *Designing Distributed Systems* — Brendan Burns (free PDF, O'Reilly) — covers the sidecar, ambassador, and adapter patterns
> - *REST in Practice* — Webber, Parastatidis, Robinson — REST beyond CRUD; hypermedia and resource design
> - gRPC documentation + *gRPC: Up and Running* — Kasun Indrasiri — for internal high-performance service communication
>
> **Mental model**: Think of synchronous calls as a phone call (both parties must be available) and async messaging as postal mail (sender moves on; receiver handles it when ready). Every architectural choice in this section is a consequence of that distinction.

---

## Part III — Data Management Patterns

How to handle data in a distributed system.

### 11. Database per Service
Each service owns its own database. No service may directly access another service's database.

```remargin
---
id: dz7
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:30:10.227131+00:00
checksum: sha256:745eca9dd522e999858bc9c76c15beaf1cfcc0f7515fd1b94ceea850af0f81d5
---
The Outbox is the most commonly skipped pattern here and the one with the worst consequences when missing. The dual-write problem (write to DB, then publish to broker) looks harmless in a happy path — it almost always works — which is exactly why teams skip the Outbox. The failure surfaces when the broker is briefly unavailable, the process crashes between the two writes, or a network partition occurs. At that point you have either a ghost event or silent data loss, neither of which is easily detectable without audit tooling. If a service publishes events tied to DB writes, the Outbox is non-negotiable.
```

```
Order Service    → orders_db    (PostgreSQL)
Inventory Service → inventory_db (MongoDB)
User Service     → users_db     (PostgreSQL)
```

- Schema changes in one service never break another
- Each service can choose the right database type for its workload
- Enforces true encapsulation

**How to join data across services**: You don't — you use API calls or events to compose data, or you maintain a read model (see CQRS).

### 12. Saga Pattern
Managing distributed transactions across multiple services without two-phase commit (2PC).

Two implementations:

**Choreography-based Saga** (event-driven):
```
Order Service → "OrderCreated" event
  → Payment Service: charge card → "PaymentProcessed"
  → Inventory Service: reserve stock → "StockReserved"
  → Shipping Service: schedule shipment
```
Each service listens for an event, acts, and publishes the next event. If any step fails, it publishes a failure event triggering compensating transactions.

**Orchestration-based Saga** (command-driven):
```
Saga Orchestrator:
  1. Command PaymentService: charge card
  2. Command InventoryService: reserve stock
  3. Command ShippingService: schedule shipment
  4. On failure: issue compensating commands in reverse
```
A central orchestrator (not a god service — just coordination logic) drives the saga steps.

| | Choreography | Orchestration |
|--|--|--|
| Coupling | Low (event-driven) | Higher (orchestrator knows steps) |
| Visibility | Hard to trace | Easy to trace |
| Complexity | Distributed logic | Centralized logic |
| Best for | Simple flows | Complex, long-running flows |

### 13. CQRS — Command Query Responsibility Segregation
```remargin
---
id: 1x8
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:30:10.227455+00:00
checksum: sha256:f58760aa1c2e8a0b42bfc7a15c5b218114e75783f8cbf1461411a3f844eee874
---
Bulkheads are consistently underimplemented relative to circuit breakers, probably because the failure mode is less obvious. A circuit breaker trips when a downstream service is clearly failing. A bulkhead protects against a downstream that is *slow but not failing* — the more dangerous scenario, because it silently exhausts a shared thread pool without triggering obvious alerts. Thread pool isolation per dependency is the right default and most frameworks (resilience4j, for instance) make it easy to configure. There's little reason not to have it.
```

Separate the write model (commands) from the read model (queries).

```
Write path: Command → [Command Handler] → write DB (normalized)
Read path:  Query  → [Query Handler]   → read DB (denormalized, optimized)
```

- Read model is updated asynchronously via events from the write side
- Read model can be a different database type entirely (e.g., Elasticsearch for search)
- Enables independent scaling of reads and writes
- Trade-off: eventual consistency between write and read models

### 14. Event Sourcing
Store the full history of state changes as a sequence of events, not just current state.

```
events table:
  OrderCreated   { id: 1, items: [...] }
  ItemAdded      { id: 1, item: "Widget" }
  PaymentTaken   { id: 1, amount: 50.00 }
  OrderShipped   { id: 1, tracking: "XYZ" }
```

- Current state is derived by replaying events
- Complete audit log by default
- Enables temporal queries ("what was the state at time T?")
- Natural fit with CQRS
- Trade-off: querying current state requires projection; schema evolution is hard

### 15. Outbox Pattern
Guarantees that a database write and a message publish happen atomically — without distributed transactions.

```
Within a single DB transaction:
  1. Write business data to main table
  2. Write event/message to outbox table (same DB, same transaction)

Background process (relay):
  3. Reads from outbox table
  4. Publishes to message broker
  5. Marks outbox record as sent
```

- Solves the dual-write problem: no risk of writing to DB but failing to publish (or vice versa)
- Uses the DB's own ACID guarantees

> **Reading — Data Management**
> - *Designing Data-Intensive Applications* — Martin Kleppmann — the single best book on distributed data; covers replication, consistency, transactions, and event streams
> - *Database Internals* — Alex Petrov — deep dive into how storage engines work; builds intuition for why "database per service" matters
> - "Sagas" — Garcia-Molina & Salem (1987 paper) — the original academic source; short and readable
> - *Patterns of Enterprise Application Architecture* — Martin Fowler — covers CQRS, event sourcing, and related patterns with concrete examples
>
> **Mental model**: Your services share *events*, not *data*. Each service owns its own table of truth; the rest of the system sees only the signals it emits. CQRS and Event Sourcing are both consequences of taking that ownership seriously.

---

## Part IV — Reliability Patterns

How to prevent and contain failures.

### 16. Circuit Breaker
Stop calling a failing service to give it time to recover.

States:
```
CLOSED  → normal operation, calls pass through
OPEN    → service is failing, calls are rejected immediately (fail fast)
HALF-OPEN → after timeout, allow a probe request; if it succeeds → CLOSED
```

- Prevents cascading failures
- Reduces load on a struggling downstream service
- Libraries: `resilience4j` (JVM), `tokio` + custom, `hystrix` (legacy)

### 17. Retry with Exponential Backoff + Jitter
Retry transient failures, but don't hammer the service.

```
attempt 1: wait 100ms
attempt 2: wait 200ms
attempt 3: wait 400ms + random jitter (±50ms)
attempt 4: wait 800ms + jitter
...give up after N attempts
```

- Jitter prevents the "thundering herd" when all clients retry simultaneously
- Only retry idempotent operations
- Set a max retry budget — don't retry indefinitely

### 18. Bulkhead
Isolate failures to a partition; prevent a failure in one area from draining all resources.

- Thread pool bulkheads: separate thread pools per downstream dependency
- Connection pool bulkheads: separate connection pools per service
- If the Payment service is slow, it only exhausts its own thread pool — it cannot starve the Inventory calls
- Named after ship compartments: one flood doesn't sink the whole ship

### 19. Timeout
Every network call must have a timeout. No exceptions.

- Set timeouts at every service boundary
- Differentiate: connection timeout (how long to wait to connect) vs read timeout (how long to wait for a response)
- Combine with circuit breakers: repeated timeouts should trip the breaker

### 20. Rate Limiting & Throttling
Protect services from being overwhelmed.

- **Rate limiting**: limit how many requests a client can make (e.g., 1000 req/min per API key)
- **Throttling**: shed load when capacity is exceeded (drop or queue requests)
- Implemented at the API Gateway or service mesh level
- Use token bucket or leaky bucket algorithms

### 21. Health Check API
Every service exposes endpoints to report its own health.

- `/health/live` — is the process alive? (used by Kubernetes liveness probe)
- `/health/ready` — is the service ready to receive traffic? (readiness probe)
- `/health/startup` — has the service finished initializing? (startup probe)

Readiness should check: DB connection, message broker connection, dependent services.

> **Reading — Reliability**
> - *Release It!* — Michael Nygard — coined the circuit breaker and bulkhead patterns for software; mandatory reading
> - *Site Reliability Engineering* — Google SRE Book (free online) — the canonical source for error budgets, SLOs, and operating at scale
> - *Chaos Engineering* — Casey Rosenthal & Nora Jones — the discipline of deliberately injecting failure to validate resilience
> - *The Art of Scalability* — Abbott & Fisher — capacity planning and architecture for growing systems
>
> **Mental model**: Every reliability pattern is a form of *blast radius control*. Circuit breakers stop failure from spreading upstream. Bulkheads stop it from spreading sideways. Timeouts stop it from spreading in time. Designing for resilience means asking: "if this component dies, what is the largest possible damage?"

---

## Part V — Observability Patterns

You can't manage what you can't measure.

### 22. Distributed Tracing
Track a single request as it flows across multiple services.

- Inject a `trace-id` and `span-id` into every request at the entry point
- Propagate headers through every downstream call
- Each service records its span (start time, end time, metadata)
- Visualize the full call tree in tools like Jaeger, Zipkin, Tempo
- Standard: OpenTelemetry (vendor-neutral)

### 23. Centralized Logging
Aggregate logs from all services into one queryable store.

- Structured logging only: JSON, not free-text strings
- Every log line must include: `service`, `trace_id`, `span_id`, `level`, `timestamp`, `message`
- Never log sensitive data (PII, passwords, tokens)
- Stack: Elasticsearch + Logstash + Kibana (ELK), or Loki + Grafana
- Correlation: use `trace_id` to find all logs for a single request across all services

### 24. Metrics & Alerting
Expose and collect quantitative measurements from every service.

**The Four Golden Signals** (Google SRE):
1. **Latency** — how long requests take (p50, p95, p99)
2. **Traffic** — how much demand is there (requests/sec)
3. **Errors** — rate of failed requests (5xx, timeouts)
4. **Saturation** — how close to capacity (CPU %, memory %, queue depth)
```remargin
---
id: 5dz
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:31:40.424841+00:00
checksum: sha256:b24792f678c9a050d68f1c5db248506c6ed0f100e7d2f44382c64b342dd841ee
---
Among the Four Golden Signals, Saturation is consistently the most neglected. Latency, traffic, and errors are easy to instrument and alert on. Saturation requires knowing what the *binding constraint* is for each service — CPU? Memory? DB connection pool? Kafka consumer lag? Queue depth? The answer differs per service and can shift over time, so you can't define a generic Saturation metric. It has to be chosen deliberately per service. Teams that skip this end up with services that degrade gracefully right up until they don't, with no leading indicator.
```


- Expose metrics in Prometheus format (`/metrics` endpoint)
- Scrape with Prometheus, visualize with Grafana
- Alert on symptoms (user-facing SLOs), not causes

### 25. Service-Level Objectives (SLOs)
Define reliability targets explicitly.

- **SLI** (Service Level Indicator): a specific metric — e.g., "% of requests that succeed in < 200ms"
- **SLO** (Service Level Objective): the target — e.g., "99.9% of requests succeed in < 200ms over 30 days"
- **SLA** (Service Level Agreement): a contract with consequences
- **Error budget**: `100% - SLO%` — the allowed downtime/failure; spend it on risk (deploys, experiments)

> **Reading — Observability**
> - *Observability Engineering* — Charity Majors, Liz Fong-Jones, George Miranda — the modern take on o11y; argues for high-cardinality events over metrics
> - *Distributed Systems Observability* — Cindy Sridharan (free O'Reilly ebook) — short, dense primer on logs, metrics, and traces; good starting point
> - OpenTelemetry documentation — the vendor-neutral standard; understand it before picking a vendor
> - *The Site Reliability Workbook* — Google (free online) — practical SLO implementation with worked examples
>
> **Mental model**: A monolith fails in place — you can attach a debugger. A distributed system fails invisibly across machines. Observability is your substitute for the debugger: you can't reproduce prod, so you must be able to *ask arbitrary questions* about what happened. Logs answer "what", metrics answer "how much", traces answer "where in the flow". You need all three.

---

## Part VI — Deployment Patterns

How to release microservices safely.

### 26. Blue-Green Deployment
Run two identical production environments; switch traffic between them.

```
Blue  = current live version (v1)
Green = new version (v2)

Deploy v2 to Green → run smoke tests → flip load balancer → Blue becomes standby
```

- Zero-downtime deployments
- Instant rollback: flip back to Blue
- Doubles infrastructure cost during transition

### 27. Canary Release
Gradually roll out a new version to a subset of users.

```
v1 → 100% traffic
v2 → 1% traffic  (watch for errors)
v2 → 10% traffic (still healthy)
v2 → 100% traffic (full rollout)
```

- Reduces blast radius of bad deployments
- Requires feature flagging or traffic splitting at the gateway/mesh level
- Automated rollback if error rate or latency crosses threshold

```remargin
---
id: 6b8
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:31:45.558647+00:00
checksum: sha256:4a508a63818eabdb6b570c6b1fb461b43b993d715183e397a925f930ce620e84
---
Canary releases only work if you have the discipline to act on the signals. The hard part isn't the traffic split — most service meshes and gateways make that trivial. The hard part is defining the rollback threshold *in advance* and automating it. Teams that do manual canary analysis invariably let confirmation bias creep in: the elevated error rate is "probably just noise." Automated rollback triggered by a pre-agreed threshold removes that cognitive load and makes the whole strategy credible.
```

### 28. Sidecar Pattern
Attach auxiliary functionality to a service as a co-located proxy/agent.

- Sidecar runs in the same pod/VM as the main service
- Handles: logging, metrics collection, service mesh proxy, config reload
- The main service stays lean and focused on business logic
- Examples: Envoy (service mesh), Filebeat (log shipping), Vault Agent (secret injection)

### 29. Service Discovery
Services find each other dynamically; no hardcoded addresses.

**Client-side discovery**: client queries a registry and load-balances itself
**Server-side discovery**: a load balancer queries the registry on behalf of the client

- Registry: Consul, Kubernetes DNS, Eureka
- In Kubernetes: services are discovered via DNS (`http://order-service.default.svc.cluster.local`)

> **Reading — Deployment**
> - *Continuous Delivery* — Jez Humble & David Farley — the foundational text; defines the deployment pipeline and release strategies
> - *Kubernetes in Action* — Marko Luksa — comprehensive and practical; covers pods, deployments, health probes, and service discovery
> - *The DevOps Handbook* — Kim, Humble, Debois, Willis — cultural and organizational context for continuous deployment
> - *Accelerate* — Forsgren, Humble, Kim — the research behind DORA metrics; empirical evidence for what deployment practices actually improve outcomes
>
> **Mental model**: Every deployment pattern is a strategy for decoupling *releasing code* from *releasing risk*. Blue-green separates the act of deploying from the act of going live. Canary separates going live from going live *for everyone*. Feature flags separate going live from *activating the feature*. Stack these to reduce blast radius.

---

## Part VII — Security Patterns

### 30. Token-Based Authentication (JWT / OAuth2)
- Services are stateless: no session state
- Client authenticates once with an Identity Provider → receives a JWT
- JWT is passed with every request; services validate the token signature without calling the IdP
- Use short-lived access tokens + refresh tokens
- Never roll your own auth; use proven libraries and IdPs (Keycloak, Auth0, Okta)

### 31. mTLS (Mutual TLS) for Service-to-Service
- Both sides of a connection present certificates
- Guarantees: you know exactly which service is calling you
- Handled transparently by a service mesh (Istio, Linkerd)
- Never trust internal network traffic by default (zero-trust)

### 32. Secrets Management
- Never store secrets in environment variables in plain text, config files, or container images
- Use a secrets manager: HashiCorp Vault, AWS Secrets Manager, Kubernetes Secrets (encrypted at rest)
- Rotate secrets automatically; services fetch them at startup or via sidecar injection
- Audit all secret access

> **Reading — Security**
> - *OAuth 2 in Action* — Justin Richer & Antonio Sanso — the most thorough treatment of OAuth2 flows and JWT; understand this before implementing auth
> - *Zero Trust Networks* — Evan Gilman & Doug Barth — the philosophy behind mTLS and why "trust the internal network" is a broken assumption
> - *Security Engineering* — Ross Anderson (free online) — broad foundation; relevant chapters on authentication, protocols, and distributed systems
>
> **Mental model**: The perimeter security model assumes the internal network is safe. Microservices kill that assumption — every service is a potential lateral movement vector. mTLS means *every service proves its identity on every call*, not just at the edge. Zero trust is the only coherent answer to a network you don't fully control.

---

## Part VIII — Guidelines for Building Real Microservices

These are the non-negotiable practices, not patterns — the engineering standards that make the above patterns work in production.

### Service Design
- **Single Responsibility**: one service owns one business capability, end-to-end
- **Right-size the service**: if you're constantly deploying two services together, merge them; if a service has too many responsibilities, split it
- **Own your data**: never share a database between services; no exceptions
- **Design for failure**: assume every downstream call will fail; build resilience in
- **Idempotency**: all mutation operations should be safe to retry with the same input
- **Versioning**: version your APIs from day one; never break existing consumers

### API Design
- Use OpenAPI/Protobuf to define contracts before writing code
- Backwards-compatible changes only in existing versions (add fields, never remove)
- Provide a machine-readable schema consumers can validate against
- Return meaningful error responses: status code + error code + message + trace ID

### Data
- Each service has its own schema; no foreign keys across service boundaries
- Treat your service's public API as a contract; treat your database schema as a private implementation detail
- Use the Outbox Pattern for any event publishing tied to a database write
- Design for eventual consistency; don't assume immediate consistency across services

### Resilience
- Every network call: set a timeout, add retries (with backoff + jitter), and wrap with a circuit breaker
- Test failure modes explicitly: inject faults, simulate slow dependencies (chaos engineering)
- Implement graceful degradation: if a non-critical dependency fails, serve a degraded response rather than an error

### Observability (non-negotiable)
- Structured JSON logs on every service — no plain text
- Distributed tracing propagated on every inbound and outbound call
- Expose Prometheus metrics; alert on the Four Golden Signals
- Every service must have a `/health/ready` and `/health/live` endpoint

### Deployment
- Every service must be deployable independently without coordination
- Containerize everything (Docker); orchestrate with Kubernetes
- Use a CI/CD pipeline: every merge to main triggers build → test → deploy to staging → promote to production
- All configuration via environment variables or a config service; no hardcoded config in the binary
- Run at least 2 replicas in production for availability

### Testing Strategy
```
Unit tests         → fast, in-process, no dependencies
Integration tests  → test one service with its real DB and dependencies
Contract tests     → verify API contracts between producer/consumer (Pact)
End-to-end tests   → minimal; only for critical user journeys
```
- Consumer-driven contract testing prevents integration surprises without expensive E2E suites

### Organizational
- **You build it, you run it** — the team that builds a service is on-call for it
- **Team topology**: each service is owned by one team; no shared ownership
```remargin
---
id: q6k
author: generic-claude-agent
type: agent
ts: 2026-04-06T20:31:50.783678+00:00
checksum: sha256:cfd40444a4e4e611ce5602b1b741c9b7b6486a9d41db040486624e79d8db850d
---
"You build it, you run it" is the organizational principle that makes every reliability pattern in Part IV actually get implemented. Circuit breakers, bulkheads, and timeouts tend to be skipped when a separate ops team absorbs the on-call pain. When the team that ships the code is also paged at 2am, the calculus changes immediately. This isn't just cultural preference — it's the feedback loop that keeps reliability work prioritized against feature pressure. Without it, the guidelines in Part VIII read like nice-to-haves.
```

- **Runbooks**: every service has documented on-call procedures for common failure modes
- **Post-mortems**: blameless analysis of every production incident

---

## Pattern Quick Reference

| Category | Pattern | Problem it Solves |
|---|---|---|
| Decomposition | Business Capability | Where to draw service boundaries |
| Decomposition | Strangler Fig | Migrating a monolith safely |
| Communication | API Gateway | Single entry point, auth, routing |
| Communication | BFF | Client-specific API shape |
| Communication | Saga | Distributed transactions |
| Communication | Event-Driven | Loose coupling between services |
| Data | Database per Service | Data isolation and encapsulation |
| Data | CQRS | Separate read/write scaling |
| Data | Event Sourcing | Audit trail, temporal state |
| Data | Outbox Pattern | Atomic DB write + event publish |
| Reliability | Circuit Breaker | Prevent cascading failures |
| Reliability | Retry + Backoff | Handle transient failures |
| Reliability | Bulkhead | Isolate failure blast radius |
| Reliability | Timeout | Prevent indefinite blocking |
| Observability | Distributed Tracing | Trace requests across services |
| Observability | Centralized Logging | Unified, queryable log store |
| Observability | Metrics + SLOs | Define and measure reliability |
| Deployment | Blue-Green | Zero-downtime releases |
| Deployment | Canary | Gradual, safe rollouts |
| Deployment | Sidecar | Offload cross-cutting concerns |
| Security | mTLS | Zero-trust service identity |
| Security | JWT / OAuth2 | Stateless authentication |
| Security | Secrets Management | Secure credential handling |

---

## Study Questions

Use these to test understanding, not recall. If you can't answer without hesitation, re-read the relevant section.

### Decomposition
1. You have an e-commerce app with a single `orders` table that stores order status, payment status, and shipping status. How do you decompose it into services — and where exactly do you draw the boundaries?
2. Two teams keep deploying their services together because a schema change in one always requires a change in the other. What does this symptom tell you about the decomposition, and how do you fix it?
3. When would you choose Strangler Fig over a targeted rewrite of a module? What signals tell you which is appropriate?
4. What is the difference between a Bounded Context and a microservice? Can one Bounded Context span multiple services? Can one service span multiple Bounded Contexts?

### Communication
5. A client needs data from three services to render a single page. You could make three sequential REST calls, fan out in parallel, or use a BFF. Walk through the trade-offs of each.
6. Service A calls Service B synchronously. Service B is slow. How does this propagate into a failure of Service A, and what patterns prevent it?
7. You need to send a confirmation email after an order is placed. The email service is sometimes unavailable. Should this be a synchronous call or an async event? Justify your choice and describe the failure modes of the approach you pick.
8. What is the difference between a *command* and an *event* in async messaging? Give a concrete example where conflating them would cause a bug.

### Data Management
9. The Inventory Service needs to know the customer's shipping address, which is owned by the User Service. You cannot share databases. What are your options, and what are the consistency trade-offs of each?
10. Walk through a choreography-based Saga for placing an order: Payment fails after Inventory has already reserved stock. What compensating transactions are needed, and who triggers them?
11. Why is two-phase commit (2PC) generally avoided in microservices? What problem does the Saga pattern solve that 2PC would solve differently?
12. You switch from storing current state to Event Sourcing. How do you handle a schema change to an old event type that was recorded two years ago?
13. A developer proposes writing to the database and then publishing to Kafka in the same code path (no Outbox). What failure scenarios does this create?

### Reliability
14. Your circuit breaker is OPEN. A new request arrives. What happens, and why is that behavior better than letting the request through?
15. You add retries to a payment endpoint. Why is this dangerous without idempotency, and how do you make the endpoint idempotent?
16. Service A has a thread pool of 50 threads. It calls both Service B and Service C. Service C becomes slow and all 50 threads block waiting on it. What happens to calls to Service B, and what pattern prevents this?
17. What is the "thundering herd" problem in the context of retries, and how does jitter specifically address it?

### Observability
18. A user reports that checkout is slow. You have logs, metrics, and traces. Describe the exact sequence of tools and queries you use to diagnose the problem.
19. Your p99 latency SLO is 500ms. Your p50 is 80ms. What does this gap tell you, and what kinds of problems produce it?
20. Why is structured (JSON) logging strictly better than plain-text logging in a microservices context? Give a concrete scenario where plain-text fails.
21. You have an SLO of 99.9% availability over 30 days. How many minutes of downtime is your error budget? If you depleted 80% of it in week 1, what should that trigger?

### Deployment
22. You deploy v2 of a service using Blue-Green. After the traffic switch, you discover v2 has a data migration that wrote incompatible records to the database. Can you roll back? What should you have done differently?
23. Your canary is at 5% traffic. The error rate for the canary is 0.8% vs 0.1% for stable. Is this signal enough to roll back? What additional signals would you look at?
24. How does the Sidecar pattern let you add mTLS to a service without changing its code?

### Security
25. A JWT's signature is valid but its `exp` claim is one hour in the past. Should the service accept it? Where exactly in the request path is this validated?
26. You rotate a database password. Which services need to be restarted, and how do Vault's dynamic secrets reduce that operational cost?
27. Why is "trust traffic from inside the VPC" not a valid security model for microservices?

### Cross-cutting / Design Thinking
28. You're designing a new feature that spans three services. A colleague proposes a shared library that all three import to avoid duplicating logic. What are the hidden coupling risks, and when (if ever) is a shared library the right call?
29. A service is slow. You have three levers: scale horizontally (add replicas), optimize the code, or cache responses. How do you decide which to pull first?
30. A post-mortem reveals that a cascading failure took down four services because none of them had timeouts set on their database connections. Write the one-sentence rule this incident should produce, and identify which section of Part VIII it belongs under.

---

## Progress Tracker

- [ ] Decomposition Patterns
- [ ] Communication Patterns
- [ ] Data Management Patterns
- [ ] Reliability Patterns
- [ ] Observability Patterns
- [ ] Deployment Patterns
- [ ] Security Patterns
- [ ] Building Real Microservices — Guidelines
