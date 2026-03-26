---
name: Implementation Workflow
description: The Core Builder Implementation Workflow.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# /implement Workflow

## Step 0: Init
- Run Pre-Flight Check from `governance-rules.md`. This makes sure you don't write code that breaks project rules.
- Create `thinking_log_[topic].md` FIRST before any other file. This keeps your internal reasoning separate from structured outputs.
- If a task list is needed → create `task.md` FIRST. This gives you a stable checklist to track progress.

## Phase 1: Deep Discovery
- Read config files (`.csproj`, `pubspec.yaml`, etc.) to understand the current project state before touching anything.
- **MANDATORY SKILLS**: You MUST ALWAYS load the `tdd` skill before coding. If working in .NET, you MUST also load `testing-strategy`.
- **DYNAMIC SKILLS**: Derive 2-3 keywords from the request → scan `.agents/skills/` → load the top 1-2 matching `SKILL.md` files. Loading the right skill early prevents mistakes later.
- Match the task to rules in `.agents/rules/`. You need to know which rules apply before you plan.

> **@@SCAN**: (1) Which skills & rules did you load? (2) What are the core files and dependencies?

## Phase 2: Planning (THE GATE)
- Check if an `implementation_plan_[topic].md` (from `/analysis`) or `specs_[topic].md` (from `/atdd`) is in context.
  - **If yes**: read them and run the Plan Quality Checklist below. The specs file gives you the exact tests you must make GREEN — read it before coding.
  - **If no**: load `technical-specification` skill, generate a lightweight `implementation_plan.md`, and get approval before coding.
- **Plan Quality Checklist** — each item must be answered, not just checked:
  - [ ] Clear goal statement (1 paragraph)? Needed so you know what "done" looks like.
  - [ ] Files listed with `[NEW]`/`[MODIFY]`/`[DELETE]`? Needed so you don't edit unplanned files.
  - [ ] DB/Schema/migration addressed (or N/A)? Missed migrations cause silent data bugs.
  - [ ] Idempotency & transaction boundaries stated? Prevents race conditions and double-saves.
  - [ ] Blast radius identified? Tells you what else might break.
  - [ ] Verification steps are concrete (exact commands or test names)? Vague steps can't be verified.
- **Codebase Spot-Check**: Use `grep_search`/`view_file` to confirm at least ONE plan claim against real code. Plans go stale — always verify. If a claim contradicts the code → **STOP** and flag to the user before proceeding.
- **YAGNI Gate**: Ask yourself — is this solving a real problem today, or a future one? If the change adds complexity without a clear, present benefit → show the user a Before/After trade-off table and let them decide. Do not silently implement things you think are net-negative.

> **@@SCAN**: (1) Does the plan pass all checklist items? (2) What was the spot-check result? (3) Does it pass the YAGNI gate?

## Phase 3: Coding
> **@@SCAN — Pre-Code (MANDATORY)** — state all three before writing the first line:
> ```
> [SCAN] Active rules: <list>
> [SCAN] Applicable gotchas: <list or NONE>
> [SCAN] Active skills: <list>
> ```
> Skipping this block is a workflow violation.

- Run `flutter analyze` / `dotnet build` after **every single file change**. Catching errors early is faster than debugging a broken build at the end.
- If ATDD tests exist (from `/atdd`): your goal is to turn them GREEN. Do NOT modify the QA's test code — only fix your implementation.
- Follow the TDD inner loop per component: write a failing test → write code to pass it → refactor. This builds quality in, not inspected out later.
- After each component turns GREEN: immediately check it for architecture compliance, null handling, edge cases, and import legality. Fix violations now — not in a post-review phase.
- If the task shifts (e.g., API → DB → UI), re-scan `.agents/skills/` for new matching skills. Drop irrelevant ones to save context.

> **@@SCAN**: (1) Did you follow TDD for each component? (2) Are ATDD tests GREEN (if they existed)? (3) Did you run the inline quality gate after each component?

## Phase 4: Self-Review
> Only use rules and skills already loaded in Phase 1. Do NOT scan `.agents/rules/` or `.agents/skills/` broadly here — it wastes context.

Review your own changes from 4 angles. State findings for each:

1. **Security & Architecture**: Does the code break any workspace rules? Any illegal imports or wrong package dependencies?
2. **Logic & Correctness**: Are nulls handled? Edge cases covered? Did you meet every acceptance criterion?
3. **Concurrency**: Idempotency must come from DB Unique Constraints — not app-layer `AnyAsync`/`Exists` checks, which are race-prone. `SaveChangesAsync` belongs only at the top-level Handler, not inside domain services.
4. **Coverage Gate** — for every `[NEW]` handler created this session:
   - ✅ A happy-path test must exist (200/201/204)
   - ✅ A primary error-path test must exist (404/403/409/400)
   - ❌ "Existing suite is still green" does NOT count as coverage for new code
   - If either is missing → write it now before moving to Phase 5. (See Gotcha #12)

- Run `git diff --name-only`. If you edited files not in the plan → fix it. Scope creep breaks other features silently.
- Re-read the `## Verification Plan` in `implementation_plan_[topic].md`. Run each named test. Confirm GREEN. If a test from the plan is missing from the diff → it was skipped. Write it now.

> **@@SCAN**: (1) All 4 review angles covered? (2) Happy + error-path tests exist for every [NEW] handler? (3) `git diff` is clean? (4) Verdict: Ship / Show / Ask?

## Phase 5: Handoff

| Category | When | Action |
|----------|------|--------|
| **Ship** | TDD green, blast radius = 0, trivial scope | Commit. 1-line entry in `walkthrough_[topic].md` + `executed_tests_[topic].md` raw data table. |
| **Show** | TDD green, moderate scope, no blocking risk | Commit + full `walkthrough_[topic].md` + `executed_tests_[topic].md` raw data table. |
| **Ask** | Architectural change, new migration, security-sensitive | Use `notify_user` BEFORE committing. Include numbered test scenarios with Steps / Expected / Blast Radius. |

**`walkthrough_[topic].md`** must include:
- **Decision Log** (only when the plan had multiple proposed features): a table showing each with ✅ Implemented / ⏳ Deferred / ❌ Rejected and a one-line reason. This stops future sessions from re-proposing rejected ideas.
- **Verification Handoff** per scenario: Steps / Expected / Blast Radius. The QA agent uses this to run `/verify`.

Run `git diff --name-only` one final time to confirm only planned files were changed before handing off.