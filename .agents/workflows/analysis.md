---
name: Analysis Workflow
description: Precision Analysis Workflow for System Architecture.
---

# Workflow: /analysis

> [!NOTE]
> This is the **System & Business Analysis** workflow — used to evaluate solutions, analyze business logic, verify architecture feasibility, and identify edge cases before implementation.

## Phase 1: Analytical Setup
- **Instruction**: Assume the role of an Expert System Analyst / Business Analyst.
- **Skill Discovery**: You must proactively identify the correct skills without the user explicitly telling you. Derive technical keywords from the feature scope, use `grep_search` on `.agents/skills/` to find matches, and load ONLY the top 1-2 most relevant analytical `SKILL.md` files (e.g., architecture, database-design).
- **Action**: Review the proposed solution, feature request, or existing component architecture thoroughly.

## Phase 2: Feasibility & Edge Case Audit
- **Instruction**: Evaluate the business logic and system impact against all workspace rules in `.agents/rules/`.
- **System Impact Audit**: You MUST actively search for cross-feature conflicts. **Action**: Identify the core database tables, shared services, or global states this new feature touches. **You must use file-search tools (`grep_search`, `codebase_search`) to find all existing usages of those components in the workspace.** Only after reading the existing usages can you answer: "What existing feature will break if we implement this?"
- **Action**: Identify logical flaws, unhandled edge cases, security risks, side-effects, and deviations from established project standards. Do not just look at code; physically execute analysis tools to verify the *entire system behavior*.

## Phase 3: Adversarial Review (Red Team)
- **Instruction**: Switch to a "Red Team Adversary" persona. Your goal to destroy the proposed implementation plan before it is coded.
- **Action**: Explicitly write out at least 3 reasons why the proposed architecture, logic, or implementation plan could fail in production. Consider concurrency, race conditions, memory leaks, security bypasses, or missing offline states.
- **Resolution**: Refine the solution to mitigate the 3 identified failures. If the failures cannot be mitigated, reject the feature and request a redesign.

## Phase 4: Deliverable (The Handoff)
- **Requirement**: Output an analysis artifact describing the evaluation AND the results of the adversarial review.
- **Action**: Create an `analysis_[topic].md` artifact detailing the edge cases, business logic gaps, identified adversaries, and architectural recommendations.
- **Handoff (Task Routing & Slicing)**: If the analysis approves moving forward, you MUST categorize the task and break it down accordingly for the user.
  - **Track A - Tiny Tasks (e.g., typo fixes, color changes)**: Advise the user that `/analysis` was overkill and they should take these directly to `/implement` in the future. Output a 1-sentence `implementation_plan.md`.
  - **Track B - Small/Medium Tasks (Low/Medium complexity)**: Slicing is not needed. Generate a single `implementation_plan.md` outlining the requirements. Instruct the user to hand it directly to `/implement` (No ATDD required).
  - **Track C - Large Tasks (Crosses all layers, high complexity, new epic)**: You MUST vertically slice the feature. Before generating the Micro-Specs, you MUST invoke the `use-case-slicing` skill (based on Use-Case 3.0) to ensure your slices are structurally perfect (End-to-End, UI down to DB). Output the main `analysis_[topic].md` artifact, and then explicitly list out independent, sequential "Micro-Specs". Instruct the user to execute these slices one by one through the full `/atdd` -> `/implement` -> `/verify` pipeline.