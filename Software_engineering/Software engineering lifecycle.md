# Software Engineering Lifecycle

The Software Engineering Lifecycle (also called **SDLC** — Software Development Lifecycle) is the structured process of planning, creating, testing, and delivering software systems.

---

## Phases

### 1. Requirements / Specification

Gathering and defining **what** the system should do.

- **Stakeholder interviews** — understand business needs
- **Functional requirements** — what the system does (features, behaviors)
- **Non-functional requirements** — how the system performs (performance, security, scalability)
- **Use cases / User stories** — describe interactions from the user's perspective
- Output: a **requirements document** or **product spec**

> Bad requirements = wasted implementation. This phase is the most critical.

---

### 2. System Design

Translating requirements into a **blueprint** for the system.

- **High-level design (HLD)** — architecture, tech stack, system components, data flow
- **Low-level design (LLD)** — class diagrams, DB schemas, API contracts, algorithms
- Decisions made here: monolith vs microservices, SQL vs NoSQL, sync vs async, etc.
- Output: **architecture document**, **ERD**, **API spec**

---

### 3. Implementation (Coding)

Writing the actual source code following the design.

- Developers implement features in **small, testable units**
- Code reviews, linting, formatting standards applied
- Version control (Git) tracks every change
- Output: **working codebase**

---

### 4. Testing & Verification

Ensuring the software behaves correctly and meets requirements.

| Type | Focus |
|------|-------|
| **Unit tests** | Individual functions/methods |
| **Integration tests** | Interaction between modules |
| **System tests** | End-to-end behavior |
| **Acceptance tests (UAT)** | Validates requirements are met |
| **Regression tests** | Ensures new changes don't break existing behavior |

- Output: **test reports**, **bug tracker**, **coverage metrics**

---

### 5. Deployment / Release

Shipping the software to production or users.

- **CI/CD pipelines** automate build, test, and deploy
- Strategies: **blue/green**, **canary releases**, **feature flags**
- Environments: dev → staging → production
- Output: **running system in production**

---

### 6. Maintenance & Evolution

Operating and improving the system after release.

- Bug fixes (corrective)
- Performance improvements (perfective)
- Adapting to new platforms/requirements (adaptive)
- Adding new features (enhancement)

> Most of a system's lifetime is spent in this phase — often 60–80% of total cost.

---

## Lifecycle Models

### Waterfall
Linear, sequential. Each phase must complete before the next begins.
- Simple to manage, but **inflexible** to change
- Works well for well-understood, stable requirements

```
Requirements → Design → Implementation → Testing → Deployment → Maintenance
```

### Iterative / Incremental
Build the system in small chunks, improving with each iteration.
- Early feedback, reduced risk
- Basis for modern agile approaches

### Agile (Scrum / Kanban)
Short cycles (**sprints**, 1–4 weeks), continuous delivery of working software.
- Adapts to changing requirements
- Close collaboration with stakeholders
- Retrospectives drive continuous improvement

### Spiral
Combines iterative development with risk analysis.
- Each loop: plan → risk analysis → develop → evaluate
- Good for high-risk, large projects

### V-Model
Extension of Waterfall where each development phase has a corresponding test phase.

```
Requirements ←→ Acceptance Testing
System Design ←→ System Testing
Detailed Design ←→ Integration Testing
Coding ←→ Unit Testing
```

---

## Key Principles Across All Phases

- **Separation of concerns** — keep unrelated things independent
- **DRY** (Don't Repeat Yourself) — avoid duplication
- **KISS** (Keep It Simple, Stupid) — prefer simplicity
- **YAGNI** (You Aren't Gonna Need It) — don't build what isn't needed yet
- **Fail fast** — surface problems early, when they're cheapest to fix
- **Continuous feedback** — requirements, testing, and deployment should loop, not be one-shot
