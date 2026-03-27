---
description: The Core Builder Implementation Workflow.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# /implement Workflow

## Step 0: Init
- **Workflow Calibration**: If you are just starting this session, you MUST use `view_file` to read the entirety of this `implement.md` file right now to load the strict `@@SCAN` checkpoints into your active context.
- Run Pre-Flight Check from `governance-rules.md`. This makes sure you don't write code that breaks project rules.
- **INTERNAL LOGGING**: You must rigorously process the output of every single `@@SCAN` block defined below in your internal chain of thought. Do NOT use it as a free-form scratchpad.
- If a task list is needed → create `task.md` FIRST. This gives you a stable checklist to track progress.

## Phase 1: Deep Discovery
- Read config files (`.csproj`, `pubspec.yaml`, etc.) to understand the current project state before touching anything.
- **MANDATORY SKILLS**: You MUST ALWAYS load the `tdd` skill before coding. If working in .NET, you MUST also load `testing-strategy`.
- **DYNAMIC SKILLS**: Derive 2-3 keywords from the request → scan `.agents/skills/` → load the top 1-2 matching `SKILL.md` files. Loading the right skill early prevents mistakes later.
- Match the task to rules in `.agents/rules/`. You need to know which rules apply before you plan.

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Which skills & rules did you load? (2) What are the core files and dependencies?

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

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Does the plan pass all checklist items? (2) What was the spot-check result? (3) Does it pass the YAGNI gate?

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
- **MANDATORY STATE TESTING**: You MUST write a failing test for EVERY state defined in the Implementation Plan's State Matrix (Loading, Empty, Error, Success) and EVERY Business Logic Rule before writing the implementation code.
- Follow the TDD inner loop per component: write a failing test → write code to pass it → refactor. This builds quality in, not inspected out later.
- After each component turns GREEN: immediately check it for architecture compliance, null handling, edge cases, and import legality. Fix violations now — not in a post-review phase.
- If the task shifts (e.g., API → DB → UI), re-scan `.agents/skills/` for new matching skills. Drop irrelevant ones to save context.

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Did you test every state in the State Matrix BEFORE coding? (2) Did you follow TDD for each component? (3) Did you run the inline quality gate after each component?

## Phase 4: Self-Review
> Only use rules and skills already loaded in Phase 1. Do NOT scan `.agents/rules/` or `.agents/skills/` broadly here — it wastes context.

Review your own changes from 4 angles. State findings for each:

1. **Security & Architecture**: Does the code break any workspace rules? Any illegal imports or wrong package dependencies?
2. **Logic & Correctness**: Are nulls handled? Edge cases covered? Did you meet every acceptance criterion?
3. **Concurrency**: Idempotency must come from DB Unique Constraints — not app-layer `AnyAsync`/`Exists` checks, which are race-prone. `SaveChangesAsync` belongs only at the top-level Handler, not inside domain services.
4. **Coverage Gate** — for every `[NEW]` or `[MODIFY]` component/handler touched this session:
   - ✅ A **Success State** (Happy Path) test must exist (e.g., 200/201/204 or valid UI).
   - ✅ An **Error State** test must exist (e.g., 404/403/409/400, or UI error boundary).
   - ✅ An **Empty State** test must exist (e.g., empty arrays/nulls handled gracefully).
   - ❌ "Existing suite is still green" does NOT count as coverage for new code.
   - If ANY are missing → write them now before moving to Phase 5. (See Gotcha #12)
   - 🛡️ **Track A Exemption:** If the task was purely cosmetic (e.g., CSS tweaks, padding, copy edits) and contained **zero logical branches or data mutations**, you are explicitly permitted to skip the State Matrix tests. You must state `[SCAN Exemption: Cosmetic Only]` in your review.

- Run `git diff --name-only`. If you edited files not in the plan → fix it. Scope creep breaks other features silently.
- Re-read the `## Verification Plan` in `implementation_plan_[topic].md`. Run each named test. Confirm GREEN. If a test from the plan is missing from the diff → it was skipped. Write it now.

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) All 4 review angles covered? (2) Do structural tests exist for Success, Error, and Empty states for every touched component? (3) `git diff` is clean? (4) Verdict: Ship / Show / Ask?

## Phase 5: Handoff

| Category | When | Action |
|----------|------|--------|
| **Ship** | TDD green, blast radius = 0, trivial scope | Commit. 1-line entry in `walkthrough_[topic].md` + `executed_tests_[topic].md` raw data table. |
| **Show** | TDD green, moderate scope, no blocking risk | Commit + full `walkthrough_[topic].md` + `executed_tests_[topic].md` raw data table. |
| **Ask** | Architectural change, new migration, security-sensitive | Use `notify_user` BEFORE committing. Include numbered test scenarios with Steps / Expected / Blast Radius. |

**Create the `walkthrough_[topic].md`** must include:
- **Decision Log** (only when the plan had multiple proposed features): a table showing each with ✅ Implemented / ⏳ Deferred / ❌ Rejected and a one-line reason. This stops future sessions from re-proposing rejected ideas.
- **Gotcha Removal/Edit Proposal (MANDATORY)**: At the very bottom, add a section evaluating `.agents/rules/project-gotchas.md`. Did your refactor just eliminate the need for an existing workaround? Did you modernize an architecture that makes a Gotcha obsolete? 
  - If yes, explicitly propose which Gotcha (e.g., #4) should be deleted or edited, and provide the exact new Markdown table row. Wait for human approval before editing the rules file.
  - If no, simply state: "No existing gotchas made obsolete."
- **Verification Handoff** per scenario: Steps / Expected / Blast Radius. The QA agent uses this to run `/verify`.

Run `git diff --name-only` one final time to confirm only planned files were changed before handing off.