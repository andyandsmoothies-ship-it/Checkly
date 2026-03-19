---
name: Analysis Workflow
description: Precision Analysis Workflow for System Architecture.
---

# Workflow: /analysis

> [!NOTE]
> This is the **System & Business Analysis** workflow — used to evaluate solutions, analyze business logic, verify architecture feasibility, and identify edge cases before implementation. It is designed to produce production-grade Software Engineering Tech Specs.

<!-- HUD:START — Delete this block to remove the Live Dashboard from all workflows -->
// turbo
3. **Launch Live Web Dashboard**: Run cmd /c "start /b node .agents\tools\agent-web-hud.js" to launch the background server and open the UI in the browser.
<!-- HUD:END -->
## Phase 1: Analytical Setup
- **Instruction**: Assume the role of an Expert System Analyst / Principal Software Engineer.
- **Skill Discovery**: Derive 2-3 technical keywords from the feature scope. Use `grep_search` on `.agents/skills/` to find matches (by filename pattern or SKILL.md content). Load ONLY the top 1-2 most relevant analytical `SKILL.md` files. Declare which skills were loaded.
- **Action**: Review the proposed solution, feature request, or existing component architecture thoroughly.

## Phase 2: Feasibility & System Impact Audit
- **Instruction**: Evaluate the business logic and system impact against all workspace rules in `.agents/rules/`.
- **System Impact Audit**: You MUST actively search for cross-feature conflicts. **Action**: Identify the core database tables, shared services, or global states this new feature touches. **You must use file-search tools (`grep_search`, `codebase_search`) to find all existing usages of those components in the workspace.** Only after reading the existing usages can you answer: "What existing feature will break if we implement this?"
- **Action**: Identify logical flaws, unhandled edge cases, security risks, side-effects, and deviations from established project standards. Do not just look at code; physically execute analysis tools to verify the *entire system behavior*.

## Phase 3: Adversarial Review (Red Team)
- **Instruction**: Switch to a "Red Team Adversary" persona. Your goal is to destroy the proposed implementation plan before it is coded.
- **Skill Refresh**: The concern has shifted to failure modes. Re-scan `.agents/skills/` for skills related to error handling, concurrency, or debugging patterns. Load 1-2 if relevant.
- **Action**: Explicitly write out at least 3 reasons why the proposed architecture, logic, or implementation plan could fail in production. Consider concurrency, race conditions, memory leaks, security bypasses, or missing offline states.
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

## Phase 5: Task Routing & Handoff
- **Action**: Based on the `analysis_[topic].md`, categorize the task and break it down for the user.

  - **Track A - Tiny Tasks (e.g., typo fixes, color changes)**: Advise the user that `/analysis` was overkill and they should take these directly to `/implement` in the future. Output a 1-sentence `implementation_plan.md`.

  - **Track B - Small/Medium Tasks (Low/Medium complexity)**: Slicing is not needed. Load the `technical-specification` skill (`.agents/skills/technical-specification/SKILL.md`) and generate a single `implementation_plan.md` using a **lightweight subset** of its template — include only: Executive Summary, Proposed Changes (grouped by file with [NEW]/[MODIFY]/[DELETE] tags), Database/Schema Changes (if any), API Contracts (if any), and Verification Plan. **Omit** non-functional requirements, phased timelines, and rate limiting sections. Instruct the user to hand it directly to `/implement` (No ATDD required).

  - **Track C - Large Tasks (Crosses all layers, high complexity, new epic)**: This track requires two sequential steps:
    1. **Step 1 — Slice**: You MUST vertically slice the feature FIRST. Search `.agents/skills/` for the `use-case-slicing` skill and invoke it to ensure your slices are structurally sound (End-to-End, UI down to DB). List the slices in the `analysis_[topic].md` artifact.
    2. **Step 2 — Per-Slice Tech Spec**: For EACH slice, you MUST load the `technical-specification` skill (`.agents/skills/technical-specification/SKILL.md`) and use its template to generate a dedicated specification document: `spec_[slice_name].md`. Each spec MUST include: Executive Summary, Functional Requirements with acceptance criteria, Database Schema changes, API Contracts, and a Verification Plan.
    3. **Handoff**: Present the list of spec documents to the user. Instruct them to execute each slice one by one through the full `/atdd` -> `/implement` -> `/verify` pipeline.