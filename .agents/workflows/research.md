---
name: Research Workflow
description: Architect's Strategic Research Workflow for System Architecture.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /research

> [!NOTE]
> This is the **Discovery & Architecture** workflow — used to explore new ideas or libraries before writing code.
> Handoff usually goes to `/analysis` or directly to `/implement`.

## Pre-Flight Setup
> [!IMPORTANT]
> Synthesize internal reasoning BEFORE starting deliverables. Do NOT pollute artifacts with internal monologue.
> **Raw Data Requirement**: Track reasoning via table: `Hypothesis | Source Checked | Rejected/Approved | Architectural Implication`.

## Phase 1: Skill & Persona Alignment
- **Instruction**: Assume the role of a Senior Architect.
- **Skill Discovery**: Derive 2-3 technical keywords from the research topic (e.g., "first-principles", "challenge assumptions"). Use `grep_search` on `.agents/skills/` to find skills matching those keywords. Load ONLY the top 1-2 most relevant architectural `SKILL.md` files. Declare which skills were loaded.
- **Action**: Query `context7` or perform web searches to gather modern patterns.

> **@@SCAN**: (1) Which skills loaded? (2) Modern patterns discovered?

## Phase 2: E2E Context Mapping (MANDATORY)
- **Instruction**: Map full context (upstream triggers + downstream effects) before evaluating options.
- **Action**:
  1. **Map full scope**: Identify everything this decision touches.
  2. **Document current state**: How is it handled today? Identify friction points.
  3. **Identify handoff points**: Where must user/system leave one context for another?
- **Output**: Structured summary of full E2E context map.

> **@@SCAN**: (1) Full E2E scope mapped (upstream + downstream)? (2) Handoff/friction points identified?

## Phase 3: Blind-Spot & Conflict Detection
- **Instruction**: Act as adversarial "Explorer". Find failure points.
- **Action**: 
  1. Identify exactly 3 **BLIND SPOTS**.
  2. Identify ≥1 **`!!! CONFLICT`** with architectural rules in `.agents/rules/` or project gotchas.

> **@@SCAN**: (1) 3 Blind Spots named? (2) CONFLICT with existing rules identified?

## Phase 4: Feasibility & Rules Check
- **Instruction**: Evaluate the idea against the project's rigid constraints.
- **Skill Refresh**: If the research shifted domains (e.g., started as "which database?" but now involves "auth architecture"), re-scan `.agents/skills/` for skills matching the new concern. Load 1-2 if relevant.
- **Action**: Read the workspace rules in `.agents/rules/`. Does the proposed idea violate any existing architecture or security constraints?

> **@@SCAN**: (1) Workspace rule violations? (2) Verdict: Viable / Needs Redesign / Reject?

## Phase 5: Deliverable (The Handoff)
- **Requirement**: Output structured artifact that persists across sessions.
- **Action**:
  1. Create `research_[topic].md` artifact using `write_to_file` (IsArtifact: true).
  2. Copy deliverable to `.agents/tmp/research/research_[topic].md` via terminal (`Copy-Item` / `cp`). Do NOT use `write_to_file` with IsArtifact: false for this path.
  3. Include E2E Workflow Map from Phase 2.
  4. End with **Handoff Block**.
- **Effort Sizing**:
  - **Sprint/Theme**: Multiple domains -> recommend `shaping` skill.
  - **Epic (Track C)**: Massive change -> recommend `/analyze-epic`.
  - **Feature (Track A/B)**: Scoped change -> recommend `/analyze-feature`.
- **Handoff**: Hand `research_[topic].md` to the user and recommend next workflow.
- **Final Message**: Print absolute file path to `.agents/tmp/research/` deliverable.

### Handoff Block Template (MANDATORY at end of deliverable)
```markdown
---
## Handoff Block
- **Verdict**: Viable / Needs Redesign / Reject
- **Effort Sizing**: Sprint/Theme | Epic (Track C) | Feature (Track A/B)
- **Recommended Next**: `shaping` skill | `/analyze-epic` | `/analyze-feature`
- **Persistent Path**: `.agents/tmp/research/research_[topic].md`
- **Blind Spots**: [3 items from Phase 3]
- **Conflicts**: [items from Phase 3, or NONE]
```

---

## Final Phase: Script Verification Gate
Run EXACTLY:
`cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`

- Code 0 (PASS): Workflow complete. Tell user to pass artifact to next agent.
- Code 1 (FAIL): Fix reported errors and retry.
- 2-Strike Rule: Same error fails twice → STOP. Write `handoff_[topic].md` with error. Tell user: "Hard gate blocked on: [error]".