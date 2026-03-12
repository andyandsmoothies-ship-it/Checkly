---
name: Research Workflow
description: Architect's Strategic Research Workflow for System Architecture.
---

# Workflow: /research

> [!NOTE]
> This is the **Discovery & Architecture** workflow — used to explore new ideas or libraries before writing code.
> Handoff usually goes to `/analysis` or directly to `/implement`.

## Phase 1: Skill & Persona Alignment
- **Instruction**: Assume the role of a Senior Architect.
- **Skill Discovery**: Derive 2-3 technical keywords from the research topic. Use `grep_search` on `.agents/skills/` to find skills matching those keywords. Load ONLY the top 1-2 most relevant architectural `SKILL.md` files. Declare which skills were loaded.
- **Action**: Query `context7` or perform web searches to gather modern patterns.

## Phase 2: Feasibility & Rules Check
- **Instruction**: Evaluate the idea against the project's rigid constraints.
- **Skill Refresh**: If the research shifted domains (e.g., started as "which database?" but now involves "auth architecture"), re-scan `.agents/skills/` for skills matching the new concern. Load 1-2 if relevant.
- **Action**: Read the workspace rules in `.agents/rules/`. Does the proposed idea violate any existing architecture or security constraints?

## Phase 3: Deliverable (The Handoff)
- **Requirement**: Always output a structured artifact.
- **Action**: Create a `concept_brief_[feature].md` or `research_[topic].md` artifact.
- **Handoff**: If the idea is approved to be built, output a final `implementation_plan.md` artifact containing the proposed architecture and file changes, so the `/implement` Builder agent can take over seamlessly.