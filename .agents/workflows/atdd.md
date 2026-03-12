---
name: ATDD Workflow
description: Generates Gherkin Specs and Test Fixtures with Red-Green-Refactor Execution.
---

# Workflow: /atdd

> [!NOTE]
> This is the **Test-Driven Architecture** workflow — used to strictly define behavior for complex/high-risk features before coding begins.
> It sits between `/research` and `/implement`.

## Phase 1: Spec Discovery & Persona
- **Instruction**: Assume the role of **Sentinel** (Senior QA/SDET Engineer).
- **Skill Discovery**: Derive 2-3 keywords from the feature context (e.g., "scoring" → testing, validation). Use `grep_search` on `.agents/skills/` to find the most relevant testing or planning `SKILL.md` file. Load ONLY the top 1-2. Declare which skills were loaded.
- **Action**: Identify the focus area and consult relevant project workspace rules in `.agents/rules/` to confirm technical constraints.

## Phase 2: SDET Execution (Test Implementation)
- **Requirement**: Translate business requirements into strict testing scenarios AND failing test code.
- **Skill Refresh**: The concern has shifted from discovery to test authoring. Re-scan `.agents/skills/` for skills matching the specific testing framework or patterns needed (e.g., integration testing, mocking). Load 1-2 if relevant.
- **Rule (Anti-Hallucination)**: Every single Gherkin scenario MUST include a comment citing the exact line or rule from `.agents/rules/` or the User's prompt that justifies its existence. If you cannot cite a business source for the test case, you are hallucinating it and must delete it.
- **Rule (No-Code Mandate)**: Sentinel CANNOT write or modify production code. Sentinel MUST write the test code (Unit Tests, Integration Tests) that proves the production code is either missing or failing.
- **Action**: Generate formal Gherkin scenarios (Given/When/Then) with citations, then write the corresponding test fixtures in the project's testing framework. Ensure the tests fail (RED) because the feature is not implemented yet.

### 2a. RED for the Right Reason (Smoke Gate)

> [!IMPORTANT]
> **ATDD Handoff Quality Bar** — Before proceeding to Phase 3, the Sentinel MUST verify that every test fails for the **right reason**.
>
> In ATDD there is a handoff boundary between the Sentinel (test author) and the Builder (implementer). If tests fail due to infrastructure issues (DB constraints, auth failures, serialization errors), the Builder wastes entire cycles debugging problems that belong to the test author.

After writing all tests, run each test once and classify every failure:

- **Infrastructure failure** (test setup, seed data, API reachability, auth) → **Sentinel's bug — fix before handoff**
- **Business assertion failure** (expected behavior not yet implemented) → **Correct RED — ready for handoff**

**Gate verdict:**
- ✅ All RED failures are at business assertions → proceed to Phase 3
- ❌ Any infrastructure failure detected → fix it, then re-run this gate

## Phase 3: Deliverable (The Handoff)
- **Requirement**: Output the failed test evidence and specifications.
- **Action**: Create a `specs_[feature].md` artifact and commit the failing test code to the `Test` project.
- **Handoff (CRITICAL)**: Generate an `implementation_plan.md` that instructs the `/implement` Builder agent to write ONLY the application production code required to make your tests turn GREEN. **If an `implementation_plan.md` already exists from a prior `/analysis` workflow, you MUST update it to prepend your strict ATDD testing constraints.**