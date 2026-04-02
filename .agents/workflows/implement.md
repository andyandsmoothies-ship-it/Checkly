---
description: The Core Builder Implementation Workflow
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# /implement Workflow

> [!CAUTION]
> **[PHASE_2.5_YIELD_LOCK]**: PROHIBITED: Executing this entire workflow in a single run. MANDATORY: Yield at **Phase 2.5**. PROHIBITED: Writing production code (Phase 3) until user explicitly confirms Sentinel (QA) has written GREEN/RED tests.

## Phase 0: Init & Calibration
| Step | Execution Contract |
|---|---|
| **Context Load** | `view_file(implement.md)` -> load `@@SCAN` checkpoints into active context. |
| **Governance** | Run Pre-Flight check (`governance-rules.md`). Process `@@SCAN` internally. |
| **Task Tracking**| MANDATORY: Create `task.md` using strict template BEFORE coding. |

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
| [NEW]  | brain/.../walkthrough_[topic].md | Result |
| [NEW]  | brain/.../executed_tests_[topic].md | Test Log |
```

## Phase 1: Deep Discovery
| Step | Execution Contract |
|---|---|
| **Topology** | MANDATORY: Parse config files (`.csproj`, `pubspec.yaml`). |
| **Step 0 Nuke** | IF structure refactor -> MANDATORY: Remove unused imports, dead props, and commented code *before* planning logic. Protects token context. |
| **Skill Load** | MANDATORY: Load `tdd`. IF `dotnet` THEN Load `testing-strategy`. |
| **Dynamic Skills**| Derive 2-3 keywords -> search `.agents/skills/` -> Load Top 2. |

> **@@SCAN**: (1) Skills/rules loaded? (2) Core files/dependencies scanned?

## Phase 2: Planning (THE GATE)
| Step | Execution Contract |
|---|---|
| **Artifact Check**| IF `implementation_plan.md` OR `specs.md` exists -> Execute Quality Checklist. ELSE -> load `technical-specification` + generate lightweight plan -> Yield Approval. |
| **Verification** | Spot-check 1 plan claim against source via `grep_search`. IF plan references an API/DTO: verify claim holds in BOTH `server/` AND `lib/`. IF False → STOP. |
| **YAGNI Gate** | IF feature adds complexity without business value -> Create Before/After tradeoff table. |

### Plan Quality Checklist
- [ ] Goal stated? (1 paragraph)
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
| **Artifact Create**| Export `test_contracts_[topic].md`. MANDATORY: Include Dependency Context Array (List all imports/services for mocking). |
| **Contract Format**| Strict Template: `ID`, `Exact Text/Key` (with line #), `State Matrix` (Happy/Error/Empty), `Private Method Access`, `Why RED now`. |
| **Execution Lock** | PROHIBITED: Entering Phase 3. MANDATORY: Output message: *"Plan ready. Run /tdd with QA Agent (@Sentinel) for failing tests. When done, reply here: 'Here is the result of tdd, check and continue'."* -> YIELD. |

## Phase 3: Coding

> **@@SCAN — Pre-Code (MANDATORY)**  -> State before line 1:
> `[SCAN] Active rules: <list>`
> `[SCAN] Applicable gotchas: <list or NONE>`
> `[SCAN] Active skills: <list>`

| Step | Execution Contract |
|---|---|
| **Test Ingestion** | IF returning from Phase 2.5 -> MANDATORY: Use `view_file` or `grep_search` to read `executed_tests_[topic].md` AND the physical test files created by QA. Understand exact assertions before coding. |
| **Cheap Verify** | Run structural validation (e.g. `flutter analyze`, `dotnet build --no-restore`). Fix before declaring complete. File writes alone != Success. |
| **Strict TDD (Legacy)**| IF altering legacy boundaries -> MANDATORY: Update legacy test FIRST (turn RED) -> THEN write PROD code (turn GREEN). |
| **Red/Green Loop**| IF `Sentinel` gives RED test -> write PROD code to make GREEN -> Refactor. PROHIBITED: Modifying test files unless executing the strict legacy TDD clause above. |
| **Refactor Safety**| IF (renaming/moving code) THEN `grep_search` is NOT an AST. MUST explicitly search 4 ways: 1) Direct calls, 2) Types, 3) String literals, 4) Test Mocks. |
| **Mirror Trap** | PROHIBITED: GREENing a cloned/replica function in a test file. Route test to actual prod logic. |

> **@@SCAN**: (1) Red/Green split respected? (2) Inline verify gate run?

## Phase 4: Self-Review
Review from 4 angles & state findings:
1. **Security/Arch**: Check package dependency/illegal imports.
2. **Logic Check**: Null handling? Acceptance criteria met?
3. **Concurrency**: Verify Idempotency is at DB/Top-layer, not mid-layer.
4. **Coverage Gate**: Every `[NEW]`/`[MOD]` component must have:
   - ✅ Happy Path Test (e.g. 200/201)
   - ✅ Error State Test (e.g. 400/403)
   - ✅ Empty State Test (e.g. Nulls)
   - *Exemption*: Purely cosmetic (`[SCAN Exemption: Cosmetic Only]`)

| Step | Execution Contract |
|---|---|
| **Diff Check** | `git diff --name-only`. Revert unplanned. |
| **Handoff Trap** | IF Context Limit Approaching: Create `handoff_[topic].md` (Completed, Remaining, Modded files) -> Notify User -> YIELD. |

> **@@SCAN**: (1) All 4 angles reviewed? (2) State tests exist? (3) `git diff` clean? (4) Verdict (Ship/Show/Ask)?

## Phase 5: Handoff

| State | Condition | Result Action |
|---|---|---|
| **Ship** | Green TDD, Blast Radius 0, Trivial | Add line to `walkthrough.md` + `executed_tests.md` -> Notify Ready. |
| **Show** | Green TDD, Moderate Scope | Write FULL `walkthrough.md` + `executed_tests.md` -> Notify Ready. |
| **Ask** | Arch change, Security, Migration | Notify user BEFORE action. List numbered scenarios -> Wait go-ahead. |

### Artifact Payload: `walkthrough_[topic].md`
- **Decision Log**: Table showing proposed vs implemented/rejected.
- **Gotcha Protocol**: Evaluate if changes obsolete a `GEMINI.override.md` rule. IF Yes -> Propose table row edit. IF No -> State "No existing gotchas obsolete."
- **Verification Map**: Steps/Expected/Radius for QA Agent.

> [!IMPORTANT]
> **Update task.md**: Convert `[/]` to `[x]` and detail absolute file paths.
> 
> **Script Verification Gate**:
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Implementation complete. Run git commit when ready."*
> - `Code 1`: Fix block -> retry. (Fail twice = Write Handoff).