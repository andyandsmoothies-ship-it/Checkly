---
name: UX Heuristic Evaluation
description: Structured UX heuristic evaluation based on Nielsen Norman Group methodology.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /ux-heuristic-eval

> [!NOTE]
> Systematic UX review against Nielsen's 10 Heuristics. Role: **Senior UX Evaluator**.

## Phase 1: Preparation & Scope

| Step | Execution Contract |
|---|---|
| **Task Tracking** | MANDATORY: Create `task.md` using the strict schema BEFORE proceeding. |
| **Skill Load** | MANDATORY: Load `ux-heuristic-evaluation` skill. |
| **Scope Extract**| Identify Target Screen(s), User Group (e.g. Admin), and Device Type. IF missing -> Request from User. |

> **@@SCAN**: (1) Scope defined? (2) User/Device targeted? (3) Skill loaded?

## Phase 2: Source Code Walkthrough

| Step | Execution Contract |
|---|---|
| **Code Parse** | `view_file` on target UI source code. Trace callbacks, navigation, and state handlers. |
| **State Mapping**| MANDATORY: Define page behavior under 4 extremes: `Loading`, `Empty`, `Error`, `Offline`. |
| **Visual Bias** | PROHIBITED: Relying solely on screenshots. Code logic dictates UX. |

> **@@SCAN**: (1) Loading/Empty/Error/Offline modeled? (2) Actions/Feedback traced?

## Phase 3: Heuristic Double-Pass

| Step | Execution Contract |
|---|---|
| **Pass 1: Flow** | Execute task conceptually as User Persona. |
| **Pass 2: Audit**| Evaluate flow against 10 Heuristics. |
| **Exceptions** | Mark deliberate design tradeoffs as "Justified Exceptions" (NOT violations). |

> **@@SCAN**: (1) Double Pass executed? (2) Violations mapped to heuristics? (3) Tradeoffs documented?

## Phase 4: Delivery Payload

| Step | Execution Contract |
|---|---|
| **Aggregation** | Group issues. Sort by severity. Extract Top 3 Impact Fixes. |
| **Artifact Gen** | Create `ux_heuristic_eval_[scope].md`. |
| **Payload Schema**| `Summary` | `Scorecard (✅/⚠️/❌)` | `Sorted Findings` | `Top 3 Fix Priorities` | `Tradeoffs`. |
| **Routing** | Output message: *"Route fixes through /analyze-feature -> /implement."* -> YIELD. |

> [!IMPORTANT]
> **Script Verification Gate**:
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Workflow complete. Share summary."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).
