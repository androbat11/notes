# Spec-Driven Development — Example

Spec-Driven Development (SDD) is a workflow where you write a **precise, unambiguous specification** before any code is written. The spec becomes the single source of truth for both humans and AI code generation tools.

The key idea: **if you can fully specify it, you (or an AI) can implement it correctly the first time.**

---

## Example: User Authentication Feature

We'll build a `POST /auth/login` endpoint using SDD, step by step.

---

### Step 1 — Write the Spec

Before writing any code, define the full behavior:

```markdown
## Feature: User Login

### Endpoint
POST /auth/login

### Input
{
  "email": string (required, valid email format),
  "password": string (required, min 8 chars)
}

### Behavior
1. Validate input fields. Return 400 if invalid.
2. Look up user by email. Return 401 if not found.
3. Compare password hash. Return 401 if mismatch.
   - Do NOT reveal whether email or password is wrong (security).
4. On success:
   - Generate a signed JWT (HS256, expires in 1h).
   - Return 200 with the token and user id.
5. Rate limit: max 5 failed attempts per IP per minute. Return 429 if exceeded.

### Success Response (200)
{
  "token": "<jwt>",
  "userId": "<uuid>"
}

### Error Responses
| Status | Reason                         |
|--------|-------------------------------|
| 400    | Missing or invalid input       |
| 401    | Invalid credentials            |
| 429    | Too many failed attempts       |
| 500    | Internal server error          |

### Security Constraints
- Password must never be logged.
- Tokens must be invalidated on logout (token blacklist or short TTL).
- All responses must return in constant time to prevent timing attacks.
```

---

### Step 2 — Derive Tests from the Spec

The spec makes test cases obvious — no ambiguity:

```typescript
describe("POST /auth/login", () => {
  it("returns 400 when email is missing")
  it("returns 400 when email format is invalid")
  it("returns 400 when password is shorter than 8 chars")
  it("returns 401 when user does not exist")
  it("returns 401 when password is wrong")
  it("returns 200 with a JWT token on valid credentials")
  it("returns 429 after 5 failed attempts from the same IP")
  it("does not reveal whether email or password was the cause of 401")
  it("JWT expires after 1 hour")
})
```

> Tests are not invented — they are **read directly from the spec**.

---

### Step 3 — Implement Against the Spec

With the spec in hand, implementation is straightforward (or can be delegated to an AI):

```typescript
// auth.controller.ts

import { Request, Response } from "express";
import { z } from "zod";
import { findUserByEmail } from "../services/user.service";
import { verifyPassword } from "../lib/crypto";
import { signJwt } from "../lib/jwt";
import { checkRateLimit } from "../lib/rateLimit";

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export async function login(req: Request, res: Response) {
  // Step 1: Validate input
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "Invalid input" });
  }

  const { email, password } = parsed.data;

  // Step 2: Rate limit check
  const ip = req.ip;
  const limited = await checkRateLimit(ip, { max: 5, windowMs: 60_000 });
  if (limited) {
    return res.status(429).json({ error: "Too many attempts" });
  }

  // Step 3: Lookup user + verify password
  // Return same error for both cases (spec: don't reveal which failed)
  const user = await findUserByEmail(email);
  const valid = user && (await verifyPassword(password, user.passwordHash));

  if (!valid) {
    return res.status(401).json({ error: "Invalid credentials" });
  }

  // Step 4: Issue JWT
  const token = signJwt({ userId: user.id }, { expiresIn: "1h" });

  return res.status(200).json({ token, userId: user.id });
}
```

---

### Step 4 — Validate Against the Spec

After implementation, review the code against the original spec line by line:

| Spec Requirement | Implemented? |
|-----------------|:------------:|
| Validate email format | yes (zod schema) |
| Validate password min length | yes (zod schema) |
| Return 400 on invalid input | yes |
| Return 401 for unknown email | yes (same branch as wrong password) |
| Return 401 for wrong password | yes |
| Don't reveal which field failed | yes (unified error message) |
| JWT signed, expires in 1h | yes |
| Rate limit 5 attempts / min / IP | yes |
| Return 429 when exceeded | yes |
| Password never logged | yes (not passed to logger) |

---

## Why SDD Works Well With AI

When you hand an LLM a precise spec, it can:
- Generate the **implementation** directly
- Generate all **test cases** from the spec
- **Validate** existing code against the spec
- **Catch gaps** — "your spec doesn't define what happens on DB timeout"

The spec acts as a **contract between you and the AI** — no guessing, no hallucinated behavior.

---

## SDD vs TDD

| | TDD | SDD |
|---|---|---|
| Starts with | Failing tests | Written specification |
| Primary artifact | Test suite | Spec document |
| Guides | Implementation | Tests + Implementation |
| AI-friendly | Somewhat | Very — LLMs excel at spec to code |
| Best for | Unit-level behavior | Feature-level behavior |

> They complement each other: **write the spec → derive tests (TDD) → implement**.
