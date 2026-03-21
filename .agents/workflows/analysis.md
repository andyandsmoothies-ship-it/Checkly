---
name: Analysis Workflow
description: Precision Analysis Workflow for System Architecture.
---

# Workflow: /analysis

> [!NOTE]
> This is the **System & Business Analysis** workflow — used to evaluate solutions, analyze business logic, verify architecture feasibility, and identify edge cases before implementation. It is designed to produce production-grade Software Engineering Tech Specs.


## Phase 1: Technical Discovery & Reuse Audit
- **Instruction**: Assume the role of a Principal Software Engineer. Your first job is to determine if we should build this at all or if it can be achieved by reusing/configuring existing code.
- **Skill Discovery**: Derive 2-3 technical keywords from the feature scope (e.g., "first-principles", "think from scratch"). Use `grep_search` on `.agents/skills/` to find matches. Load ONLY the top 1-2 most relevant `SKILL.md` files. Declare which skills were loaded.
- **Reuse vs. Build (CRITICAL)**: Use `grep_search` and `codebase_search` to determine if the requirement can be met by configuring or deleting existing components. If it can, skip to Phase 4 and recommend reuse/refactoring.

## Phase 2: Feasibility & System Impact Audit
- **Instruction**: Evaluate the business logic and system impact against all workspace rules in `.agents/rules/`.
- **System Impact Audit**: You MUST actively search for cross-feature conflicts. **Action**: Identify the core database tables, shared services, or global states this new feature touches. **You must use file-search tools (`grep_search`, `codebase_search`) to find all existing usages of those components in the workspace.** Only after reading the existing usages can you answer: "What existing feature will break if we implement this?"
- **Action**: Identify logical flaws, unhandled edge cases, security risks, side-effects, and deviations from established project standards. Do not just look at code; physically execute analysis tools to verify the *entire system behavior*.

## Phase 3: Adversarial Review (Red Team)
- **Instruction**: Switch to a "Red Team Adversary" persona. Your goal is to destroy the proposed implementation plan before it is coded.
- **Skill Refresh**: The concern has shifted to failure modes. Re-scan `.agents/skills/` for skills related to error handling, concurrency, or debugging patterns. Load 1-2 if relevant.
- **Action**: Explicitly write out at least 3 reasons why the proposed solution could fail in production. Consider concurrency, race conditions, memory leaks, security bypasses, or missing offline states.
- **Resolution**: Refine the solution to mitigate the 3 identified failures. If the failures cannot be mitigated, reject the feature and request a redesign.

## Phase 4: The Deliverable (Production-Grade Architecture Document)
- **Requirement**: You MUST create a rigorous, structured `analysis_[topic].md` artifact. This is NOT a code diff; it is a Software Engineering Design Document.
- **The artifact MUST include the following mandatory sections**:
  1. **Executive Summary & Goals**: What are we building and why?
  2. **System Architecture & Data Flow**: Clear description of how the system will interact across the UI, Backend (API), and Database. Use a Mermaid diagram if complex.
  3. **Database & Schema Changes**: (If applicable) Table modifications, migrations, and index strategies.
  4. **API Contracts**: (If applicable) Request/Response payloads and endpoint designs.
  5. **System Impact & Blast Radius**: Explicit list of existing features/components that could break and how they are protected.
  6. **Adversarial Review & Edge Cases**: The 3 Red Team failures and their mitigations. Error handling strategies (offline, timeouts, invalid data).
  7. **Security & Permissions**: RLS, Auth, or authorization checks required.
  8. **Complexity Assessment**: State whether this task is Small (single concern), Medium (multiple concerns), or Large (crosses all layers). This drives Track classification in Phase 5.

## Phase 5: Task Routing & Handoff
- **Action**: Read the `analysis_[topic].md` produced in Phase 4. Based on its findings (blast radius, complexity, layer count), categorize the task into one of the tracks below.

  - **Track A — Small Tasks (Single concern, low blast radius)**:
    Generate a single `implementation_plan_[topic].md` using a lightweight template: Executive Summary, Proposed Changes (grouped by file with [NEW]/[MODIFY]/[DELETE] tags), Database/Schema Changes (if any), API Contracts (if any), and Verification Plan.
    **Handoff**: `/implement` → (optionally) `/verify`.

  - **Track B — Medium Tasks (Multiple concerns, moderate blast radius)**:
    Generate a single `implementation_plan_[topic].md` with: Executive Summary, Proposed Changes (grouped by file), Database/Schema Changes, API Contracts, System Impact & Blast Radius, and Verification Plan with explicit scenarios.

    Then apply the **ATDD Decision Gate** to determine the pipeline:

    | Signal | Skip ATDD (B1) | Require ATDD (B2) |
    |--------|----------------|---------------------|
    | Correctness | Obvious from the spec | Ambiguous — multiple valid interpretations |
    | Pattern | Extends existing, well-understood pattern | New pattern or algorithm |
    | State | Simple flag/branch | Complex state machine or multi-step transitions |
    | Edge cases | Few, easily enumerated in verification table | Many, easy to miss without formal test writing |
    | Risk | Low — failure is visible and recoverable | High — silent corruption or data loss |

    **B1 Handoff**: `/implement` → `/verify`.
    **B2 Handoff**: `/atdd` → `/implement` → `/verify`.

  - **Track C — Large Tasks (Crosses all layers, high complexity, new epic)**:
    This track requires vertical slicing FIRST, then per-slice classification.
    1. **Step 1 — Slice**: Search `.agents/skills/` for the `use-case-slicing` skill and invoke it. List the slices in the `analysis_[topic].md` artifact.
    2. **Step 2 — Per-Slice Classification**: For EACH slice, classify it as **Track A**, **Track B1**, or **Track B2** using the same decision gate above. Generate the appropriate artifact for each:
       - **Track A slices** → `implementation_plan_[slice].md` → `/implement`
       - **Track B1 slices** → `implementation_plan_[slice].md` → `/implement` → `/verify`
       - **Track B2 slices** → `implementation_plan_[slice].md` → `/atdd` → `/implement` → `/verify`
    3. **Handoff**: Present the slice list with each slice's track. Execute in dependency order.