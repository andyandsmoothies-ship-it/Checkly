---
description: The Core Builder Implementation Workflow.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# /implement Workflow

## Step 0: Init
- **Workflow Calibration**: If you are just starting this session, you MUST use `view_file` to read the entirety of this `implement.md` file right now to load the strict `@@SCAN` checkpoints into your active context.
- Run Pre-Flight Check from `governance-rules.md`.
- **INTERNAL LOGGING**: Process `@@SCAN` block output internally. Do not use as scratchpad.
- **MANDATORY ARTIFACT**: You MUST create a `task.md` artifact FIRST before writing any code using this exact schema:
  ```
  # Task: [Feature / Bug / Topic Name]
  Workflow: /implement | Track: [A / B1 / B2 / C]
  ## Phases
  - [ ] Phase 1: Deep Discovery
  - [ ] Phase 2: Planning
  - [ ] Phase 3: Coding
  - [ ] Phase 4: Self-Review
  - [ ] Phase 5: Handoff
  ## Artifact Inventory
  | Status | File Path | Type |
  |--------|-----------|------|
  ```

## Phase 1: Deep Discovery
- Read config files (`.csproj`, `pubspec.yaml`, etc.) to understand the current project state before touching anything.
- **MANDATORY SKILLS**: You MUST ALWAYS load the `tdd` skill before coding. If working in .NET, you MUST also load `testing-strategy`.
- **DYNAMIC SKILLS**: Derive 2-3 keywords from the request → scan `.agents/skills/` → load the top 1-2 matching `SKILL.md` files.
- Match task to rules in `.agents/rules/`.

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Which skills & rules did you load? (2) What are the core files and dependencies?

## Phase 2: Planning (THE GATE)
- Check if an `implementation_plan_[topic].md` (from `/analysis`) or `specs_[topic].md` (from `/atdd`) is in context.
  - **If yes**: read them and run the Plan Quality Checklist below. The specs file gives you the exact tests you must make GREEN — read it before coding.
  - **If no**: load `technical-specification` skill, generate a lightweight `implementation_plan.md`, and get approval before coding.
- **Plan Quality Checklist** — answer each item:
  - [ ] Clear goal statement (1 paragraph)?
  - [ ] Files listed with `[NEW]`/`[MODIFY]`/`[DELETE]`?
  - [ ] DB/Schema/migration addressed (or N/A)?
  - [ ] Idempotency & transaction boundaries stated?
  - [ ] Blast radius identified?
  - [ ] Verification steps are concrete (exact commands or test names)?
- **Codebase Spot-Check**: Use `grep_search`/`view_file` to confirm ONE plan claim against real code. If contradicted → **STOP** and flag to user.
- **YAGNI Gate**: Is this solving a real problem today? If it adds complexity without clear benefit → show Before/After trade-off table.

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Does the plan pass all checklist items? (2) What was the spot-check result? (3) Does it pass the YAGNI gate?

## Phase 2.5: The QA TDD Handoff Gate (MANDATORY YIELD)
> [!CAUTION]
> **Anti-Bias Protocol:** The Builder Agent (@Forge) is strictly forbidden from writing both the tests and the implementation. To prevent test-hacking, the unit test boundaries must be set by QA.
- **Action:** BEFORE entering Phase 3, you MUST stop generation and yield to the user.
- **Message:** "Plan is ready. Please take this plan to the QA Agent (@Sentinel) and ask them to write the failing TDD / Unit Tests based on these contracts. Return here and type 'Tests are red' when complete."
- **DO NOT WRITE ANY PRODUCTION CODE UNTIL THE USER CONFIRMS THE TESTS ARE WRITTEN.**

## Phase 3: Coding
> **@@SCAN — Pre-Code (MANDATORY)** — state all three before writing the first line:
> ```
> [SCAN] Active rules: <list>
> [SCAN] Applicable gotchas: <list or NONE>
> [SCAN] Active skills: <list>
> ```
> Skipping this block is a workflow violation.

- **The Cheap Verifier Gate**: Before declaring code complete, run a fast semantic check. Dart: `cmd /c flutter analyze lib/path/to/feature`. C#: `cmd /c dotnet build server/Checkly.Api.csproj --no-restore`. Fix locally.
- **The Red/Green Context Split (MANDATORY)**: @Sentinel provided failing tests. Turn them GREEN. **DO NOT MODIFY test files.**
- Follow TDD inner loop: Run QA test → write code to pass it → refactor.
- Post-Green Check: Check architecture compliance, null handling, edge cases, import legality. Fix immediately.
- If task shifts domains, re-scan `.agents/skills/` and drop irrelevant ones.

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Did you follow Red/Green split natively? (2) Did you run inline quality gate per component?

## Phase 4: Self-Review
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

- Run `git diff --name-only`. Revert unplanned edits.
- Run each test from the `## Verification Plan`. Confirm GREEN.

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) All 4 review angles covered? (2) Do structural tests exist for Success, Error, and Empty states for every touched component? (3) `git diff` is clean? (4) Verdict: Ship / Show / Ask?

> [!CAUTION]
> **Clean Handoff Protocol**: If you are nearing your context limit or hit a blocking error before this phase is complete, do NOT silently stop. Write a `handoff_[topic].md` listing completed phases, remaining phases, and all files modified so far. Then tell the user: *"Context limit reached. Resume from `handoff_[topic].md` in a new session."*

## Phase 5: Handoff

| Category | When | Action |
|----------|------|--------|
| **Ship** | TDD green, blast radius = 0, trivial scope | Commit. 1-line entry in `walkthrough_[topic].md` + `executed_tests_[topic].md` raw data table. |
| **Show** | TDD green, moderate scope, no blocking risk | Commit + full `walkthrough_[topic].md` + `executed_tests_[topic].md` raw data table. |
| **Ask** | Architectural change, new migration, security-sensitive | Use `notify_user` BEFORE committing. Include numbered test scenarios with Steps / Expected / Blast Radius. |

**Create the `walkthrough_[topic].md`** must include:
- **Decision Log** (only when the plan had multiple proposed features): a table showing each with ✅ Implemented / ⏳ Deferred / ❌ Rejected and a one-line reason. This stops future sessions from re-proposing rejected ideas.
- **Gotcha Removal/Edit Proposal (MANDATORY)**: At the very bottom, add a section evaluating the `GEMINI.override.md` files located inside the feature folders you just modified. Did your refactor just eliminate the need for an existing workaround? Did you modernize an architecture that makes a Gotcha obsolete? 
  - If yes, explicitly propose which Gotcha (e.g., #4) should be deleted or edited, and provide the exact new Markdown table row. Wait for human approval before editing the rules file.
  - If no, simply state: "No existing gotchas made obsolete."
- **Verification Handoff** per scenario: Steps / Expected / Blast Radius. The QA agent uses this to run `/verify`.

Run `cmd /c git diff --name-only` one final time to confirm only planned files were changed.

> **🛡️ ARTIFACT PRE-FLIGHT (MANDATORY — do this BEFORE git commit):**
> Run `list_dir` on `C:\Users\HP\.gemini\antigravity\brain\{conversation-id}\` and visually confirm that **every** artifact listed in the task.md Phase 5 checkboxes exists as a real file on disk.
> - ✅ `walkthrough_[topic].md` — visible in listing
> - ✅ `executed_tests_[topic].md` — visible in listing
> - ✅ `task.md` — visible in listing
>
> **If any file is missing → create it before committing.** A `[x]` checkbox in task.md does NOT prove the file was created. See Gotcha #20.