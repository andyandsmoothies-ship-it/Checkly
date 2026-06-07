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

- **Locality** — What maintainers get from depth (fix bugs in one place).

## Step 1: Start & Task Tracking

- **Task Tracking**: Create `docs/features/[topic]/task_deepen_[topic]_[YYYYMMDD_HHMMSS].md` before exploring:

  ```markdown
  # Task: Deepen [Topic] | Workflow: /deepen-arch

  - **Source Input**: [Path]

  - [ ] Step 1: Start & Task Tracking | [ ] Step 2: Explore & Propose | [ ] Step 3: Design It Thrice & Synthesize | [ ] Step 4: The Verdict Payload | [ ] Step 5: Deliverable Handoff

  - **Artifact Inventory**:
    - docs/reports/deepen/[topic]/report_deepen_[topic]_[YYYYMMDD_HHMMSS].md
    - docs/adr/adr_[timestamp]_[id]_deepen_[topic].md
  ```

## Step 2: Explore & Propose

| Step | Execution Contract |
|---|---|
| **Trigger** | Execute when user asks to improve architecture, refactor tight coupling, or run `/deepen-arch`. |
| **Exploration Heuristics** | **Data-Driven Discovery**:<br>1. Identify largest files and longest methods using static analysis/grep/view tools.<br>2. **Restrict Scope**: Target a specific feature/folder instead of the whole project.<br>3. Ask key heuristics: *Duplicate logic? God class? Multiple files modified for one change?*<br><br>**Blast Radius Check**: Verify upstream callers, database schemas, and existing tests via grep/view tools. |
| **Candidate List & Pugh Matrix** | Output list of viable deepening opportunities. For each: files, problem, solution, benefits, and trade-offs/cost.<br>**Rule:** When listing trade-offs/costs, you MUST include a short and concise example of the **Best Context (When to use)** and **Worst Context (When to avoid)**.<br>Create a Candidate Pugh Matrix comparing all candidates against the Status Quo (`0`, `+1`, `-1`).<br><br>**Report Generation**: Write candidate details and matrix to `docs/reports/deepen/[topic]/report_deepen_[topic]_[YYYYMMDD_HHMMSS].md`. |

> [!IMPORTANT]
> **MANDATORY @@SCAN (Chat Payload Truncation)**: DO NOT print the full candidate list or Pugh Matrix in the chat. Write them directly to the report markdown file. In the chat, print only a short bulleted summary of candidates and the path to the report, then yield: *"Which candidate would you like to explore?"*

## Step 3: Design It Thrice & Synthesize

| Step | Execution Contract |
|---|---|
| **Trigger** | User selects a candidate. |
| **Constraint Gen** | Generate 3 distinct interface designs sequentially: (1) Minimalist, (2) Flexible, (3) Ergonomic. |
| **Pugh Matrix** | Score each design (and baseline) against Locality, Leverage, Open-Closed Principle, and Blast Radius (`0`, `+1`, `-1`). |
| **Conclusion** | Clearly state which design option is the best fit and why. |

> [!IMPORTANT]
> **MANDATORY @@SCAN (Chat Payload Truncation)**: Write the 3 design details, Pugh Matrix, and conclusion to the report/ADR file. In the chat, print only a short executive summary and the path to the file, then yield: *"Which design approach should we lock in?"*

## Step 4: The Verdict Payload

| Step | Execution Contract |
|---|---|
| **Refinement** | Finalize the chosen interface. |
| **Documentation** | If new domain concepts are introduced, document them in the project's global rules file. |
| **ADR** | Create an Architectural Decision Record (`docs/adr/adr_[timestamp]_[id]_deepen_[topic].md`) summarizing context, designs, Pugh Matrix, and locked-in interface. |

## Step 5: Deliverable Handoff

### Final Generation Mandate (Suffix)

> [!IMPORTANT]
> **Handoff Block Suffix:** You MUST append a `## Handoff Block` at the absolute EOF of your final response containing:
> 1. Summary of the chosen interface and seams.
> 2. **AI Agent Mission Brief** (A short TL;DR so the next agent knows exactly what to analyze/build).
> 3. The exact next workflow command the user should run: e.g., `Start Feature Analysis on: {Absolute_Path_to_ADR}`.

> [!IMPORTANT]
> **Script Verification Gate (MANDATORY)**:
> Execute the verification script (if available in project scripts) before considering the task complete:
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.
- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>

