# SecureCore — Backend Security Learning Roadmap

---

## Phase 1 — Foundations of Defensive Coding
> Build the security mindset and understand the most exploited vulnerability classes.

| # | Module | Key Concepts |
|---|--------|--------------|
| 1 | The Security Mindset | Threat surfaces, attacker perspective, trust boundaries |
| 2 | OWASP Top 10 | Backend-specific deep dive into each category |
| 3 | Input Validation & Sanitization | Allowlist vs denylist, Zod/Joi schema validation |
| 4 | Output Encoding | Preventing XSS and injection via proper output handling |
| 5 | Error Handling & Logging | Secure logging, never leaking stack traces |
| 6 | Dependency Security | Supply chain attacks, `npm audit`, Snyk, Socket.dev |

---

## Phase 2 — API & Authentication Security
> Secure the most exposed layer of any backend — the API surface.

| # | Module | Key Concepts |
|---|--------|--------------|
| 1 | Authentication Fundamentals | bcrypt/argon2, credential storage, brute force protection |
| 2 | JWT Deep Dive | HS256 vs RS256, refresh rotation, alg:none attack |
| 3 | OAuth 2.0 & OpenID Connect | Flows, scopes, PKCE, implicit flow dangers |
| 4 | Authorization Patterns | RBAC, ABAC, BOLA/IDOR, least privilege |
| 5 | Rate Limiting & Abuse Prevention | Throttling, account enumeration, credential stuffing |
| 6 | CORS, CSRF & Security Headers | Browser boundaries, Helmet.js configuration |

---

## Phase 3 — Data & Infrastructure Security
> Harden the layers beneath the application code.

| # | Module | Key Concepts |
|---|--------|--------------|
| 1 | MongoDB Security | `$where` injection, query sanitization, field-level encryption |
| 2 | Secrets Management | Env vars done right, HashiCorp Vault, secret rotation |
| 3 | Docker & Container Hardening | Non-root users, minimal images, read-only filesystems |
| 4 | Transport Security | TLS, HSTS, dangers of plain HTTP in microservices |
| 5 | Microservice Security Patterns | mTLS, signed JWTs, zero-trust principles |
| 6 | Healthcare Data Considerations | PHI handling, encryption at rest, audit logging |

---

## Phase 4 — Secure Architecture & Engineering Practice
> Operate as a security-aware engineer across the full development lifecycle.

| # | Module | Key Concepts |
|---|--------|--------------|
| 1 | Threat Modeling | STRIDE methodology, data flow diagrams, trust boundaries |
| 2 | Secure Design Patterns | Defense in depth, fail-secure defaults, complete mediation |
| 3 | Security in the SDLC | Shift-left security, PR checklists, security as acceptance criteria |
| 4 | Static Analysis & SAST | ESLint security plugins, Semgrep, CI/CD integration |
| 5 | Penetration Testing Awareness | How pen testers think, reading pentest reports as a dev |
| 6 | Incident Response Basics | Breach response, forensic logging, readiness |

---

**Total: 4 Phases · 24 Modules**

Each module ends with a production challenge and a 3-question mastery check before advancing.

---

## Progress Tracker

| Phase | Module | Status |
|-------|--------|--------|
| 1 | 1 — The Security Mindset | In Progress |
| 1 | 2 — OWASP Top 10 | Pending |
| 1 | 3 — Input Validation & Sanitization | Pending |
| 1 | 4 — Output Encoding | Pending |
| 1 | 5 — Error Handling & Logging | Pending |
| 1 | 6 — Dependency Security | Pending |
| 2 | 1 — Authentication Fundamentals | Pending |
| 2 | 2 — JWT Deep Dive | Pending |
| 2 | 3 — OAuth 2.0 & OpenID Connect | Pending |
| 2 | 4 — Authorization Patterns | Pending |
| 2 | 5 — Rate Limiting & Abuse Prevention | Pending |
| 2 | 6 — CORS, CSRF & Security Headers | Pending |
| 3 | 1 — MongoDB Security | Pending |
| 3 | 2 — Secrets Management | Pending |
| 3 | 3 — Docker & Container Hardening | Pending |
| 3 | 4 — Transport Security | Pending |
| 3 | 5 — Microservice Security Patterns | Pending |
| 3 | 6 — Healthcare Data Considerations | Pending |
| 4 | 1 — Threat Modeling | Pending |
| 4 | 2 — Secure Design Patterns | Pending |
| 4 | 3 — Security in the SDLC | Pending |
| 4 | 4 — Static Analysis & SAST | Pending |
| 4 | 5 — Penetration Testing Awareness | Pending |
| 4 | 6 — Incident Response Basics | Pending |
