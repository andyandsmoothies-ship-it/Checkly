---
description: The Core Builder Implementation Workflow
---

@[.agents/rules/orchestration-standards.md]

# /implement Workflow

> [!CAUTION]
> **[PHASE_2.5_YIELD_LOCK]**: PROHIBITED: Executing entire workflow in a single run. MANDATORY: Yield at **Phase 2.5**. PROHIBITED: Writing prod code (Phase 3) until QA writes tests.

## Phase 0: Init & Calibration
| Step | Execution Contract |
|---|---|
| **Context Load** | `view_file(implement.md)` -> load `@@SCAN` into active context. |
| **Governance** | Run Pre-Flight check (`governance-rules.md`). |
| **Task Tracker**| MANDATORY: Create `task_[ConversationID].md` BEFORE coding. |

```markdown
# Task: [Name]
Workflow: /implement | Track: [A / B1 / B2 / C]

## Upfront
- [ ] Phase 1: Deep Discovery
- [ ] Phase 2: Planning & Slicing
- [ ] Phase 2.5: QA TDD Execution (Via QA session)

## Active Slice
- [ ] Slice [N]: [Name] (Read Tests -> Code -> Verify)

## Wrap Up
- [ ] Phase 4: Self-Review
- [ ] Phase 5: Handoff -> Terminate session

## Artifacts
| Status | File Path | Type |
|---|---|---|
| [NEW] | brain/.../walkthrough_[topic].md | Result |
| [NEW] | brain/.../executed_tests_[topic].md | Test Log |
```

## Phase 1: Deep Discovery
| Step | Execution Contract |
|---|---|
| **Topology** | Parse config files (`.csproj`, `pubspec.yaml`). |
| **Step 0 Nuke** | IF structure refactor -> Remove unused imports/dead code first. |
| **Skill Load** | Load `tdd`. IF `dotnet` THEN Load `testing-strategy`. Load 2 dynamic skills. |

> **@@SCAN**: (1) Skills loaded? (2) Core files scanned?

## Phase 2: Planning
| Step | Execution Contract |
|---|---|
| **Plan Check**| IF `implementation_plan.md` exists -> Execute Quality Checklist. ELSE -> generate lightweight plan -> Yield. |
| **Verification Pledge**| Declare terminal validation commands (e.g. `flutter test`) upfront. |
| **JIT Harness** | Declare `[ACTIVE_SKILLS]` at the top of the plan. Drop all other context. |
| **ATDD Ingestion**| Read existing `.md` test contracts and physical test files. |
| **Trust But Verify**| Spot-check 1 core plan claim via `grep_search` before coding. |
| **YAGNI Gate** | IF feature adds unrequested complexity -> Create tradeoff table. |

### Plan Quality Checklist
- [ ] Goal stated?
- [ ] JIT Harness (`[ACTIVE_SKILLS]`) declared?
- [ ] File delta (`[NEW]`, `[MOD]`, `[DEL]`) defined?
- [ ] DB/Schema migrations handled?
- [ ] Blast radius identified?
- [ ] Verification steps concrete?

> **@@SCAN**: (1) Passes Plan Checklist? (2) Spot-check Result? (3) Passes YAGNI?

## Phase 2.5: QA TDD Handoff (MANDATORY YIELD)
> [!CAUTION]
> **Anti-Bias Protocol:** Builder CANNOT write own tests.
| Step | Execution Contract |
|---|---|
| **Artifact Create**| Write `test_contracts_[topic].md` to brain dir. Format: `ID`, `Exact Text`, `State Matrix`, `Why RED`. |
| **Execution Lock**| PROHIBITED: Entering Phase 3 without TDD execution. Output block below -> YIELD. |

> [!IMPORTANT]
> **YOUR NEXT COMMAND:** 
> - Switch to Sentinel QA: `@[/tdd] Execute test authoring based on this contract: {Path_to_test_contracts.md}`
> - Once `/tdd` is complete, return here and type: `Here is the result of tdd. Go.`

## Phase 3: Coding
> **@@SCAN — Pre-Code (MANDATORY)**
> `[SCAN] Active rules: <list>` | `[SCAN] Gotchas: <list/NONE>` | `[SCAN] Active skills: <list>`

| Step | Execution Contract |
|---|---|
| **Zero-Drift Execution**| PROHIBITED: Multiple slices in a single `/implement` session. Execute EXACTLY ONE slice. Read Active Slice tests -> Code -> Make GREEN -> Generate `handoff.md` -> YIELD. |
| **Context Blinders** | Actively ignore test contracts for future slices. |
| **Test Ingestion** | Read unit test files created by QA for the ACTIVE SLICE ONLY. |
| **Cheap Verify** | Run `flutter analyze` or `dotnet build --no-restore`. Fix before complete. |
| **Immutable Mock Guard**| PROHIBITED: Changing existing ATDD Tests to make code pass. Adapt code to existing contract. |
| **Red/Green Loop**| Turn RED test GREEN -> Refactor. Do NOT modify test files. |
| **Refactor Safety**| `grep_search` 4 ways: 1) Direct calls, 2) Types, 3) Strings, 4) Test Mocks. |
| **State Invariants**| Explicitly verify Entry Preconditions and Exit Postconditions. |
| **Blast Radius** | IF modifying shared code -> Execute upstream regression tests. |

> **@@SCAN**: (1) Red/Green respected? (2) Verify gate run?

## Phase 4: Self-Review
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
| **Test Analytics**| Bypassing terminal limits: output tests to `results.json` and `view_file` them. |
| **Diff Check** | `git diff --name-only`. Revert unplanned. |
| **Handoff Trap** | IF Context Limit Approaching: Create `handoff.md` -> YIELD. |

> **@@SCAN**: (1) 4 angles reviewed? (2) State tests exist? (3) `git diff` clean?

## Phase 5: Handoff
| State | Condition | Result Action |
|---|---|---|
| **Ship/Show** | Green TDD, Blast Radius 0 | Write FULL `walkthrough.md` + `executed_tests.md` -> Execute Verify Script. |
| **Ask** | Arch change, Security | Notify user BEFORE action. Wait go-ahead. |

### Walkthrough Schema
> [!IMPORTANT]
> Your `walkthrough_[topic].md` MUST INCLUDE: 
> 1. `## Decision Log`: Proposed vs Implemented.
> 2. `## Verification Handoff`: Steps for QA.
> 3. `<test_trace>`: Raw terminal execution output (`dotnet test`).
> 4. `<forensic_evidence>`: General validation commands run.
> 5. `## Gotcha Protocol`: Propose `GEMINI.override.md` edits.
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
> 1. Open a **NEW QA Session**.
> 2. `@[/atdd] Execute the NEXT slice from this plan: {Path_to_implementation_plan.md}`
> 3. Open a **NEW Builder Session** and run `@[/implement]` on those RED tests.
>
> **Scenario B: FINAL slice (or only 1 slice).**
> 1. Open a **NEW QA Session**.
> 2. `@[/verify] {Path_to_walkthrough.md}`
> 3. If verified, manually commit via GitHub Desktop.