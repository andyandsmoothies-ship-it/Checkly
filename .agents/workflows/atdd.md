---
name: ATDD Workflow
description: Acceptance Test-Driven Development — defines acceptance tests before implementation begins.
---

# Workflow: /atdd

> [!NOTE]
> This is the **Acceptance Test-Driven Development (ATDD)** workflow — used to define acceptance tests for complex/high-risk features before coding begins.
> It sits between `/analysis` and `/implement`. Do NOT confuse with TDD (unit tests during coding) — ATDD defines WHAT the feature must do at the acceptance level; TDD proves HOW the internal code works.

## Phase 1: Spec Discovery & Persona
- **Instruction**: Assume the role of **Sentinel** (Senior QA/SDET Engineer).
- **Skill Loading (MANDATORY)**: Load the `atdd-quality-gates` skill from `.agents/skills/atdd-quality-gates/SKILL.md`. This skill contains the checklists, templates, and rules you must follow in Phase 2. Declare that it was loaded.
- **Skill Discovery**: Derive 2-3 keywords from the feature context (e.g., "scoring" → testing, validation). Use `grep_search` on `.agents/skills/` to find the most relevant testing or planning `SKILL.md` file. Load ONLY the top 1-2. Declare which skills were loaded.
- **Action**: Identify the focus area and consult relevant project workspace rules in `.agents/rules/` to confirm technical constraints.

## Phase 2: SDET Execution (Test Implementation)
- **Requirement**: Translate business requirements into strict testing scenarios AND failing test code.
- **Skill Refresh**: The concern has shifted from discovery to test authoring. Re-scan `.agents/skills/` for skills matching the specific testing framework or patterns needed (e.g., integration testing, mocking). Load 1-2 if relevant.
- **Rule (Anti-Hallucination)**: Every single Gherkin scenario MUST include a comment citing the exact line or rule from `.agents/rules/` or the User's prompt that justifies its existence. If you cannot cite a business source for the test case, you are hallucinating it and must delete it.
- **Rule (No-Code Mandate)**: Sentinel CANNOT write or modify production code. Sentinel MUST write the test code (Unit Tests, Integration Tests) that proves the production code is either missing or failing.
- **Rule (Single Concern)**: Each test method tests exactly ONE acceptance criterion. If setup steps fail, they must fail with a clear message, not a raw exception. See `atdd-quality-gates` skill Gate 2 for details and examples.
- **Rule (Max Chain ≤ 5)**: A test method must not contain more than 5 sequential HTTP calls or DB operations. Beyond this, split into separate tests or extract helpers. See `atdd-quality-gates` skill Gate 2 for rationale.
- **Action**: Generate formal Gherkin scenarios (Given/When/Then) with citations, then write the corresponding test fixtures in the project's testing framework. Ensure the tests fail (RED) because the feature is not implemented yet.

### 2a. RED for the Right Reason (Smoke Gate)

> [!IMPORTANT]
> **ATDD Handoff Quality Bar** — Before proceeding to Phase 3, the Sentinel MUST verify that every test fails for the **right reason**.
>
> In ATDD there is a handoff boundary between the Sentinel (test author) and the Builder (implementer). If tests fail due to infrastructure issues (DB constraints, auth failures, serialization errors), the Builder wastes entire cycles debugging problems that belong to the test author.

**Step 1**: Run the **Infrastructure Pre-Flight Checklist** from `atdd-quality-gates` skill Gate 1. Fix any failing checks before proceeding.

**Step 2**: Run each test once and classify every failure using the **Smoke Gate Table** format from `atdd-quality-gates` skill Gate 3:

| Test Name | Status | Type | Error Summary |
|-----------|--------|------|---------------|
| ... | RED | ✅ Business / ❌ Infra | ... |

**Gate verdict:**
- ✅ All failures are `Business` → proceed to Phase 2b
- ❌ Any `Infra` or `Ambiguous` failure → fix it, re-run, update the table

### 2b. Deferred Acceptance Criteria

If an AC **cannot be tested** due to a pre-existing bug or missing infrastructure, apply the **Skip-With-Reason Protocol** from `atdd-quality-gates` skill Gate 4. Never comment out tests — use `[Fact(Skip = "reason")]` (xUnit) or `it.skip()` (Vitest) so they remain visible in test reports.

## Phase 3: Deliverable (The Handoff)
- **Requirement**: Output the failed test evidence and specifications.
- **Action**: Create a `specs_[feature].md` artifact and commit the failing test code to the `Test` project.
- **Infrastructure Map (MANDATORY)**: The specs artifact MUST include a Test Infrastructure Map section following the template from `atdd-quality-gates` skill Gate 5. This documents helper methods, seed data, auth tokens, expected response shapes, and known limitations so the Builder doesn't have to reverse-engineer the test setup.
- **Handoff (CRITICAL)**: Generate an `implementation_plan.md` that instructs the `/implement` Builder agent to write ONLY the application production code required to make your tests turn GREEN. **If an `implementation_plan.md` already exists from a prior `/analysis` workflow, you MUST update it to prepend your strict ATDD testing constraints.**