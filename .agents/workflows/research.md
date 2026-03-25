---
name: Research Workflow
description: Architect's Strategic Research Workflow for System Architecture.
---

@[../../../.gemini/GEMINI.md]

# Workflow: /research

> [!NOTE]
> This is the **Discovery & Architecture** workflow — used to explore new ideas or libraries before writing code.
> Handoff usually goes to `/analysis` or directly to `/implement`.


## Phase 1: Skill & Persona Alignment
- **Instruction**: Assume the role of a Senior Architect.
- **Skill Discovery**: Derive 2-3 technical keywords from the research topic (e.g., "first-principles", "challenge assumptions"). Use `grep_search` on `.agents/skills/` to find skills matching those keywords. Load ONLY the top 1-2 most relevant architectural `SKILL.md` files. Declare which skills were loaded.
- **Action**: Query `context7` or perform web searches to gather modern patterns.

> **@@SCAN** Before context mapping, answer: (1) Which skills did you load? (2) What modern patterns or libraries did you discover?

## Phase 2: E2E Context Mapping (MANDATORY)
- **Instruction**: Before evaluating ANY solution, you MUST map the **full context** that this feature or decision touches. Never evaluate an option in isolation — understand the complete picture first.
- **Action**:
  1. **Map the full scope**: Identify everything this decision touches from start to finish — not just the immediate change, but the upstream triggers and downstream effects.
  2. **Document the current state**: How does the system handle this today? Where are the friction points, errors, or workarounds?
  3. **Identify handoff points**: Where must a user (or a system) leave one context and go to another to complete their intent? Each handoff is a potential friction point or failure mode.
- **Output**: A structured summary showing the full context. Adapt the format to the topic (e.g., lifecycle table, integration diagram, data flow, dependency map, cost comparison).
- **Why**: A solution that works for one part of the picture may break another part entirely. The context map ensures every proposed option is stress-tested against the full scope before recommendation.

> **@@SCAN** Before feasibility check, answer: (1) Did you map the full E2E scope (upstream triggers + downstream effects)? (2) What are the handoff points / friction points you identified?

## Phase 3: Feasibility & Rules Check
- **Instruction**: Evaluate the idea against the project's rigid constraints.
- **Skill Refresh**: If the research shifted domains (e.g., started as "which database?" but now involves "auth architecture"), re-scan `.agents/skills/` for skills matching the new concern. Load 1-2 if relevant.
- **Action**: Read the workspace rules in `.agents/rules/`. Does the proposed idea violate any existing architecture or security constraints?

> **@@SCAN** Before writing deliverable, answer: (1) Does the idea violate any workspace rules? (2) Is the recommendation Viable, Needs Redesign, or Reject?

## Phase 4: Deliverable (The Handoff)
- **Requirement**: Always output a structured artifact.
- **Action**: Create a `concept_brief_[feature].md` or `research_[topic].md` artifact. The artifact MUST include the E2E Workflow Map from Phase 2.
- **Handoff**: If the research concludes the idea is viable, recommend the user run `/analysis` to produce a proper implementation plan. Do NOT generate an `implementation_plan.md` from this workflow — research lacks the system impact analysis and adversarial review required for a quality plan.