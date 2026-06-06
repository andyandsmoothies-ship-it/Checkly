---

description: Universal verification gate proving upstream artifacts (code, plans, audits) are structurally sound, performant, and correctly implemented.

---

# Workflow: /verify

> [!CAUTION]

> **[READ_ONLY_LOCK]**: The Sentinel persona is strictly READ-ONLY. PROHIBITED: "In-Flight Corrections" or executing `replace_file_content`. IF regression found THEN STOP -> trigger `/diagnose` -> handoff to Forge.

## Step 1: Context & Accountability Audit

- **Task Tracking**: MANDATORY: Create `docs/features/[topic]/task_[topic]_[YYYYMMDD_HHMMSS].md` using the strict schema BEFORE proceeding. You MUST include an `## Input Lineage` section tracking the absolute path to the input artifact.

- **Skill Load**: Extract 2-3 keywords -> `grep_search` `.agents/skills/` -> Load Verification/Testing skills.

- **Side Effects**: MANDATORY: Assess code changes for framework state loss, missing locks, or illegal ghost imports based on `.agents/rules/`.

- **Verification**: MANDATORY: Semi-Formal Reasoning. Trace code path line-by-line. PROHIBITED: Assuming behavior based on function names.

- **Criteria Check**: `grep_search` upstream `implementation_plan.md` → verify every AC is realized in code. If AC involves API/DTO: verify realization exists in BOTH `server/` and `lib/`. Flag omissions.

- **Boundary Sync Check**: MANDATORY: Does this feature combine data across architectural boundaries (e.g., Remote API + Local Store)? If yes, explicitly verify and document the merging logic. Unverified trust across boundaries fails the pipeline.

- **EDD Proof**: MANDATORY: Demand **Executed Evidence** (logs, API responses). PROHIBITED: Accepting "Generative Evidence" (Builder claiming it works).

- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Code path traced line-by-line? (2) All ACs verified against real code on both stacks?

## Step 2: Adversarial Interrogation (Red Team)

- **Red Team Threshold**: MANDATORY: Only execute `red_team_playbook.md` stress tests if: (1) Track C Epic, OR (2) Track B touching API boundaries, Database schemas, Auth guards, or File handling. Skip for UI/UX (Track A).

- **Hostile Gate**: MANDATORY: Execute **Virtual Reader Scoring**. Roast the code via 3 Personas: 1) DB Architect (N+1, ops), 2) Security Auditor (IDOR, payloads), 3) Junior Dev (Coupling, unreadable logic). Score each out of 10. IF any score < 7 -> trigger `/diagnose`.

- **Drift OOM Scan**: IF (Flutter/Drift `*_queries.dart` / `*_manager.dart`) THEN SCAN for `.get()`. MUST possess limit OR aggregate OR explicit safety comment. IF missing -> FAIL (OOM violation).

- **Stability Scan**: IF (Flutter UI) THEN SCAN for infinite width widgets (e.g., `ElevatedButton`) inside horizontal layouts (`Row`). MUST possess bounds (`Expanded`, `minimumSize`). IF (Flutter Logic) THEN SCAN for proper `GetIt` DI registration before consumption (no mocking unregistered services).

- **Efficiency Eval**: MANDATORY: Evaluate N+1 queries, memory leaks, Big-O complexity. PROHIBITED: Declaring SUCCESS simply because tests pass if UX degrades.

- **Zero Trust Gate**: MANDATORY: Ensure no secrets/keys are hardcoded, explicit `[Authorize]` tags are applied, CORS is strict, and no unapproved "Shadow IT" packages were added.

- **Supportability (Crickett's Rule)**: MANDATORY: Reject code that is non-idiomatic. Demand explicit documentation answering: What does this do? Why is this done this way? What are the tradeoffs?

- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Hostile Interrogation run? (2) Drift/OOM/Stability Scans executed (if applicable)? (3) Supportability tradeoffs documented?

## Step 3: Continuous Integration (CI) Gate

- **Quality Sweep**: MANDATORY "Mini-Sweep":

  1. Run native auto-formatter (e.g., `dart format .`, `dotnet format`, `prettier`) on modified code.

  2. Run `grep_search` on touched files to block sloppy code (leftover `print()`, `console.log`, `TODO:`, hardcoded styling/colors, AND **dead UI stubs like `onPressed: () {}` or `href='#'`**).

  3. Automatically organize documentation by running the organizer script:
     // turbo

  4. Run the PBAC UI checker to scan for unprotected widgets (advisory mode):
     // turbo
     `cmd /c python .agents/scripts/verify_pbac_ui.py --advisory`

  5. Run the contract sync checker to detect API/DB drifts:
     // turbo
     `cmd /c python .agents/scripts/verify_sync_contracts.py`

- **Test Quality**: Map walkthrough files to related test files (via suffix mapping or grepping symbol references in tests). Evaluate tests to ensure: (1) no empty/ghost assertions, (2) no mocking of core business/domain logic, (3) assertions test observable behavior rather than private state, (4) failed states report explicit error messages rather than raw silent booleans, and (5) all modified UI pages/widgets/contracts include and pass automated Golden/Snapshot tests.

- **Execution**: Stop Dev Servers -> Run tests. Run only related feature tests (e.g., `test/features/your_feature/`) for UI, widgets, and feature-specific logic. Run global tests ONLY when changing shared database schemas, global network clients, or public API signatures.

- **Pass/Fail Logic**: IF (Tests Green, Golden Visuals/Snapshots Match, AND Zero Warnings) -> Proceed Step 4. IF (Any Fail/Warning) -> **MANDATORY TRANSITION**: `/diagnose`. Do NOT ask permission.

- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Build passed with zero warnings? (2) Test quality checks executed and logged? (3) IF failed -> transitioned to `/diagnose`?

## Step 4: Deliverable (The Metrics Snapshot)

- **Coverage & Metrics Gen**: MANDATORY: Execute available tooling to calculate Test Coverage, Cyclomatic Complexity, File Sizing, and Mutation scores (e.g., `dotnet test /p:CollectCoverage=true`). The human relies on these metrics to govern the factory; do not skip them.

- **Artifact Form**: MANDATORY: Use `write_to_file` to save `verification_[YYYYMMDD_HHMMSS].md` into the `docs/reports/qa/` directory. MUST INCLUDE: (1) `## Input Lineage` containing the absolute path to the verified artifact, (2) The Quantitative Metrics Dashboard (Coverage %, Complexity, Warnings count), and (3) Terminal log proof of the green test suite.

- **Yield & Handoff**: Yield to the user with the exact Next Command explicitly referencing `{Absolute_Path_to_verification_artifact.md}`.

> [!IMPORTANT]

<output_schema>

> **Script Verification Gate (MANDATORY)**:

> You MUST use the `run_command` tool to execute this script before considering the task complete.

> // turbo

> `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`

> - `Code 0`: *"Workflow complete. Share summary."*

> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>

</output_schema>
