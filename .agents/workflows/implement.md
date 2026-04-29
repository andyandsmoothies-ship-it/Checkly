---
description: The Core Builder Implementation Workflow
---

@[.agents/rules/orchestration-standards.md]

# /implement Workflow

> [!CAUTION]
> **[TEST_FIRST_LOCK]**: PROHIBITED: Writing prod code until QA writes failing tests (unless explicitly instructed as Track B1).

## Phase 0: Init & Calibration
| Step | Execution Contract |
|---|---|
| **Context Load** | `view_file(implement.md)` -> load `@@SCAN` into active context. |
| **Governance** | Run Pre-Flight check (`governance-rules.md`). |
| **Task Tracker**| MANDATORY: Create `task_[YYYYMMDD_HHMMSS]_[ConversationID]_[topic].md` BEFORE coding. |

```markdown
# Task: [Name]
Workflow: /implement | Track: [A / B1 / B2 / C]

## Upfront
- [x] Pre-Requisite: Implementation Plan (from /analyze-feature)
- [x] Pre-Requisite: Failing Tests (from /atdd or /tdd)

## Active Slice
- [ ] Slice [N]: [Name] (Read Tests -> Code -> Verify)

## Wrap Up
- [ ] Phase 2: Self-Review
- [ ] Phase 3: Handoff -> Terminate session

## Artifacts
| Status | File Path | Type |
|---|---|---|
| [NEW] | brain/.../walkthrough_[topic].md | Result |
| [NEW] | brain/.../executed_tests_[topic].md | Test Log |
```

## Phase 1: Coding (The Builder Phase)
> **@@SCAN — Pre-Code (MANDATORY)**
> `[SCAN] Active rules: <list>` | `[SCAN] Gotchas: <list/NONE>` | `[SCAN] Active skills: <list>`

| Step | Execution Contract |
|---|---|
| **Zero-Drift Execution**| PROHIBITED: Multiple slices in a single `/implement` session. Execute EXACTLY ONE slice. **Task Runner Protocol:** Create an atomic checklist from the plan. Execute EXACTLY ONE logical block (file/test suite) per prompt turn, automatically yielding to the user after each step to prevent hallucination. Make GREEN -> Generate `handoff.md` -> YIELD. |
| **Context Blinders** | Actively ignore test contracts for future slices. |
| **Test Ingestion** | Read unit test files created by QA for the ACTIVE SLICE ONLY. |
| **Cheap Verify** | Run `flutter analyze` or `dotnet build --no-restore`. Fix before complete. |
| **Strict TDD (Legacy)**| IF altering legacy boundaries -> MANDATORY: Update legacy test FIRST (turn RED) -> THEN write PROD code (turn GREEN). |
| **Immutable Mock Guard**| PROHIBITED: Changing existing ATDD Tests to make code pass. Adapt code to existing contract. |
| **Red/Green Loop**| Turn RED test GREEN -> Refactor. Do NOT modify test files. |
| **Refactor Safety**| `grep_search` 4 ways: 1) Direct calls, 2) Types, 3) Strings, 4) Test Mocks. |
| **Mirror Trap** | PROHIBITED: GREENing a cloned/replica function in a test file. Route test to actual prod logic. |
| **State Invariants**| Explicitly verify Entry Preconditions and Exit Postconditions. |
| **Blast Radius** | IF modifying shared code -> Execute upstream regression tests. |
| **Observability & Audit**| MANDATORY: All new endpoints/actions MUST log start/finish with Correlation IDs. All manual SQL scripts or DB inserts MUST include a transaction that writes to the audit/system_logs table. |

> **@@SCAN**: (1) Red/Green respected? (2) Verify gate run? (3) Logging & Audit trails implemented?

## Phase 2: Self-Review
Review from 6 angles:
0. **Double-Check Hack**: Verify code did not violate loaded `[ACTIVE_SKILLS]`.
1. **Security/Arch**: Check illegal imports.
2. **Logic**: Null handling? Acceptance criteria?
3. **Concurrency**: Idempotency at DB/Top-layer.
4. **Coverage**: Every `[NEW]`/`[MOD]` component needs Happy, Error, Empty, and Invariant tests.
5. **Quality Gate**: Run compiler/linter. ZERO warnings allowed. Fix them before handoff.
6. **Supportability**: Is it idiomatic? Document tradeoffs in walkthrough.

| Step | Execution Contract |
|---|---|
| **Test Analytics**| Bypassing terminal limits: output tests to `.agents/tmp/results.json` and `view_file` them. |
| **Diff Check** | `git diff --name-only`. Revert unplanned. |
| **Anti-Collapse Gate**| IF any modified file >400 lines: STRICTLY PROHIBITED from handoff. You MUST halt and extract components. |
| **Handoff Trap** | IF Context Limit Approaching: Create `handoff.md` -> YIELD. |

> **@@SCAN**: (1) 4 angles reviewed? (2) State tests exist? (3) `git diff` clean? (4) File lines <400?

## Phase 3: Handoff
| State | Condition | Result Action |
|---|---|---|
| **Ship/Show** | Green TDD, Blast Radius 0 | Write FULL `walkthrough.md` + `executed_tests.md` -> Execute Verify Script. |
| **Ask** | Arch change, Security | Notify user BEFORE action. Wait go-ahead. |

### Walkthrough Schema
> [!IMPORTANT]
> Your `walkthrough_[topic].md` MUST INCLUDE the following EXACT sections:
> 1. `## Decision Log`: Proposed vs Implemented.
> 2. `## Verification Handoff`: Steps for QA.
> 3. `<test_trace>`: Raw terminal execution output from a GLOBAL test run (`dotnet test` or `flutter test`). PROHIBITED: Isolated test runs (`flutter test path/...`). You MUST prove you didn't break existing tests.
> 4. `<forensic_evidence>`: General validation commands run.
> 5. `## Gotcha Protocol`: Propose edits to the local sub-folder's `GEMINI.md` (e.g., `server/GEMINI.md` or `lib/GEMINI.md`) if new quirks found.
>
> **Script Verification Gate (MANDATORY)**: Execute via `run_command`
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`

## 🚦 User Handoff & Next Steps
> [!IMPORTANT]
> **Outputs Created:** Implemented code (GREEN) + `walkthrough_[topic].md` (or `handoff.md` if more slices remain).
>
> **HOW TO CONTINUE THE SLICING LOOP:**
>
> **Scenario A: MORE slices left in the Implementation Plan.**
> 1. Check the Implementation Plan to see the routing for the NEXT slice.
> 2. If it requires tests first (Track B2/C): Run `@[/tdd]` or `@[/atdd]`.
> 3. If it is direct implementation (Track B1/UI): Open a **NEW Builder Session** and run `@[/implement] Execute the NEXT slice from this plan: {Path}`.
>
> **Scenario B: FINAL slice (or only 1 slice).**
> 1. Open a **NEW QA Session**.
> 2. `@[/verify] {Path_to_walkthrough.md}`
> 3. If verified, manually commit via GitHub Desktop.