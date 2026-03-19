---
name: Implementation Workflow
description: The Core Builder Implementation Workflow.
---

# Workflow: /implement

> [!NOTE]
> This is the **Builder** workflow — where code gets written.
> Use for new features, modifications, and bug fixes (after `/diagnose`).

## Pre-Flight
> Run the **Pre-Flight Check** in `orchestration.md` § Pre-Flight Check (CANONICAL) before proceeding.

// Step 0: Setup
1. If artifact needed → Create it FIRST (naming per `orchestration.md` § Artifact Naming Convention)
2. If task needed → Set task_boundary FIRST

<!-- HUD:START — Delete this block to remove the Live Dashboard from all workflows -->
// turbo
3. **Launch Live Dashboard**: Run `cmd /c "start powershell -NoProfile -ExecutionPolicy Bypass -File .agents\tools\agent-hud.ps1"` to open the Agent HUD in a separate window for real-time task tracking.
<!-- HUD:END -->
## Phase 1: Deep Discovery
- **Instruction**: Identify the core files and package dependencies for this feature.
- **Action**: Use the `view_file` tool to read the project configuration files (e.g., `package.json`, `.csproj`, `requirements.txt`, `go.mod`) to understand current project state.
- **Skill Discovery**: Derive 2-3 technical keywords from the user's request (e.g., "login" → "auth", "security"). Use `grep_search` or `list_dir` on `.agents/skills/` to find skills matching those keywords. Load ONLY the top 1-2 most relevant `SKILL.md` files. Declare `- **Skills Checked**: [paths]` in your next response.
- **Rule Inventory**: Match the task to modular workspace rules in `.agents/rules/`.

## Phase 2: Planning (THE GATE)
- **Instruction**: Check if an `implementation_plan.md` already exists in your `brain/` folder (from a prior `/analysis` workflow).
    - **If YES**: Read it and run the **Plan Quality Checklist** below. If ALL pass → request permission to begin coding. If ANY fail → **stop** and tell the user which items are missing. Recommend they re-run `/analysis` or provide the missing details.
    - **If NO**: Load the `technical-specification` skill (`.agents/skills/technical-specification/SKILL.md`) and generate a new `implementation_plan.md` using a lightweight subset of its template. Request approval via `notify_user` before coding.
- **Plan Quality Checklist** (mandatory for both paths):
  - [ ] **Goal**: Has a clear 1-paragraph goal statement?
  - [ ] **File Changes**: Lists specific files with [NEW]/[MODIFY]/[DELETE] tags?
  - [ ] **Data Changes**: Covers DB/Schema/migration changes (or explicitly states N/A)?
  - [ ] **Blast Radius**: Identifies which existing features could break?
  - [ ] **Verification**: Has concrete test commands or manual verification steps?

## Phase 3: Coding (Builder Execution)
- **Instruction**: Put on your "Senior Developer" hat. You MUST implement changes following this exact sequence:
  1. **ATDD Outer Loop Check (Conditional)**: If the QA/SDET provided failing integration/acceptance tests in the plan (from a prior `/atdd` workflow), review them. Your ultimate goal is to turn these GREEN. DO NOT modify the QA's test code. If no ATDD tests exist, proceed to build the feature standardly.
  2. **TDD Inner Loop (MANDATORY)**: Before writing the production classes, search `.agents/skills/` for a TDD or test-first development skill and invoke it. Write granular failing unit tests for the internal components, then write the implementation to make them pass.
  3. **Red-Green-Refactor Execution**: Repeat the TDD cycle until the feature is complete (and ATDD tests pass, if applicable).
  4. **Skill Refresh**: If the coding concern has shifted (e.g., from API design to database work to UI), re-scan `.agents/skills/` for skills matching the current concern. Load 1-2 new skills, drop ones no longer relevant.
  5. **Ghost Audit**: Perform a "Mental Check" for every import/using statement to ensure no restricted libraries are used.

## Phase 4: Self-Review & Drift Check (N-Dimensional)
- **Action**: Stop coding and assume the role of a Senior Reviewer.
- **Context Discipline Rule**: DO NOT indiscriminately scan or read files in `.agents/rules/` or `.agents/skills/` during this phase. This will cause severe context bloat and memory loss. Only evaluate against the *specific* rules and skills you already loaded in Phase 1 or those explicitly listed in the `implementation_plan.md`.
- **N-Dimensional Audit**: You MUST review your own code changes from three distinctly different perspectives. Explicitly state your findings for each:
  1. **Security & Architecture**: Does the code violate the specific workspace rules identified for this task? Are there illegal imports or missed package dependencies?
  2. **Logic & Correctness**: Does the code perfectly handle nulls, edge cases, and unexpected inputs? Did you miss any acceptance criteria?
  3. **Coverage**: Did your TDD Inner Loop tests actually cover the critical paths?
- **Drift Check**: Did you edit files NOT listed in the `implementation_plan.md`? **Action:** Use the `run_command` tool with `git status` or `git diff` to verify the actual files changed. Re-read acceptance criteria. Fix any violations found during self-review before handoff.

## Phase 5: Handoff & Verification
- **Action**: Stop any running development servers (using `send_command_input` with `Terminate: true` if applicable) to release file locks. Then, run the project's standard build and test commands (e.g., `npm run build`, `dotnet build`, `make test`) to verify absolutely no compilation or syntax errors.
- **Walkthrough**: Create or update `walkthrough.md`. It MUST include a **Verification Handoff** section with concrete, numbered test scenarios. Each scenario must have:
  - **Steps**: Exact user actions to reproduce (e.g., "Open template → set mode to Penalty → create audit → add 1 fault")
  - **Expected**: Observable correct behavior (e.g., "Score starts at 100% and decreases")
  - **Blast radius**: Any related features the QA agent should regression-test
  This section is the contract between the Builder and the QA agent running `/verify`. If the QA agent cannot determine what "correct" looks like from the walkthrough alone, the handoff has failed.
- **Skill Refresh (Final)**: Scan `.agents/skills/` for any verification or code-review checklist skill and invoke it for final audit before handoff. Alternatively, recommend the user run `/verify` for comprehensive checks.