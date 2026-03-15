---
name: Analysis Workflow
description: Precision Analysis Workflow for System Architecture.
---

# Workflow: /analysis

> [!NOTE]
> This is the **System & Business Analysis** workflow — used to evaluate solutions, analyze business logic, verify architecture feasibility, and identify edge cases before implementation. It is designed to produce production-grade Software Engineering Tech Specs.

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
  - **Track B - Small/Medium Tasks (Low/Medium complexity)**: Slicing is not needed. Generate a single `implementation_plan.md` outlining the technical specs required for implementation, mapping securely to the analysis document. Instruct the user to hand it directly to `/implement` (No ATDD required).
  - **Track C - Large Tasks (Crosses all layers, high complexity, new epic)**: You MUST vertically slice the feature. Search `.agents/skills/` for any slicing or use-case decomposition skill and invoke it to ensure your slices are structurally sound. Output the main `analysis_[topic].md` artifact, and then explicitly list out independent, sequential "Micro-Specs". Instruct the user to execute these slices one by one through the full `/atdd` -> `/implement` -> `/verify` pipeline.