---
name: ATDD Workflow
description: Acceptance Test-Driven Development — defines acceptance tests before implementation begins.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /atdd

> [!NOTE]
> This is the **Acceptance Test-Driven Development (ATDD)** workflow — used to define acceptance tests for complex/high-risk features before coding begins.
> It sits between `/analysis` and `/implement`. Do NOT confuse with TDD (unit tests during coding) — ATDD defines WHAT the feature must do at the acceptance level; TDD proves HOW the internal code works.

## Pre-Flight Setup
> [!IMPORTANT]
> **MANDATORY ARTIFACT**: Create `task.md` right now using this schema. Update `[ ]` → `[/]` → `[x]` continuously. Do NOT proceed until created:
> ```
> # Task: [Feature / Acceptance Test Topic]
> Workflow: /atdd | Track: [B2 / C]
> ## Phases
> - [ ] Phase 1: Spec Discovery & Persona
> - [ ] Phase 2: SDET Execution
> - [ ] Phase 3: Deliverable
> ## Artifact Inventory
> | Status | File Path | Type |
> |--------|-----------|------|
> ```

> [!IMPORTANT]
> MUST create `thinking_log_[topic].md` via `write_to_file` BEFORE writing scenarios. All internal reasoning goes here.
> **Raw Data Requirement**: Include Table: `# Test Case Derivation Data` (Columns: `Scenario Hypothesis | Rejected/Approved | Reason (Cite Rule/Spec) | Final Gherkin Title`). All reasoning must be tabulated.

## Phase 1: Spec Discovery & Persona
- **Instruction**: Assume the role of **Sentinel** (Senior QA/SDET Engineer).
- **Skill Loading (MANDATORY)**: Load the `atdd-quality-gates` skill from `.agents/skills/atdd-quality-gates/SKILL.md`. This skill contains the checklists, templates, and rules you must follow in Phase 2. Declare that it was loaded.
- **Skill Discovery**: Derive 2-3 keywords from the feature context (e.g., "scoring" → testing, validation). Use `grep_search` on `.agents/skills/` to find the most relevant testing or planning `SKILL.md` file. Load ONLY the top 1-2. Declare which skills were loaded.
- **Action**: Identify the focus area and consult relevant project workspace rules in `.agents/rules/` to confirm technical constraints.
- **First Principles Check**: Before authoring scenarios, independently verify the upstream spec/analysis artifact:
  1. Read the `analysis_[topic].md` or `specs_[slice].md` from the prior `/analysis` workflow provided by the user in this session prompt (via attachment or absolute file path).
  2. Use `grep_search` / `view_file` to confirm entities, endpoints, or DB tables mentioned in the spec actually exist in the codebase.
  3. If the spec references components that don't exist or have changed → flag the discrepancy to the user. Do not write tests against stale specs.

> **@@SCAN** Before writing scenarios, answer: (1) Did you load the `atdd-quality-gates` skill? (2) Did you verify the upstream spec against the actual codebase? (3) Were any discrepancies found?

## Phase 2: SDET Execution

### 2a. Scenario Authoring (Write scenarios BEFORE code)

- **Requirement**: Translate requirements into Gherkin scenarios (Given/When/Then).
- **Rule (Anti-Hallucination)**: Every scenario MUST cite exact line/rule from `.agents/rules/` or prompt. If no source, delete it.
- **Rule (Negative Coverage)**: For each happy-path, write ≥1 negative/boundary case (e.g. 403, 400).
- **Rule (Spec-Readable Names)**: e.g. `Auditor_Cannot_Delete_Template`. No `Test1`.
- **Checkpoint & Assumptions**: Do NOT ask user about routine optimizations.
  - Default to safest strategy based on rules.
  - Document assumptions in "Assumptions & Design Choices" block.
  - Proceed immediately to Phase 2b. Use `notify_user` ONLY for unresolvable business contradictions.

### 2b. Test Implementation (One scenario at a time)
> [!IMPORTANT]
> **@@SCAN — Pre-Test Governance Anchor (MANDATORY)**
> Before writing the first test, explicitly state all three:
> 1. **Active Platform Rules**: Which testing framework and conventions apply (xUnit, Testcontainers, AppDriver pattern etc.).
> 2. **Active Gotchas**: Any entries from your actively loaded `GEMINI.md` Context Cascade relevant to the entities or endpoints under test. Write `NONE` if none apply.
> 3. **Active Skills**: Which skills from Phase 1 are still in scope. Drop irrelevant ones now.
>
> **Required output before first test method:**
> ```
> [SCAN] Active rules: <list>
> [SCAN] Applicable gotchas: <list or NONE>
> [SCAN] Active skills: <list>
> ```
> ❌ Skipping this block is a workflow violation. Do NOT write any test code without it.



- **Requirement**: Iterate vertically: one scenario → one test → verify RED → next.
- **Rule (No-Code Mandate)**: Sentinel writes test code ONLY. No production code.
- **Rule (Single Concern)**: Test ONE acceptance criterion. Extract setup.
- **Rule (Max Chain ≤ 5)**: Max 5 HTTP/DB calls per test.
- **Rule (Behavior, Not Shape)**: Verify business rules, not property names.
- **Rule (Meaningful Assertions)**: Assert WHAT returned. No bare `Assert.NotNull()`.
- **Rule (Test Independence)**: Set up own state. No cross-test dependencies.
- **Action**: Write test, run it, confirm RED for business reason, move to next scenario.

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

> **@@SCAN** Before declaring tests complete, answer: (1) Did ALL test failures classify as Business (not Infra)? (2) Were any ACs deferred with Skip-With-Reason? (3) Did you run the Saboteur Protocol — what did you sabotage and did the tests catch it?

> [!CAUTION]
> AI agents write tests that just "run". You MUST prove they enforce intent via manual mutation testing.

- **Action**: Sentinel MUST sabotage one piece of core business logic in source code (e.g. `>=` to `<`, remove validation).
- **Execution**: Run tests.
- **Pass/Fail**: If tests PASS on sabotaged code, reject tests and write stronger assertions. Tests MUST FAIL.
- **Cleanup**: Revert sabotage in source code immediately.

> **@@SCAN**: (1) Specs include Test Infrastructure Map? (2) All tests RED for business reasons only? (3) Test Constraints appended to implementation plan?

## Phase 3: Deliverable (The Handoff)
- **Requirement**: Output failed test evidence and specifications.
- **Action**: Create `specs_[feature].md` AND `test_cases_[feature].md`. `test_cases` MUST be ONLY a raw Markdown table of approved ACs. Do not bloat specs. Commit failing tests to project.
- **Infrastructure Map**: Specs must include Test Infrastructure Map template from `atdd-quality-gates`.
- **Key Principle**: These Gherkin/failing tests ARE the ATDD spec. Builder goes straight to GREEN from here.
- **Handoff**: Inject authored test names into `implementation_plan_[topic].md` under `### ATDD Constraints`. If no plan exists, do not generate one.

> [!CAUTION]
> **Clean Handoff**: Before context limit, write `handoff_[topic].md` listing completed phases + Smoke Gate state.

## Final Phase: Script Verification Gate
Run EXACTLY:
`cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`

- Code 0 (PASS): Workflow complete. Share summary and stop.
- Code 1 (FAIL): Fix reported errors and retry.
- 2-Strike Rule: Same error fails twice → STOP. Write `handoff_[topic].md` with error. Tell user: "Hard gate blocked on: [error]".