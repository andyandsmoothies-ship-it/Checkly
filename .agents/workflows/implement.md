---
description: The Core Builder Implementation Workflow
---

@[.agents/rules/orchestration-standards.md]

# /implement Workflow

> [!CAUTION]
> **[PHASE_2.5_YIELD_LOCK]**: PROHIBITED: Executing this entire workflow in a single run. MANDATORY: Yield at **Phase 2.5**. PROHIBITED: Writing production code (Phase 3) until user explicitly confirms Sentinel (QA) has written GREEN/RED tests.

## Phase 0: Init & Calibration
| Step | Execution Contract |
|---|---|
| **Context Load** | `view_file(implement.md)` -> load `@@SCAN` checkpoints into active context. |
| **Governance** | Run Pre-Flight check (`governance-rules.md`). Process `@@SCAN` internally. |
| **Task Tracking**| MANDATORY: Create `task_[ConversationID].md` using strict template BEFORE coding. |

```markdown
# Task: [Name]
Workflow: /implement | Track: [A / B1 / B2 / C]

## Phases
- [ ] Phase 1: Deep Discovery
- [ ] Phase 2: Planning
- [ ] Phase 2.5: QA TDD Handoff Gate
- [ ] Phase 3: Coding
- [ ] Phase 4: Self-Review
- [ ] Phase 5: Handoff

## Artifact Inventory
| Status | File Path | Type |
|--------|-----------|------|
| [NEW]  | brain/.../walkthrough_[topic]_[ConversationID].md | Result |
| [NEW]  | brain/.../executed_tests_[topic]_[ConversationID].md | Test Log |
```

## Phase 1: Deep Discovery
| Step | Execution Contract |
|---|---|
| **Topology** | MANDATORY: Parse config files (`.csproj`, `pubspec.yaml`). |
| **Step 0 Nuke** | IF structure refactor -> MANDATORY: Remove unused imports, dead props, and commented code *before* planning logic. Protects token context. |
| **Skill Load** | MANDATORY: Load `tdd`. IF `dotnet` THEN Load `testing-strategy`. |
| **Dynamic Skills**| IF plan lacks `[ACTIVE_SKILLS]` -> Derive 2-3 keywords from prompt -> search `.agents/skills/` -> Load Top 2. |

> **@@SCAN**: (1) Skills/rules loaded? (2) Core files/dependencies scanned?

## Phase 2: Planning (THE GATE)
| Step | Execution Contract |
|---|---|
| **Artifact Check**| IF `implementation_plan.md` OR `specs.md` exists -> Execute Quality Checklist. ELSE -> load `technical-specification` + generate lightweight plan -> Yield Approval. |
| **Verification Pledge** | MANDATORY: Before writing any code, explicitly declare the terminal validation commands (e.g. `flutter test`, `dotnet test`) you will run to prove "what good looks like." |
| **JIT Harness** | MANDATORY: Declare `[ACTIVE_SKILLS]` at the top of the plan. Drop all other RAG context. The AI is legally bound to this isolation cage for the session. |
| **ATDD Ingestion**| IF ATDD artifacts were provided in the prompt -> MANDATORY: Use `view_file` to read the `.md` test contracts AND the physical test files created by QA. Real-world engineering requires understanding the Outer Loop (ATDD) before defining the Inner Loop (TDD). |
| **Trust But Verify** | Assume the plan is well-intentioned but might hallucinate. Spot-check 1 core plan claim against actual source via `grep_search` before coding. IF plan assumes an API/DTO exists: prove it holds in BOTH `server/` AND `lib/`. IF False → STOP and pivot. |
| **YAGNI Gate** | IF feature adds complexity without business value -> Create Before/After tradeoff table. |

### Plan Quality Checklist
- [ ] Goal stated? (1 paragraph)
- [ ] JIT Harness (`[ACTIVE_SKILLS]`) declared?
- [ ] File delta (`[NEW]`, `[MOD]`, `[DEL]`) defined?
- [ ] Identity DB/Schema migrations?
- [ ] Transaction boundaries & idempotency defined?
- [ ] Blast radius identified?
- [ ] Verification steps concrete?

> **@@SCAN**: (1) Passes Plan Quality Checklist? (2) Spot-check Result? (3) Passes YAGNI?

## Phase 2.5: QA TDD Handoff (MANDATORY YIELD)
> [!CAUTION]
> **Anti-Bias Protocol:** Builder CANNOT write own tests.
| Step | Execution Contract |
|---|---|
| **Artifact Create**| Export `test_contracts_[topic]_[ConversationID].md`. MANDATORY: Include Dependency Context Array (List all imports/services for mocking). |
| **Contract Format**| Strict Template: `ID`, `Exact Text/Key` (with line #), `State Matrix` (Happy/Error/Empty), `Private Method Access`, `Why RED now`. |
| **Execution Lock** | PROHIBITED: Entering Phase 3 without explicit TDD execution. The *Marking Your Own Homework Paradox* applies universally. MANDATORY YIELD: You MUST yield to the QA persona (@Sentinel) to write tests. Output the exact block below -> YIELD. |

## 🚦 Phase 2.5 Handoff (Yield)

> [!IMPORTANT]
> **Outputs Created:** Internal component plan.
>
> **YOUR NEXT COMMAND:** 
> - Switch to Sentinel QA and type: `@[/tdd] The Builder proposes these classes... (describe or paste plan)`
> - Once `/tdd` is complete, return here and type: `Here is the result of tdd. Go.`

## Phase 3: Coding

> **@@SCAN — Pre-Code (MANDATORY)**  -> State before line 1:
> `[SCAN] Active rules: <list>`
> `[SCAN] Applicable gotchas: <list or NONE>`
> `[SCAN] Active skills: <list>`

| Step | Execution Contract |
|---|---|
| **Test Ingestion** | IF returning from Phase 2.5 -> MANDATORY: Use `view_file` or `grep_search` to read the internal unit test files (TDD) created by QA during Phase 2.5. Understand exact internal assertions before coding. |
| **Cheap Verify** | Run structural validation (e.g. `flutter analyze`, `dotnet build --no-restore`). Fix before declaring complete. File writes alone != Success. |
| **Strict TDD (Legacy)**| IF altering legacy boundaries -> MANDATORY: Update legacy test FIRST (turn RED) -> THEN write PROD code (turn GREEN). |
| **Immutable Mock ATDD Guard**| MANDATORY: You are completely prohibited from changing existing ATDD Tests or AuthMocks to make your mutated code pass (The Anti-Bias Protocol). If your code breaks a test, your code is wrong. You must adapt your logic to the existing contract boundary. |
| **Red/Green Loop**| IF `Sentinel` gives RED test -> write PROD code to make GREEN -> Refactor. PROHIBITED: Modifying test files unless executing the strict legacy TDD clause above. |
| **Refactor Safety**| IF (renaming/moving code) THEN `grep_search` is NOT an AST. MUST explicitly search 4 ways: 1) Direct calls, 2) Types, 3) String literals, 4) Test Mocks. |
| **Mirror Trap** | PROHIBITED: GREENing a cloned/replica function in a test file. Route test to actual prod logic. |
| **State Invariants**| MANDATORY: You MUST explicitly write test assertions to verify the Entry Preconditions and Exit Postconditions of the slice. |
| **Blast Radius** | IF modifying shared foundational code (e.g., `Common/`, `shared/`, `core/`) -> MANDATORY: Execute regression tests for ALL upstream callers. If tests do not exist, write them before modifying the code. |

> **@@SCAN**: (1) Red/Green split respected? (2) Inline verify gate run?

## Phase 4: Self-Review
Review from 6 angles & state findings:
0. **Double-Check Hack**: Re-read your loaded `[ACTIVE_SKILLS]` instructions. Explicitly verify your code did not violate any core parameters of the loaded skill. (Proven mental-model hack for catching LLM drift).
1. **Security/Arch**: Check package dependency/illegal imports.
2. **Logic Check**: Null handling? Acceptance criteria met?
3. **Concurrency**: Verify Idempotency is at DB/Top-layer, not mid-layer.
4. **Coverage Gate**: Every `[NEW]`/`[MOD]` component must have:
   - ✅ Happy Path Test (e.g. 200/201)
   - ✅ Error State Test (e.g. 400/403)
   - ✅ Empty State Test (e.g. Nulls)
   - ✅ State Invariant Test (Entry/Exit Conditions)
   - ✅ Blast Radius Test (If modifying shared code)
   - *Exemption*: Purely cosmetic (`[SCAN Exemption: Cosmetic Only]`)
5. **Quality Gate (Zero-Warning Mandate)**: You MUST run structural validation (e.g., `flutter analyze` or `dotnet build`). If the compiler/linter emits ANY warnings (e.g., unused imports, dead code, logic smells), you are strictly PROHIBITED from handing the task back to the user. You must fix the warnings first. No exceptions.
6. **Supportability Sweep (Crickett's Rule)**: Is this code idiomatic for the tech stack? Would a new developer understand the What, Why, and Tradeoffs? The tradeoffs MUST be explicitly documented in the walkthrough.

| Step | Execution Contract |
|---|---|
| **Test Analytics**| Output tests to files to bypass terminal limits. `.NET`: `powershell -File scripts\CollectTestResults.ps1` \| `Flutter`: `flutter test --machine > results.json` \| `Node`: `npm test -- --json > results.json`. `view_file` the result. |
| **Diff Check** | `git diff --name-only`. Revert unplanned. |
| **Handoff Trap** | IF Context Limit Approaching: Create `handoff_[topic]_[ConversationID].md` (Completed, Remaining, Modded files) -> Notify User -> YIELD. |

> **@@SCAN**: (1) All 4 angles reviewed? (2) State tests exist? (3) `git diff` clean? (4) Verdict (Ship/Show/Ask)?

## Phase 5: Handoff

| State | Condition | Result Action |
|---|---|---|
| **Ship** | Green TDD, Blast Radius 0, Trivial | Add line to `walkthrough.md` + `executed_tests.md` -> Notify Ready. |
| **Show** | Green TDD, Moderate Scope | Write FULL `walkthrough.md` + `executed_tests.md` -> Notify Ready. |
| **Ask** | Arch change, Security, Migration | Notify user BEFORE action. List numbered scenarios -> Wait go-ahead. |
| **Verify Gate** | ALL STATES | MANDATORY: Execute `verify_workflow.py` via `run_command` immediately after writing the walkthrough to prove artifact completeness. |

### Final Generation Mandate (Suffix)
> [!IMPORTANT]
> **Walkthrough Schema:** Your `walkthrough_[topic]_[ConversationID].md` MUST INCLUDE: 
> 1. `## Decision Log`: Table showing proposed vs implemented/rejected.
> 2. `## Verification Handoff`: Steps/Expected/Radius for QA Agent. (MANDATORY: Recommend running `@red_team_playbook.md` if feature is Track C, or backend Track B).
> 3. `<test_trace>`: MANDATORY for external feedback. You MUST provide the raw terminal execution output of your tests (e.g., `dotnet test` or `flutter analyze`) inside these XML tags. Self-certification of code fixes without terminal proof is prohibited.
> 4. `<forensic_evidence>`: Proof of general validation/exploration commands run.
> 4. `## Gotcha Protocol`: Propose `GEMINI.override.md` edit if obsolete rules exist.
>
> **Update task_[ConversationID].md**: Convert `[/]` to `[x]` and detail absolute file paths.
> 
> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Implementation complete. Output User Handoff."*
> - `Code 1`: Re-read artifacts, fix the missing sections, update `task.md`, and retry. (Fail twice = Write Handoff).

## 🚦 User Handoff & Next Steps

> [!IMPORTANT]
> **Outputs Created:** Implemented code (GREEN) + `walkthrough_[topic]_[ConversationID].md`.
>
> **YOUR NEXT COMMAND:** (Do not merge code yet)
> - Switch to Sentinel QA and type: `@[/verify] this walkthrough_[topic]_[ConversationID].md`