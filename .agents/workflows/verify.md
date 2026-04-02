---
name: Verification Workflow
description: Universal verification gate proving upstream artifacts (code, plans, audits) are structurally sound, performant, and correctly implemented.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /verify

> [!CAUTION]
> **[READ_ONLY_LOCK]**: The Sentinel persona is strictly READ-ONLY. PROHIBITED: "In-Flight Corrections" or executing `replace_file_content`. IF regression found THEN STOP -> trigger `/diagnose` -> handoff to Forge.

## Phase 1: Context & Accountability Audit

| Audit Vector | Execution Contract |
|---|---|
| **Skill Load** | Extract 2-3 keywords -> `grep_search` `.agents/skills/` -> Load Verification/Testing skills. |
| **Side Effects** | MANDATORY: Assess code changes for framework state loss, missing locks, or illegal ghost imports based on `.agents/rules/`. |
| **Verification**| MANDATORY: Semi-Formal Reasoning. Trace code path line-by-line. PROHIBITED: Assuming behavior based on function names. |
| **Criteria Check**| `grep_search` upstream `implementation_plan.md` → verify every AC is realized in code. If AC involves API/DTO: verify realization exists in BOTH `server/` and `lib/`. Flag omissions. |
| **EDD Proof** | MANDATORY: Demand **Executed Evidence** (logs, API responses). PROHIBITED: Accepting "Generative Evidence" (Builder claiming it works). |

> **@@SCAN**: (1) Code path traced line-by-line? (2) All ACs verified against real code on both stacks?

## Phase 1.5: Adversarial Interrogation (Red Team)

| Interrogation Vector | Execution Contract |
|---|---|
| **Hostile Gate** | Execute **Hostile Interrogation** (Part C of `verification-loop` skill). Must answer 3 failure questions. |
| **Drift OOM Scan**| IF (Flutter/Drift `*_queries.dart` / `*_manager.dart`) THEN SCAN for `.get()`. MUST possess limit OR aggregate OR explicit safety comment. IF missing -> FAIL (OOM violation). |
| **Efficiency Eval** | MANDATORY: Evaluate N+1 queries, memory leaks, Big-O complexity. PROHIBITED: Declaring SUCCESS simply because tests pass if UX degrades. |

> **@@SCAN**: (1) Hostile Interrogation run? (2) Drift OOM Scan executed (if applicable)?

## Phase 2: Continuous Integration (CI) Gate

| Step | Execution Contract |
|---|---|
| **Execution** | Stop Dev Servers -> Run strict build & test pipeline (`npm run build`, `dotnet build`, etc.). |
| **Pass/Fail Logic**| IF (Tests Green AND Zero Warnings) -> Proceed Phase 3. IF (Any Fail/Warning) -> **MANDATORY TRANSITION**: `/diagnose`. Do NOT ask permission. |

> **@@SCAN**: (1) Build passed with zero warnings? (2) IF failed -> transitioned to `/diagnose`?

## Phase 3: Deliverable (Continuous Verification)

| Step | Execution Contract |
|---|---|
| **Skill Refresh** | Re-scan `.agents/skills/` for code-review/security skills to detect slow-burn tech debt. |
| **Artifact Form** | Create `walkthrough_[topic]_[time].md`. Include EDD Executed Evidence (terminal logs/test outputs). |
| **Handoff Lock** | Write `handoff_[topic].md` (Phases + Gate State) before context dilution. |

> [!IMPORTANT]
> **Script Verification Gate**:
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Workflow complete. Share summary."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).