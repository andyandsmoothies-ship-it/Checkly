---

description: Structured UX heuristic evaluation based on Nielsen Norman Group methodology.

---

# Workflow: /ux-heuristic-eval

> [!NOTE]

> Systematic UX review against Nielsen's 10 Heuristics. Role: **Senior UX Evaluator**.

## Step 1: Discovery, Chunking & Scope

| Step | Execution Contract |

|---|---|

| **Task Tracking** | MANDATORY: Create `docs/features/[topic]/task_[topic]_[YYYYMMDD_HHMMSS].md` using the strict schema BEFORE proceeding. |

| **Skill Load** | MANDATORY: Load `ux-heuristic-evaluation` skill. |

| **Auto-Chunking**| Ask the user for the main sitemap or `router.dart`. Divide the app into logical "Chunks" (e.g. Login Flow). Present the chunks and ask the user to confirm starting with Chunk 1. |

| **Scope Extract**| Document the Target Screen(s) for the current chunk, User Group (e.g. Admin), and Device Type. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) App chunked? (2) User/Device targeted? (3) Skill loaded?

## Step 2: Source Code Walkthrough

| Step | Execution Contract |

|---|---|

| **Code Parse** | `view_file` on target UI source code. Trace callbacks, navigation, and state handlers. |

| **State Mapping**| MANDATORY: Define page behavior under 4 extremes: `Loading`, `Empty`, `Error`, `Offline`. |

| **Visual Bias** | PROHIBITED: Relying solely on screenshots. Code logic dictates UX. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Loading/Empty/Error/Offline modeled? (2) Actions/Feedback traced?

## Step 3: Heuristic Double-Pass

| Step | Execution Contract |

|---|---|

| **Pass 1: Flow** | Execute task conceptually as User Persona. |

| **Pass 2: Audit**| Evaluate flow against 10 Heuristics. |

| **Exceptions** | Mark deliberate design tradeoffs as "Justified Exceptions" (NOT violations). |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Double Pass executed? (2) Violations mapped to heuristics? (3) Tradeoffs documented?

## Step 4: Delivery Payload

| Step | Execution Contract |

|---|---|

| **Aggregation** | Group issues. Sort by severity. Extract Top 3 Impact Fixes. |

| **Artifact Gen** | Create `ux_heuristic_eval_[scope].md` in the `{App Data Directory}\brain\{Conversation ID}\` directory. |

| **Payload Schema**| `Summary` | `Scorecard (✅/⚠️/❌)` | `Sorted Findings` | `Top 3 Fix Priorities` | `Tradeoffs`. |

| **Routing** | Output message: *"Route fixes through Feature Analysis -> Implementation using this exact path: `{Absolute_Path_to_ux_heuristic_eval.md}`"* -> YIELD. |

> [!IMPORTANT]

> **Script Verification Gate (MANDATORY)**:

> You MUST use the `run_command` tool to execute this script before considering the task complete.

> // turbo

> `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`

> - `Code 0`: *"Workflow complete. Share summary with absolute paths."*

> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>
