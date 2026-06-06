---

description: Find and deepen shallow architectural modules. Increases testability, locality, and leverage by designing better seams.

---

# Workflow: /deepen-arch

> [!IMPORTANT]
> **Required Skill**: You MUST read and load the `improve-codebase-architecture` skill before proceeding. This ensures correct use of the glossary and enables visual HTML reporting.

> [!NOTE]
> **Role: Principal Architect**.
> Goal: Eliminate architectural friction by turning shallow modules (interface ≈ implementation) into deep modules (small interface hiding vast complexity).

## When to Start This Workflow
Use this workflow in the following cases:
1. **Before building a new feature** (e.g. after `/define-requirements`): If the existing codebase is too coupled or complex to cleanly support the new feature, use `/deepen-arch` first to prepare the codebase.
2. **After a major feature launch**: If a lot of code was added and you feel some parts have become messy, duplicated, or "shallow".
3. **When you don't know where to start but feel friction**: If editing code is slow, buggy, or requires changing many unrelated files.

### Lifecycle Context
```
[User Request / New Epic] 
       │
       ▼
[Define Requirements (/define-requirements)]
       │
       ▼
Is the current architecture ready for this?
 ├── Yes ──> [Feature Analysis (/analyze-feature)] ──> [Implementation (/implement)]
 └── No  ──> [Deepen Architecture (/deepen-arch)] ──> [Feature Analysis (/analyze-feature)] ──> [Implementation (/implement)]
```

## Glossary (Mandatory Vocabulary)

- **Module** — Anything with an interface and an implementation (function, class, package).

- **Interface** — Everything a caller must know (types, invariants, ordering, errors).

- **Depth** — Leverage at the interface. High behaviour behind a small interface.

- **Seam** — Where an interface lives; a boundary for substitution.

- **Adapter** — A concrete implementation injected at a seam.

- **Leverage** — What callers get from depth.

- **Locality** — What maintainers get from depth (fix bugs in one place).

## Step 1: Explore & Propose

| Step | Execution Contract |

|---|---|

| **Trigger** | Execute when user asks to improve architecture, refactor tight coupling, or `/deepen-arch`. |

| **Exploration** | Find friction: (1) Shallow modules. (2) Untestable coupling. (3) Wasted abstractions. <br><br>**MANDATORY Blast Radius Check**: Before finalizing the list, you MUST use `grep_search`, `view_file`, or ANY other available tools and strategies to cross-reference upstream callers (how many files use this?), DB schemas (does this change a table?), and existing tests. Your trade-off/cost estimate must be exhaustively verified against codebase reality, not blind guessing. |

| **Candidate List**| Output an exhaustive, numbered list of ALL viable deepening opportunities found during your analysis. For each provide:<br>- **Files**: Affected modules.<br>- **Problem**: Why it causes friction.<br>- **Solution**: What would change.<br>- **Benefits**: Explained via Leverage and Locality.<br>- **Trade-offs / Cost**: The effort, risk, or blast radius required (e.g., requires database schema changes, massive refactoring). This ensures the user can weigh the ROI before selecting one to analyze. |

| **Candidate Pugh Matrix** | Create a Markdown table comparing all candidates against each other and the status quo. Score them on expected non-functional requirements (e.g., Expected Locality, Expected Leverage, Blast Radius Safety, Execution Cost). Score as Status Quo (`0`), Better (`+1`), or Worse (`-1`). This detailed comparison acts as the input for Step 2. |

> **MANDATORY @@SCAN**: You MUST print the candidate list, followed by the Candidate Pugh Matrix, and then explicitly YIELD to the user: *"Which of these would you like to explore?"*

## Step 2: Design It Thrice & Synthesize

| Step | Execution Contract |

|---|---|

| **Trigger** | The user selects a candidate from Step 1. |

| **Constraint Gen** | You MUST generate 3 radically different interface designs sequentially in a single response. |

| **Design 1 (Minimalist)** | Minimize the interface (1–3 entry points max). Maximize leverage. |

| **Design 2 (Flexible)** | Maximize flexibility, extension, and adaptability. |

| **Design 3 (Ergonomic)** | Optimize for the most common caller. Make the default case trivial. |

| **Output Format** | For each design provide: (1) Interface Signature, (2) Caller Usage Example, (3) What is hidden, (4) Dependency Strategy (In-process, Local-substitutable, or Remote/Port&Adapter), (5) Trade-offs. |

| **Pugh Matrix** | Create a Markdown table scoring each option (including the current baseline) against non-functional requirements (e.g., Locality, Leverage, Open-Closed Principle, Blast Radius). Score as Baseline (`0`), Better (`+1`), or Worse (`-1`). |

| **Conclusion** | State clearly and concisely which option is the absolute best fit for the whole context. The wording must be short and decisive. |

> **MANDATORY @@SCAN**: After presenting all 3 designs, the matrix, and the short conclusion, state your recommendation as Principal Architect and YIELD: *"Which design approach should we lock in?"*

## Step 3: The Verdict Payload

| Step | Execution Contract |

|---|---|

| **Refinement** | Work with the user to finalize the chosen interface. |

| **Documentation** | If the new deep module introduces new domain concepts not present in the project, recommend adding them to `GEMINI.md`. |

| **Architectural Decision Record (ADR)** | Do NOT generate an implementation plan. Instead, create an ADR artifact (e.g., `adr_[timestamp]_[id]_deepen_[topic].md`) summarizing the context, the 3 explored options, the Pugh Matrix, the locked-in interface, and any identified domain/schema gaps. This ADR must act as the primary input for the `analyze-feature` or `analyze-epic` workflow so that rigorous vertical slice impact analysis occurs before writing code. |

## Step 4: Deliverable Handoff

### Final Generation Mandate (Suffix)

> [!IMPORTANT]

> **Handoff Block Suffix:** You MUST append a `## Handoff Block` at the absolute EOF containing:

> 1. Summary of the chosen interface and seams.

> 2. **AI Agent Mission Brief** (A short TL;DR so the next agent knows exactly what to analyze).

> 3. The exact next workflow command the user should run to perform a holistic vertical slice analysis: e.g., `Start Feature Analysis on: {Absolute_Path_to_ADR}`.

> [!IMPORTANT]

> **Script Verification Gate (MANDATORY)**:

> You MUST use the `run_command` tool to execute this script before considering the task complete.

> // turbo

> `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>
