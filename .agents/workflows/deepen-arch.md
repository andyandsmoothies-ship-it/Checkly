---
description: Find and deepen shallow architectural modules. Increases testability, locality, and leverage by designing better seams.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /deepen-arch

> [!NOTE]
> **Role: Principal Architect**. 
> Goal: Eliminate architectural friction by turning shallow modules (interface $\approx$ implementation) into deep modules (small interface hiding vast complexity). 

## Glossary (Mandatory Vocabulary)
- **Module** — Anything with an interface and an implementation (function, class, package).
- **Interface** — Everything a caller must know (types, invariants, ordering, errors).
- **Depth** — Leverage at the interface. High behaviour behind a small interface.
- **Seam** — Where an interface lives; a boundary for substitution.
- **Adapter** — A concrete implementation injected at a seam.
- **Leverage** — What callers get from depth.
- **Locality** — What maintainers get from depth (fix bugs in one place).

## Phase 1: Explore & Propose

| Step | Execution Contract |
|---|---|
| **Trigger** | Execute when user asks to improve architecture, refactor tight coupling, or `/deepen-arch`. |
| **Exploration** | Use `grep_search` and `view_file` to find friction. Look for: (1) Shallow modules. (2) Untestable coupling. (3) Wasted abstractions (deletion test: if you delete it, does complexity just move?). |
| **Candidate List**| Output a numbered list of 3 deepening opportunities. For each provide:<br>- **Files**: Affected modules.<br>- **Problem**: Why it causes friction.<br>- **Solution**: What would change.<br>- **Benefits**: Explained via Leverage and Locality. |

> **MANDATORY @@SCAN**: You MUST print the candidate list and then explicitly YIELD to the user: *"Which of these would you like to explore?"*

## Phase 2: Design It Thrice

| Step | Execution Contract |
|---|---|
| **Trigger** | The user selects a candidate from Phase 1. |
| **Constraint Gen** | You MUST generate 3 radically different interface designs sequentially in a single response. |
| **Design 1 (Minimalist)** | Minimize the interface (1–3 entry points max). Maximize leverage. |
| **Design 2 (Flexible)** | Maximize flexibility, extension, and adaptability. |
| **Design 3 (Ergonomic)** | Optimize for the most common caller. Make the default case trivial. |
| **Output Format** | For each design provide: (1) Interface Signature, (2) Caller Usage Example, (3) What is hidden, (4) Dependency Strategy (In-process, Local-substitutable, or Remote/Port&Adapter), (5) Trade-offs. |

> **MANDATORY @@SCAN**: After presenting all 3 designs, state your personal recommendation as Principal Architect and YIELD: *"Which design approach should we lock in?"*

## Phase 3: The Verdict Payload

| Step | Execution Contract |
|---|---|
| **Refinement** | Work with the user to finalize the chosen interface. |
| **Documentation** | If the new deep module introduces new domain concepts not present in the project, recommend adding them to `GEMINI.md`. |
| **Artifact Gen** | Create an implementation plan (e.g., `implementation_plan_[timestamp]_[id]_deepen_[topic].md`) detailing the exact file modifications required to build the new seam and adapter. |

## Phase 4: Deliverable Handoff

### Final Generation Mandate (Suffix)
> [!IMPORTANT]
> **Handoff Block Suffix:** You MUST append a `## Handoff Block` at the absolute EOF containing:
> 1. Summary of the chosen interface and seams.
> 2. **AI Agent Mission Brief** (A short TL;DR so the Builder agent knows exactly what to do).
> 3. The exact next workflow command the user should run: e.g., `@[/implement] {Absolute_Path_to_Implementation_Plan}`.

> [!IMPORTANT]
> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`
