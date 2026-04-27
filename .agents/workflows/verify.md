---
description: Universal verification gate proving upstream artifacts (code, plans, audits) are structurally sound, performant, and correctly implemented.
---

@[.agents/rules/orchestration-standards.md]
# Workflow: /verify

> [!CAUTION]
> **[READ_ONLY_LOCK]**: The Sentinel persona is strictly READ-ONLY. PROHIBITED: "In-Flight Corrections" or executing `replace_file_content`. IF regression found THEN STOP -> trigger `/diagnose` -> handoff to Forge.

## Phase 1: Context & Accountability Audit

| Audit Vector | Execution Contract |
|---|---|
| **Task Tracking** | MANDATORY: Create `task_[YYYYMMDD]_[ConversationID]_[topic].md` using the strict schema BEFORE proceeding. |
| **Skill Load** | Extract 2-3 keywords -> `grep_search` `.agents/skills/` -> Load Verification/Testing skills. |
| **Side Effects** | MANDATORY: Assess code changes for framework state loss, missing locks, or illegal ghost imports based on `.agents/rules/`. |
| **Verification**| MANDATORY: Semi-Formal Reasoning. Trace code path line-by-line. PROHIBITED: Assuming behavior based on function names. |
| **Criteria Check**| `grep_search` upstream `implementation_plan.md` → verify every AC is realized in code. If AC involves API/DTO: verify realization exists in BOTH `server/` and `lib/`. Flag omissions. |
| **Boundary Sync Check**| MANDATORY: Does this feature combine data across architectural boundaries (e.g., Remote API + Local Store)? If yes, explicitly verify and document the merging logic. Unverified trust across boundaries fails the pipeline. |
| **EDD Proof** | MANDATORY: Demand **Executed Evidence** (logs, API responses). PROHIBITED: Accepting "Generative Evidence" (Builder claiming it works). |

> **@@SCAN**: (1) Code path traced line-by-line? (2) All ACs verified against real code on both stacks?

## Phase 1.5: Adversarial Interrogation (Red Team)

| Interrogation Vector | Execution Contract |
|---|---|
| **Red Team Threshold** | MANDATORY: Only execute `red_team_playbook.md` stress tests if: (1) Track C Epic, OR (2) Track B touching API boundaries, Database schemas, Auth guards, or File handling. Skip for UI/UX (Track A). |
| **Hostile Gate** | MANDATORY: Execute **Virtual Reader Scoring**. Roast the code via 3 Personas: 1) DB Architect (N+1, ops), 2) Security Auditor (IDOR, payloads), 3) Junior Dev (Coupling, unreadable logic). Score each out of 10. IF any score < 7 -> trigger `/diagnose`. |
| **Drift OOM Scan**| IF (Flutter/Drift `*_queries.dart` / `*_manager.dart`) THEN SCAN for `.get()`. MUST possess limit OR aggregate OR explicit safety comment. IF missing -> FAIL (OOM violation). |
| **Efficiency Eval** | MANDATORY: Evaluate N+1 queries, memory leaks, Big-O complexity. PROHIBITED: Declaring SUCCESS simply because tests pass if UX degrades. |
| **Supportability (Crickett's Rule)** | MANDATORY: Reject code that is non-idiomatic. Demand explicit documentation answering: What does this do? Why is this done this way? What are the tradeoffs? |

> **@@SCAN**: (1) Hostile Interrogation run? (2) Drift OOM Scan executed (if applicable)? (3) Supportability tradeoffs documented?

## Phase 2: Continuous Integration (CI) Gate

| Step | Execution Contract |
|---|---|
| **Quality Sweep**| MANDATORY "Mini-Sweep":<br>1. Run native auto-formatter (e.g., `dart format .`, `dotnet format`, `prettier`) on modified code.<br>2. Run `grep_search` on touched files to block sloppy code (leftover `print()`, `console.log`, `TODO:`, or hardcoded styling/colors). |
| **Execution** | Stop Dev Servers -> Run ALL tests globally (`flutter test`, `dotnet test`). PROHIBITED: Isolated test runs (`flutter test path/...`). MUST prove no legacy assertions broke. |
| **Pass/Fail Logic**| IF (Tests Green AND Zero Warnings) -> Proceed Phase 3. IF (Any Fail/Warning) -> **MANDATORY TRANSITION**: `/diagnose`. Do NOT ask permission. |

> **@@SCAN**: (1) Build passed with zero warnings? (2) IF failed -> transitioned to `/diagnose`?

## Phase 3: Deliverable (The Metrics Snapshot)

| Step | Execution Contract |
|---|---|
| **Coverage & Metrics Gen** | MANDATORY: Execute available tooling to calculate Test Coverage, Cyclomatic Complexity, File Sizing, and Mutation scores (e.g., `dotnet test /p:CollectCoverage=true`). The human relies on these metrics to govern the factory; do not skip them. |
| **Artifact Form** | MANDATORY: Use `write_to_file` to save `verification_[YYYYMMDD]_[ConversationID]_[topic].md` into the `brain/` directory. MUST INCLUDE: (1) The Quantitative Metrics Dashboard (Coverage %, Complexity, Warnings count), and (2) Terminal log proof of the green test suite. |
| **Yield & Handoff** | Yield to the user with the exact Next Command explicitly referencing `{Absolute_Path_to_verification_artifact.md}`. |

> [!IMPORTANT]
> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}rain\{Conversation ID}"`
> - `Code 0`: *"Workflow complete. Share summary."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).