---
name: Implementation Workflow
description: The Core Builder Implementation Workflow.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /implement

## Step 0: Context Initialization (CRITICAL FAIL-SAFE)
> [!IMPORTANT]
> Before you write any code, you MUST verify you fully understand the workspace rules.
> **Rule**: Ensure the above rule files are loaded in your context. Do not proceed to Phase 1 until confirming adherence.

> [!NOTE]
> This is the **Builder** workflow — where code gets written.
> Use for new features, modifications, and bug fixes (after `/diagnose`).

## Pre-Flight
> Run the **Pre-Flight Check** in `@.agents/rules/governance-rules.md` (CANONICAL) before proceeding.

// Step 0: Setup (ANTI-POISONING MANDATE)
> [!IMPORTANT]
> You MUST immediately create a `thinking_log_[topic].md` artifact using `write_to_file` BEFORE writing any other files. All internal reasoning, logic hypotheses, and rejected implementations must go there. Do NOT pollute structured artifacts with internal monologue.
> **Raw Data Requirement**: This log MUST contain a structured Markdown table titled `# Implementation Test Data`. Columns must be: `TDD Goal | Internal Cycle (Red/Green) | Rejected/Approved Assertion | Final Code Path`. This ensures the user has raw analysis data mirroring your internal logic loop.
1. If artifact needed → Create it FIRST (naming per `@.agents/rules/artifact-protocol.md` § Artifact Naming Convention)
2. If task needed → Set task_boundary FIRST


## Phase 1: Deep Discovery
- **Instruction**: Identify the core files and package dependencies for this feature.
- **Action**: Use the `view_file` tool to read the project configuration files (e.g., `package.json`, `.csproj`, `requirements.txt`, `go.mod`) to understand current project state.
- **Skill Discovery**: Derive 2-3 technical keywords from the user's request (e.g., "login" → "auth", "security"). Use `grep_search` or `list_dir` on `.agents/skills/` to find skills matching those keywords. Load ONLY the top 1-2 most relevant `SKILL.md` files. Declare `- **Skills Checked**: [paths]` in your next response.
- **Rule Inventory**: Match the task to modular workspace rules in `.agents/rules/`.

> **@@SCAN** Before proceeding, answer: (1) Which skills and rules did you load? (2) What are the core files and dependencies for this feature?

## Phase 2: Planning (THE GATE)
- **Instruction**: Check if the user provided an `implementation_plan_[topic].md` (from `/analysis`) and a `specs_[topic].md` (from `/atdd`) in the chat context (via a file path, link, or attachment).
    - **Handling Existing Artifacts**: If an `implementation_plan` is provided, read it and run the **Plan Quality Checklist** below. If a `specs` file is provided, you MUST read it to consume the Test Infrastructure Map and the ATDD specifications before coding.
    - **If ALL pass** → request permission to begin coding. If ANY fail → **stop** and tell the user which items are missing. Recommend they re-run `/analysis` or provide the missing details.
    - **If NO**: Load the `technical-specification` skill (`.agents/skills/technical-specification/SKILL.md`) and generate a new `implementation_plan.md` using a lightweight subset of its template. Request approval via `notify_user` before coding.
- **Plan Quality Checklist** (mandatory for both paths):
  - [ ] **Goal**: Has a clear 1-paragraph goal statement?
  - [ ] **File Changes**: Lists specific files with [NEW]/[MODIFY]/[DELETE] tags?
  - [ ] **Data Changes**: Covers DB/Schema/migration changes (or explicitly states N/A)?
  - [ ] **Concurrency**: Explicitly addresses idempotency (DB unique constraints) and transaction boundaries (Unit of Work)?
  - [ ] **Blast Radius**: Identifies which existing features could break?
  - [ ] **Verification**: Has concrete test commands or manual verification steps?
- **First Principles Check (Substance over Format)**: Do NOT trust the plan blindly. Independently verify it against the real codebase:
  1. Use `grep_search` / `view_file` to confirm the files listed in the plan actually exist and match the described state.
  2. Spot-check at least ONE blast radius claim — read the referenced file and verify the dependency exists.
  3. If ANY claim contradicts the actual code → **STOP**. Flag the discrepancy to the user. Do not code against a stale plan.
- **"Worth Doing?" Gate (Mandatory Critical Thinking)**: Even if the plan is technically correct and passes all checks above, you MUST independently evaluate whether it delivers real value. Ask yourself:
  1. **Complexity vs. Benefit**: Does this change add complexity (raw SQL, new abstractions, extra files) that isn't justified by a real, observable problem today? Premature optimization is a code smell, not a feature.
  2. **YAGNI Check**: Is the plan solving a problem the user actually has, or a hypothetical future problem? If the answer is "it would matter at 10,000 rows" but the user has 200, flag it.
  3. **Readability Trade**: Does the "improved" version make the code harder to understand, debug, or maintain? Simpler code that a junior dev can read beats clever code that only the author understands.
  4. **Action**: If ANY of the above raise concerns → **tell the user honestly**. Present a clear comparison table (Before vs. After) with trade-offs. Let them decide. Do NOT silently implement changes you believe are net-negative.

> **@@SCAN** Before coding, answer: (1) Does the plan pass ALL 5 quality checklist items? (2) Did you spot-check at least ONE blast radius claim against real code? (3) Does this change pass the YAGNI / Worth Doing gate?

## Phase 3: Coding (Builder Execution — Quality Built In)
> [!IMPORTANT]
> **@@SCAN — Pre-Code Governance Anchor (MANDATORY)**
> Before writing the first line of code, explicitly state all three:
> 1. **Active Platform Rules**: Architecture pattern (FSD etc.) and the exact target file structure for this feature.
> 2. **Active Gotchas**: Any entries from `project-gotchas.md` that apply to this task. Write `NONE` if none apply.
> 3. **Active Skills**: Which skills from Phase 1 are still in scope for coding. Drop irrelevant ones now.
>
> **Required output before first code change:**
> ```
> [SCAN] Active rules: <list>
> [SCAN] Applicable gotchas: <list or NONE>
> [SCAN] Active skills: <list>
> ```
> ❌ Skipping this block is a workflow violation. Do NOT write any code without it.


- **Instruction**: Put on your "Senior Developer" hat. Quality is built in during coding, not inspected out after.
- **The Micro-Verification Mandate**: During the implementation phase, do not wait until the entire feature is coded to verify stability. You MUST run `dotnet build`, `flutter analyze`, or the relevant test suite after **EVERY single file modification or major logical step**.
  1. **ATDD Outer Loop Check (Conditional)**: If the QA/SDET provided failing acceptance tests (from a prior `/atdd` workflow), review them. Your goal is to turn these GREEN. DO NOT modify the QA's test code. If no ATDD tests exist, proceed standardly.
  2. **TDD Inner Loop (MANDATORY)**: Search `.agents/skills/` for a TDD skill and invoke it. Write failing unit tests first, then write the implementation to make them pass.
  3. **Red-Green-Refactor**: Repeat the TDD cycle until the feature is complete.
  4. **Inline Quality Gate (per component)**: After each component reaches GREEN, immediately check it against the rules loaded in Phase 1 — architecture compliance, null handling, edge cases, import legality. Fix violations NOW, not in a post-hoc review phase. This replaces the "inspect after coding" antipattern.
  5. **Skill Refresh**: If the concern shifts (e.g., API → DB → UI), re-scan `.agents/skills/` for matching skills. Load 1-2 new, drop irrelevant ones.

> **@@SCAN** Before self-review, answer: (1) Did you follow TDD (Red-Green-Refactor) for each component? (2) Were there ATDD tests — if yes, are they now GREEN? (3) Did you run the inline quality gate after each component went GREEN?

## Phase 4: Self-Review & Drift Check (N-Dimensional)
- **Action**: Stop coding and assume the role of a Senior Reviewer.
- **Context Discipline Rule**: DO NOT indiscriminately scan or read files in `.agents/rules/` or `.agents/skills/` during this phase. This will cause severe context bloat and memory loss. Only evaluate against the *specific* rules and skills you already loaded in Phase 1 or those explicitly listed in the `implementation_plan.md`.
- **N-Dimensional Audit**: You MUST review your own code changes from four distinctly different perspectives. Explicitly state your findings for each:
  1. **Security & Architecture**: Does the code violate the specific workspace rules identified for this task? Are there illegal imports or missed package dependencies?
  2. **Logic & Correctness**: Does the code perfectly handle nulls, edge cases, and unexpected inputs? Did you miss any acceptance criteria?
  3. **Concurrency & Transactions (The Hostile Gate)**: Mentally simulate a 500ms network drop and a thundering herd (race condition).
     - ✅ **DB-First Idempotency**: Application-layer checks (`AnyAsync`, `Exists`) are sequential illusions. Idempotency MUST be enforced via DB-level Unique Constraints (`.IsUnique()`).
     - ✅ **Transaction Singularity**: Ban `SaveChangesAsync()` inside domain services or helpers. Services only *stage* entities. The top-level Handler assumes sole authority to flush the transaction.
  4. **Coverage — Test Evidence Gate (MANDATORY)**: For every `[NEW]` handler or endpoint created during this session, you MUST explicitly verify:
     - ✅ A **happy-path** test exists (e.g., `200 OK`, `201 Created`, `204 NoContent`)
     - ✅ A **primary-error-path** test exists (e.g., `404 NotFound`, `403 Forbidden`, `409 Conflict`, `400 BadRequest`)
     - ❌ "The existing suite is still green" does NOT count as coverage of new behavior.
     - **Action**: List each new handler by name. If either test is missing → write it NOW before proceeding to Phase 5. This gate applies even for "Track B1" slices. (See `project-gotchas.md` Gotcha #12)
- **Drift Check (2-part)**:
  1. **File scope**: Run `git status` / `git diff --name-only`. Did you edit files NOT listed in the plan? Fix violations.
  2. **Verification cross-check (MANDATORY)**: Re-read the `## Verification Plan` section of the `implementation_plan_[topic].md` (including any `### ATDD Constraints` injected by the Sentinel). For each **named test** listed there, run it and confirm it is GREEN. If you authored new standard unit tests, confirm they appear in `git diff`. If a test name from the plan is missing from the diff/suite → it was skipped. Write or fix it NOW. The phrase "standard Builder tests will be authored" is NOT a pass.

> **@@SCAN** Before handoff, answer: (1) Did you review from all 4 perspectives (Security, Logic, Concurrency/Transactions, Coverage)? (2) For every [NEW] handler: does a happy-path AND error-path test exist? (3) Did you run `git status` to check for unplanned file changes? (4) What was the verdict — Ship, Show, or Ask?

## Phase 5: Integrate & Handoff (Ship / Show / Ask)
- **Action**: Stop any running dev servers. Run the project's build and test commands to verify zero compilation errors.
- **Classify** the change using Ship/Show/Ask (inspired by Trunk-Based Development):

  | Category | When | Action |
  |----------|------|--------|
  | **Ship** | TDD green, blast radius = 0, trivial scope | Commit directly. Create a 1-line entry in `walkthrough_[topic].md`. You MUST also create a separate `executed_tests_[topic].md` artifact containing ONLY a raw data table (Columns: `Test Method | Target File | Assertion Verified`). |
  | **Show** | TDD green, moderate scope, no blocking risk | Commit, then create `walkthrough_[topic].md` as a "Show and Tell". You MUST also create a separate `executed_tests_[topic].md` artifact containing ONLY a raw data table (Columns: `Test Method | Target File | Assertion Verified`). |
  | **Ask** | Architectural change, new DB migration, security-sensitive | Use `notify_user` to request review BEFORE committing. Include numbered test scenarios with Steps, Expected, and Blast Radius. |

- **Walkthrough** (for Show and Ask): Create `walkthrough_[topic].md` with:
  - **Decision Log** (mandatory when the source plan proposed multiple features): A table showing each proposed feature with its verdict (✅ Implemented, ⏳ Deferred, ❌ Rejected) and a one-line rationale. This captures WHY things were or weren't built, so future sessions don't re-propose rejected ideas.
  - **Verification Handoff**: Each scenario must have:
    - **Steps**: Exact user actions to reproduce
    - **Expected**: Observable correct behavior
    - **Blast radius**: Related features to regression-test
- **Drift Check**: Run `git status` / `git diff` to verify only planned files were changed. Fix any violations before handoff.