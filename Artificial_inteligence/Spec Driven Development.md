# Spec Driven Development (SDD)

A methodology where the **specification is written first** and becomes the authoritative source of truth — before any implementation. Code must conform to the spec, not the other way around.

## Core Idea

Similar to TDD but at a higher abstraction level:

| Approach | Defines first | Then... |
|----------|--------------|---------|
| TDD | Tests (expected behavior) | Write code to pass tests |
| SDD | Formal spec (system contract) | Implementation must satisfy spec |

The key principle: *if the spec is wrong, all the code is wrong*.

## Spec Formats

- Natural language requirements (structured)
- Formal mathematical notation (Z notation, TLA+, Alloy)
- Interface definitions (OpenAPI, Protobuf, IDL)
- State machines and invariants
- Type systems and contracts

## Origins: NASA

NASA is one of the earliest and most rigorous adopters of formal specification, driven by a critical constraint: **a bug in space can kill people and cost billions**.

- **Space Shuttle flight software**: ~500,000 lines of code with less than 0.1 defects per 1,000 lines — achieved through exhaustive specification and formal review cycles
- Adopted **Cleanroom Software Engineering** (developed by Harlan Mills at IBM), which mandates formal specs before any code is written
- Used **Z notation** and **VDM** to mathematically prove correctness of specifications
- NASA's **Software Engineering Laboratory (SEL)** at Goddard produced decades of research showing spec-first approaches dramatically reduced defect rates

## Relation to AI

SDD has experienced a renaissance with LLMs for several reasons:

**AI as an implementation engine**
A precise spec becomes the prompt. The clearer and more formal the spec, the better the generated output. LLMs are essentially spec-to-code translators.

**AI needs specs to be reliable**
Vague prompts produce vague code. SDD discipline forces clear thinking *before* generation.

**Formal verification loops**
AI can now:
- Generate code from spec
- Generate tests from spec
- Verify that the code satisfies the spec
- Flag contradictions or gaps in the spec itself

## Modern SDD Workflow (AI-assisted)

```
[Natural language intent]
        ↓
[Structured spec / PRD]
        ↓
[Formal interface / contract]  ← OpenAPI, types, invariants
        ↓
[AI-generated implementation]
        ↓
[AI-generated tests against spec]
        ↓
[Automated verification]
        ↓
[Back to spec if gaps found]
```

## Key Takeaway

SDD shifts the **source of truth upstream**. Instead of inferring intent from code, the spec *is* the intent — and both humans and AI implement against it. This makes AI-generated code more reliable, reviewable, and correctable.
