---
name: Research Workflow
description: Architect's Strategic Research Workflow for System Architecture.
---

# Workflow: /research

> [!NOTE]
> This is the **Discovery & Architecture** workflow — used to explore new ideas or libraries before writing code.
> Handoff usually goes to `/analysis` or directly to `/implement`.

<!-- HUD:START — Delete this block to remove the Live Dashboard from all workflows -->
// turbo
3. **Launch Live Web Dashboard**: Run cmd /c "start /b node .agents\tools\agent-web-hud.js" to launch the background server and open the UI in the browser.
<!-- HUD:END -->
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
- **Handoff**: If the research concludes the idea is viable, recommend the user run `/analysis` to produce a proper implementation plan. Do NOT generate an `implementation_plan.md` from this workflow — research lacks the system impact analysis and adversarial review required for a quality plan.