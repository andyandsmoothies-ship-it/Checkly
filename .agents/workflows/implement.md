---

description: The Core Builder Implementation Workflow

---

# /implement Workflow

> [!CAUTION]

> **[TEST_FIRST_LOCK / ANTI-BIAS GATE]**: PROHIBITED: Writing prod code until QA writes failing tests (unless explicitly instructed as Track B1 / UI-Only). If you are asked to build Business Logic (Track B2/C) and failing tests do not exist yet, you MUST HALT immediately. Do not write tests yourself. Yield to the user and instruct them to run `/atdd` or `/tdd` in a separate session to prevent confirmation bias.

## Step 1: Init & Calibration

- **Context Load**: Open and view `implement.md` to load the current rules and `@@SCAN` into context.

- **Governance**: Run Pre-Flight check (`governance-rules.md`).

- **Task Tracker**: Create `docs/features/[topic]/task_[YYYYMMDD_HHMMSS].md` BEFORE writing code:

```markdown

# Task: [Name]

Workflow: /implement | Track: [A / B1 / B2 / C]

*(Note: Track A = Direct Implementation (Tests Written AFTER code). Track B/C = Acceptance/Unit Tests Written BEFORE code. Skipping tests entirely is PROHIBITED unless explicitly stated.)*

## Input Lineage

- **Source Input**: `[Absolute_Path_to_Source_File_or_Input]`

## Upfront

- [x] Pre-Requisite: Implementation Plan (from Feature Analysis)

- [x] Pre-Requisite: Failing Tests (from ATDD or TDD step)

## Active Slice

- [ ] Slice [N]: [Name] (Read Tests -> Code -> Verify)

## Wrap Up

- [ ] Step 3: Self-Review

- [ ] Step 4: Handoff -> Terminate session

## Artifacts

| Status | File Path | Type |

|---|---|---|

| [NEW] | docs/features/[topic]/walkthrough_[YYYYMMDD_HHMMSS].md | Walkthrough |

| [NEW] | docs/reports/qa/[topic]/green_test_log_[YYYYMMDD_HHMMSS].md | Test Log |

```

## Step 2: Coding (The Builder Step)

- **Pre-Code Scan**: Print into chat response: `[SCAN] Active rules: <list>` | `[SCAN] Gotchas: <list/NONE>` | `[SCAN] Active skills: <list>`.

- **Zero-Drift Execution**: PROHIBITED: Multiple slices in a single `/implement` session. Execute EXACTLY ONE slice. Create an atomic checklist from the plan. Execute EXACTLY ONE logical block (file/test suite) per prompt turn, yielding to the user after each step to prevent hallucination. Make GREEN -> Generate `handoff.md` -> YIELD.

- **Context Blinders**: Actively ignore test contracts for future slices.

- **Test Ingestion**: Read unit test files created by QA for the ACTIVE SLICE ONLY.

- **Cheap Verify**: Run `flutter analyze` or `dotnet build --no-restore`. Fix issues immediately before concluding.

- **Strict TDD (Legacy)**: IF altering legacy boundaries -> MANDATORY: Update legacy test FIRST (turn RED) -> THEN write PROD code (turn GREEN).

- **Behavior-Driven**: The upstream tests are your living documentation. Build exactly the behavior specified by the tests. Do not add speculative internal logic not proven by a test.

- **Immutable Mock Guard**: PROHIBITED: Changing existing ATDD Tests to make code pass. Adapt code to existing contract.

- **Red/Green Loop**: Turn RED test GREEN -> Refactor. Do NOT modify test files. If tests are missing, trigger the Anti-Bias Gate and STOP.

- **Refactor Safety**: `grep_search` 4 ways: (1) Direct calls, (2) Types, (3) Strings, (4) Test Mocks.

- **Zero Trust Code**: Treat all inputs as hostile. Re-validate inputs at every layer. Do not implicitly trust upstream data cleansing.

- **Mirror Trap**: PROHIBITED: GREENing a cloned/replica function in a test file. Route test to actual prod logic.

- **State Invariants**: Explicitly verify Entry Preconditions and Exit Postconditions.

- **Blast Radius**: IF modifying shared code, execute upstream regression tests.

- **Observability & Audit**: All new endpoints/actions MUST log start/finish with Correlation IDs. All manual SQL scripts or DB inserts MUST include a transaction that writes to the audit/system_logs table.

- **Mandatory Scan**: Print checklist in response: (1) Red/Green respected? (2) Verify gate run? (3) Logging & Audit trails implemented?

## Step 3: Self-Review

- **Review Angles**: Self-verify code across 6 angles: (0) Double-Check Hack (Verify loaded `[ACTIVE_SKILLS]` compliance), (1) Security/Arch (Check illegal imports), (2) Logic (Null handling, edge cases, acceptance criteria), (3) Concurrency (DB/Top-layer idempotency), (4) Coverage (Verify happy, error, empty, invariant tests for modified components), (5) Quality Gate (ZERO compiler/linter warnings allowed), (6) Supportability (Idiomatic code, document tradeoffs in walkthrough).

- **Test Analytics**: Bypassing terminal limits: output tests to `.agents/tmp/results.json` and `view_file` them.

- **Test Verification**: IF modifying business logic -> You MUST verify failing tests exist for your slice BEFORE coding. If missing, HALT and instruct user to run `@[/tdd]`. Do not write tests yourself.

- **Diff Check**: Check `git diff --name-only` (or check modified files list) and revert unplanned edits.

- **Arch Boundaries**: MANDATORY: Verify UI/presentation files do not directly import DB/API layers.

- **Orphaned Stub Check**: MANDATORY: Execute `grep_search` to ensure absolutely NO `fail('Implement...')` or placeholder stubs (e.g., `onPressed: () {}`) remain from QA or UI building in the active slice.

- **PBAC UI Validation Check**: MANDATORY: Run the PBAC UI checker to scan for unprotected widgets (advisory mode):
  // turbo
  `cmd /c python .agents/scripts/verify_pbac_ui.py --advisory`

- **Anti-Collapse Gate**: IF any modified file >400 lines: STRICTLY PROHIBITED from handoff. You MUST halt and extract components.

- **Handoff Trap**: IF Context Limit Approaching: Create `handoff.md` -> YIELD.

- **Mandatory Scan**: Print checklist in response: (1) 6 angles reviewed? (2) State tests exist AND NO orphaned stubs remain? (3) PBAC UI check executed? (4) Arch boundaries respected? (5) File lines <400?

## Step 4: Handoff


- **Ship/Show (TDD Green, Blast Radius 0)**: Write full `walkthrough_[YYYYMMDD_HHMMSS].md` + `green_test_log_[YYYYMMDD_HHMMSS].md` -> Execute Verify Script.

- **Ask (Architecture/Security Change)**: Notify user BEFORE action and wait for approval.

### Walkthrough Schema

- **Required Sections**: Walkthrough `docs/features/[topic]/walkthrough_[YYYYMMDD_HHMMSS].md` MUST contain:

  1. `## Input Lineage`: Absolute path of implementation plan.

  2. `## Decision Log`: Proposed vs Implemented designs.

  3. `## Verification Handoff`: Steps for manual/automated QA.

  4. `<test_trace>`: Raw terminal execution output from GLOBAL test run (`dotnet test` or `flutter test`). Prohibited: isolated/single test runs.

  5. `<forensic_evidence>`: General validation commands run.

  6. `## Gotcha Protocol`: Proposed additions to `GEMINI.md` in relevant sub-folders.

- **Script Verification Gate**: MANDATORY: Run verification script before concluding task:

  // turbo

  `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to task tracker .md file}"`

## 🚦 User Handoff & Next Steps

<output_schema>

- **Outputs Created**: Implemented code (GREEN) + `walkthrough_[...].md` (or `handoff_[...].md` if more slices remain).

- **Loop Progression Protocol**:

  - **Scenario A: More Slices Remain**: Check next slice's track. If Track B2/C (needs tests), run `@[/tdd]` or `@[/atdd]`. If Track B1/UI (direct), open a new Builder session and run `@[/implement]`.

  - **Scenario B: Final Slice (or only 1 slice)**: Open a new QA session and run `@[/verify] {Path_to_walkthrough.md}`. If verified, manually commit via Git client.

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>

</output_schema>
