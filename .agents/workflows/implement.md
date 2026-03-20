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
- **First Principles Check (Substance over Format)**: Do NOT trust the plan blindly. Independently verify it against the real codebase:
  1. Use `grep_search` / `view_file` to confirm the files listed in the plan actually exist and match the described state.
  2. Spot-check at least ONE blast radius claim — read the referenced file and verify the dependency exists.
  3. If ANY claim contradicts the actual code → **STOP**. Flag the discrepancy to the user. Do not code against a stale plan.

## Phase 3: Coding (Builder Execution — Quality Built In)
- **Instruction**: Put on your "Senior Developer" hat. Quality is built in during coding, not inspected out after.
  1. **ATDD Outer Loop Check (Conditional)**: If the QA/SDET provided failing acceptance tests (from a prior `/atdd` workflow), review them. Your goal is to turn these GREEN. DO NOT modify the QA's test code. If no ATDD tests exist, proceed standardly.
  2. **TDD Inner Loop (MANDATORY)**: Search `.agents/skills/` for a TDD skill and invoke it. Write failing unit tests first, then write the implementation to make them pass.
  3. **Red-Green-Refactor**: Repeat the TDD cycle until the feature is complete.
  4. **Inline Quality Gate (per component)**: After each component reaches GREEN, immediately check it against the rules loaded in Phase 1 — architecture compliance, null handling, edge cases, import legality. Fix violations NOW, not in a post-hoc review phase. This replaces the "inspect after coding" antipattern.
  5. **Skill Refresh**: If the concern shifts (e.g., API → DB → UI), re-scan `.agents/skills/` for matching skills. Load 1-2 new, drop irrelevant ones.

## Phase 4: Self-Review & Drift Check (N-Dimensional)
- **Action**: Stop coding and assume the role of a Senior Reviewer.
- **Context Discipline Rule**: DO NOT indiscriminately scan or read files in `.agents/rules/` or `.agents/skills/` during this phase. This will cause severe context bloat and memory loss. Only evaluate against the *specific* rules and skills you already loaded in Phase 1 or those explicitly listed in the `implementation_plan.md`.
- **N-Dimensional Audit**: You MUST review your own code changes from three distinctly different perspectives. Explicitly state your findings for each:
  1. **Security & Architecture**: Does the code violate the specific workspace rules identified for this task? Are there illegal imports or missed package dependencies?
  2. **Logic & Correctness**: Does the code perfectly handle nulls, edge cases, and unexpected inputs? Did you miss any acceptance criteria?
  3. **Coverage**: Did your TDD Inner Loop tests actually cover the critical paths?
- **Drift Check**: Did you edit files NOT listed in the `implementation_plan.md`? **Action:** Use the `run_command` tool with `git status` or `git diff` to verify the actual files changed. Re-read acceptance criteria. Fix any violations found during self-review before handoff.

## Phase 5: Integrate & Handoff (Ship / Show / Ask)
- **Action**: Stop any running dev servers. Run the project's build and test commands to verify zero compilation errors.
- **Classify** the change using Ship/Show/Ask (inspired by Trunk-Based Development):

  | Category | When | Action |
  |----------|------|--------|
  | **Ship** | TDD green, blast radius = 0, trivial scope | Commit directly. Create a 1-line entry in `walkthrough_[topic].md`. |
  | **Show** | TDD green, moderate scope, no blocking risk | Commit, then create `walkthrough_[topic].md` as a "Show and Tell" for async knowledge sharing — not a gate. |
  | **Ask** | Architectural change, new DB migration, security-sensitive | Use `notify_user` to request review BEFORE committing. Include numbered test scenarios with Steps, Expected, and Blast Radius. |

- **Walkthrough** (for Show and Ask): Create `walkthrough_[topic].md` with a **Verification Handoff** section. Each scenario must have:
  - **Steps**: Exact user actions to reproduce
  - **Expected**: Observable correct behavior
  - **Blast radius**: Related features to regression-test
- **Drift Check**: Run `git status` / `git diff` to verify only planned files were changed. Fix any violations before handoff.