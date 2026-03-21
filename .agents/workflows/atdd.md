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
- **First Principles Check**: Before authoring scenarios, independently verify the upstream spec/analysis artifact:
  1. Read the `analysis_[topic].md` or `spec_[slice].md` from the prior `/analysis` workflow.
  2. Use `grep_search` / `view_file` to confirm entities, endpoints, or DB tables mentioned in the spec actually exist in the codebase.
  3. If the spec references components that don't exist or have changed → flag the discrepancy to the user. Do not write tests against stale specs.

## Phase 2: SDET Execution

### 2a. Scenario Authoring (Write scenarios BEFORE code)

- **Requirement**: Translate business requirements into formal Gherkin scenarios (Given/When/Then).
- **Rule (Anti-Hallucination)**: Every scenario MUST include a comment citing the exact line or rule from `.agents/rules/` or the user's prompt that justifies its existence. If you cannot cite a business source, you are hallucinating it — delete it.
- **Rule (Negative Coverage)**: For each happy-path scenario, write at least one negative or boundary case (e.g., wrong role → 403, missing field → 400, duplicate entry → 409).
- **Rule (Spec-Readable Names)**: Scenario names must read like specifications a non-engineer can understand. Bad: `Test1`, `CreateStore_Works`. Good: `Auditor_Cannot_Delete_Template`, `Submission_With_Empty_Sections_Returns_ValidationError`.
- **Checkpoint**: Present the Gherkin scenarios to the user via `notify_user` for approval BEFORE writing any test code. This is the "Three Amigos" validation — catch misunderstood requirements here, not after coding.

### 2b. Test Implementation (One scenario at a time)

- **Requirement**: For each approved scenario, write the corresponding test code. Iterate vertically — one scenario → one test → verify RED → next.
- **Rule (No-Code Mandate)**: Sentinel CANNOT write or modify production code. Sentinel writes test code only.
- **Rule (Single Concern)**: Each test method tests exactly ONE acceptance criterion. Extract setup into helper methods that fail with clear messages. See `atdd-quality-gates` skill Gate 2.
- **Rule (Max Chain ≤ 5)**: A test must not contain more than 5 sequential HTTP calls or DB operations. See `atdd-quality-gates` skill Gate 2.
- **Rule (Behavior, Not Shape)**: Each test must verify a *business rule* or *user-visible behavior* — not data types, property names, or echoed input values. See `atdd-quality-gates` skill Gate 7 for examples.
- **Rule (Meaningful Assertions)**: Assertions must prove something non-trivial. `Assert.NotNull()` or `Assert.True(response.IsSuccessStatusCode)` without checking WHAT was returned are flops.
- **Rule (Test Independence)**: Each test must set up its own state. Tests MUST NOT depend on execution order or side effects of other tests.
- **Action**: Write each test, run it, confirm it fails RED for a business reason, then move to the next scenario.

### 2c. Smoke Gate (RED for the Right Reason)

> [!IMPORTANT]
> Before proceeding to Phase 3, verify that every test fails for the **right reason** — because the feature doesn't exist yet, not because the test itself is broken.

**Step 1**: Run the **Infrastructure Pre-Flight Checklist** from `atdd-quality-gates` skill Gate 1. Fix any failing checks.

**Step 2**: Run all tests and classify every failure using the **Smoke Gate Table** from `atdd-quality-gates` skill Gate 3:

| Test Name | Status | Type | Error Summary |
|-----------|--------|------|---------------|
| ... | RED | ✅ Business / ❌ Infra | ... |

**Gate verdict:**
- ✅ All failures are `Business` → proceed to Phase 2d
- ❌ Any `Infra` or `Ambiguous` failure → fix it, re-run, update the table

### 2d. Deferred Acceptance Criteria

If an AC **cannot be tested** due to a pre-existing bug or missing infrastructure, apply the **Skip-With-Reason Protocol** from `atdd-quality-gates` skill Gate 4. Never comment out tests — use `[Fact(Skip = "reason")]` (xUnit) or `it.skip()` (Vitest) so they remain visible in test reports.

### 2e. The Saboteur Protocol (Mutation Verification)

> [!CAUTION]
> AI agents act like water flowing to the path of least resistance. They will write tests that just "run" rather than tests that "mean something". To prove the tests actually enforce intent, you must perform manual mutation testing.

- **Action**: Before declaring test coverage complete, the Sentinel MUST intentionally sabotage one piece of core business logic in the source code (e.g., change a `>=` to a `<`, remove a validation check, or alter a required property).
- **Execution**: Run the tests.
- **Pass/Fail**: If the tests still PASS despite the sabotaged code, the tests are weak ("leaky container"). Sentinel must reject the tests and force the Builder to write stronger assertions. Only when the tests successfully FAIL on sabotaged code are they considered stable.
- **Cleanup**: Revert the sabotage in the source code immediately after the check.

## Phase 3: Deliverable (The Handoff)
- **Requirement**: Output the failed test evidence and specifications.
- **Action**: Create a `specs_[feature].md` artifact and commit the failing test code to the test project.
- **Infrastructure Map (MANDATORY)**: The specs artifact MUST include a Test Infrastructure Map section following the template from `atdd-quality-gates` skill Gate 5.
- **Key Principle**: The Gherkin scenarios and failing tests produced by this workflow ARE the TDD spec-tests. The Builder's `/implement` workflow should treat them as the RED starting point — go straight to GREEN, do not re-specify.
- **Handoff**: If an `implementation_plan.md` exists from a prior `/analysis` workflow, append a **Test Constraints** section listing the test names that must turn GREEN and any ATDD-specific requirements. If NO plan exists, do NOT generate one — recommend the user run `/analysis` first.