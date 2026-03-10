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
- **Skill Discovery**: You must proactively identify the correct skills without the user explicitly telling you. First, derive 2-3 technical keywords from the user's request (e.g., "login" -> "auth", "security"). Then, use `grep_search` or `list_dir` on the `.agents/skills/` directory to find skills matching those keywords. Load ONLY the top 1-2 most relevant `SKILL.md` files to avoid context bloat. You must declare `- **Skills Checked**: [paths]` in your next response.
- **Rule Inventory**: Match the task to modular workspace rules in `.agents/rules/`.

## Phase 2: Planning (THE GATE)
- **Instruction**: Check if an `implementation_plan.md` already exists in your `brain/` folder (from an Architect or QA workflow).
    - **If YES**: Read it, audit it against `.agents/rules/`, and request permission to begin coding.
    - **If NO**: Generate a new `implementation_plan.md` outlining the required files, logic, and dependencies. Request approval via `notify_user` before coding.
- **Plan Audit**: Ensure the plan completely adheres to all workspace rules in `.agents/rules/`.

## Phase 3: Coding (Builder Execution)
- **Instruction**: Put on your "Senior Developer" hat. You MUST implement changes following this exact sequence:
  1. **ATDD Outer Loop Check (Conditional)**: If the QA/SDET provided failing integration/acceptance tests in the plan (from a prior `/atdd` workflow), review them. Your ultimate goal is to turn these GREEN. DO NOT modify the QA's test code. If no ATDD tests exist, proceed to build the feature standardly.
  2. **TDD Inner Loop Invocation (MANDATORY)**: Before writing the production classes to solve the feature requirements or ATDD tests, invoke the `tdd` skill (`.agents/skills/tdd/SKILL.md`).
  3. **Red-Green-Refactor Execution**: Using the `tdd` skill, write granular failing unit tests for the internal components you need to build, write the implementation, and refactor. Repeat this until the feature is complete (and ATDD tests pass, if applicable).
  4. **Skill Execution**: While coding, strictly apply the architectural and language patterns from the skills you discovered in Phase 1.
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
- **Instruction**: Dynamically invoke a verification checklist skill from `.agents/skills/` (or recommend the user run `/verify` for ad-hoc checks) for final audit before handoff.