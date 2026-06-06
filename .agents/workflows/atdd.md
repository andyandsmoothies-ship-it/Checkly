---

description: Acceptance Test-Driven Development — defines acceptance tests BEFORE implementation begins.

---

# Workflow: /atdd

> [!TIP]

> **The Two Loops of TDD (Inner vs Outer)**

> - True Test-Driven Development consists of two loops. This workflow handles the **Outer Loop** (Acceptance TDD / BDD), defining **WHAT** the system must do at the business level before an implementation plan is finalized.

> - Use the `/tdd` workflow for the **Inner Loop** (Programmer-level TDD), testing **HOW** the logic works based on a specific implementation plan.

> - *Note: BDD was originally created as a vocabulary shift for TDD to get people to focus on "behavior" rather than "testing". Keep that focus here.*

> [!NOTE]

> **Universal ATDD for All Projects (Web, Mobile, APIs, DBs)**

> * **Frontend (React, Flutter, Vue)**: Write test stubs for user flows, mock visual clicks, and layout structures *before* building the actual screens.

> * **Backend (Node, C#, Python)**: Declare endpoint request schemas, write stub actions, and assert failing HTTP responses *before* writing controller handlers.

> * **Database & Analytics**: Seed target data, specify mock tables/columns, and run empty/boundary calculations *before* optimizing OLAP queries.

> * **The Immutable Rule**: Code the *failing expectation* first (RED) to act as a clear contract for the developer.

> [!NOTE]

> This is ATDD (Acceptance Test-Driven Development). Goal: Define WHAT the feature must do at the acceptance level. Target Persona: **Sentinel** (QA).

## Step 1: Pre-Flight

- **Task Tracking**: MANDATORY: Create `docs/features/[topic]/task_[topic]_[YYYYMMDD_HHMMSS].md` using the strict schema below BEFORE proceeding.

```markdown

# Task: [Feature / Acceptance Test Topic]

Workflow: /atdd | Track: [B2 / C]

## Input Lineage

- **Source Input**: `[Absolute_Path_to_Source_File_or_Input]`

## Steps

- [ ] Step 2: Spec Discovery & Persona

- [ ] Step 3: SDET Execution

- [ ] Step 4: Deliverable

## Artifact Inventory

| Status | File Path | Type |

| [NEW]  | docs/qa/contracts/[topic]/test_contracts_[YYYYMMDD_HHMMSS].md | Contracts |

```

## Step 2: Spec Discovery

> [!IMPORTANT]

> PROHIBITED: Starting scenarios without completely understanding the upstream spec.

- **Skill Load**: MANDATORY: Load `atdd-quality-gates` skill.

- **Verification**: MANDATORY: Read upstream `implementation_plan_[topic]_[YYYYMMDD_HHMMSS].md`. Execute `grep_search` / `view_file` to confirm existing entities. **Exception:** If the plan explicitly defines a NET-NEW API route/feature to be built, do NOT flag its absence as an error. Your job is to write the failing test for it (Red Step). For existing dependencies that are missing, IF discrepancy THEN Flag to user → STOP.

- **Origin Idea Alignment**: MANDATORY: Read the `[ORIGIN_IDEA]` tag. You must evaluate if the upstream plan actually solves the human's goal. Then, your test scenarios MUST explicitly assert that the original business goal is achieved. Prove the business value, not just the compiler state.

- **Gap Analysis**: MANDATORY: Play the Adversary. Ask: "What boundary limits, concurrency flaws (double-clicks), timeouts, or hostile bypasses did the spec miss?" Define minimally 2 ACs that are NOT explicitly requested by the spec to act as an edge-case safety net.

- **@@SCAN**: You MUST print this checklist directly into your chat response to the user before proceeding to the next step. (1) `atdd-quality-gates` loaded? (2) API routes confirmed in BOTH server/ and lib/? (3) Discrepancies found? (4) Gap Analysis ACs defined?

## Step 3: SDET Execution

### 2a. Scenario Authoring (BEFORE Code)

- **Citation**: MANDATORY: Every scenario MUST cite exact line/rule from `.agents/rules/` or prompt. IF no source THEN Delete.

- **Coverage**: MANDATORY: `Happy-path >= 1` AND `Negative/Boundary >= 1`.

- **Naming**: MANDATORY: Spec-readable (e.g., `Auditor_Cannot_Delete_Template`).

- **Gherkin Formatting**: MANDATORY: All Acceptance Criteria in your deliverables MUST be written in strict Gherkin logic (`Given [state] When [action] Then [result]`). This creates an immutable business contract that Product Owners can read.

- **Anti-Collision**: MANDATORY: Create a NEW, tightly-scoped test file per feature slice (e.g., `UpdateUser_Jwt_Tests.cs`). PROHIBITED: Appending multiple scenarios to mega-files (e.g., `UpdateUserTests.cs`).

### 2b. Test Implementation (Iterative Loop)

> **MANDATORY @@SCAN — Pre-Test Governance Anchor**: You MUST print this checklist directly into your chat response. State before first test:

> `[SCAN] Active rules: <list>`

> `[SCAN] Applicable gotchas: <list or NONE>`

> `[SCAN] Active skills: <list>`

- **Role Limits**: PROHIBITED: Writing production code. Sentinel writes test code ONLY.

- **Execution**: MANDATORY: Loop `One scenario` -> `One test` -> `Verify RED` -> `Next`.

- **Assertions**: MANDATORY: Assert WHAT returned. PROHIBITED: Bare `Assert.NotNull()`. Max 5 HTTP/DB calls per test.

- **No Existence-Only Tests**: PROHIBITED: Writing tests that only verify imports/existence (e.g. `expect(MyClass, isNotNull)`). Every test must verify at least one behavioral output (UI rendering, mock API calls, or state changes).

### 2c. Smoke Gate (Red for the Right Reason)

- **Pre-Flight**: Run Infrastructure Checklist from `atdd-quality-gates` Gate 1.

- **Classification**: Run all tests natively exporting to files (e.g., `.NET`: `scripts\CollectTestResults.ps1`, `Flutter`: `flutter test --machine > .agents/tmp/out.json`). Read the file and classify failures -> Table `Test Name | Status | Type | Error Summary`.

- **Gate Verdict**: IF (All == Business) -> Proceed to 2d. IF (Any == Infra/Ambiguous) -> Fix -> Re-run. **WARNING:** Watch out for the "False RED" Trap (e.g., test fails with `400 BadRequest` because the test data payload is structurally invalid, rather than failing at the final business assertion). If caught in a False RED, fix the test payload to bypass initial validation and re-run.

### 2d/2e. Deferred ACs & Saboteur Protocol

- **Skip Protocol**: IF AC cannot be tested (bug/missing infra) THEN `Fact(Skip="reason")`. PROHIBITED: Commenting out tests.

- **Sabotage Test**: MANDATORY: Mutate core business logic (e.g. `>=` to `<`) -> Run Tests -> IF Tests PASS -> Reject tests & rewrite stronger. THEN Revert sabotage.

- **@@SCAN**: You MUST print this checklist directly into your chat response. (1) All failures classified as Business? (2) Any ACs deferred? (3) Saboteur Protocol run results?

## Step 4: Deliverable (Handoff)

- **Artifact Form**: Create `specs_[feature].md` & `test_cases_[feature].md` (Markdown table of approved ACs in strict Given/When/Then format). MANDATORY: Both files MUST include an `## Input Lineage` block at the top containing the absolute path of the upstream plan.

- **Metadata**: Append `Test Infrastructure Map` to Specs.

- **Clean Handoff**: Complete block below -> YIELD.

## 🚦 User Handoff & Next Steps

> [!IMPORTANT]

<output_schema>

> **Outputs Created:** Physical test files (RED) + `test_contracts_[YYYYMMDD_HHMMSS].md`.

>

> **YOUR NEXT COMMAND:** (Do not send test logs to Builder)

> - Switch to Forge Builder and type: `@[/implement] this [INSERT THE EXACT RELATIVE PATH OF THE ORIGINAL implementation_plan YOU WERE GIVEN]`

> [!IMPORTANT]

> **Update docs/features/[topic]/task_[topic]_[YYYYMMDD_HHMMSS].md**: Convert `[/]` to `[x]` and detail absolute file paths.

> **Document Cleanup (Required)**:
> Automatically clean up and organize newly created markdown plans into their correct topic folders:
> // turbo

> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`

> - `Code 0`: *"Workflow complete. Tell user to pass test artifacts to Builder."*

> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>

</output_schema>
