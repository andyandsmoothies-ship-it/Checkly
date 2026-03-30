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

> **@@SCAN** Before context mapping, PAUSE and INTERNALLY evaluate: (1) Which skills did you load? (2) What modern patterns or libraries did you discover?

## Phase 2: E2E Context Mapping (MANDATORY)
- **Instruction**: Map full context (upstream triggers + downstream effects) before evaluating options.
- **Action**:
  1. **Map full scope**: Identify everything this decision touches.
  2. **Document current state**: How is it handled today? Identify friction points.
  3. **Identify handoff points**: Where must user/system leave one context for another?
- **Output**: Structured summary of full E2E context map.

> **@@SCAN** Before feasibility check, PAUSE and INTERNALLY evaluate: (1) Did you map the full E2E scope (upstream triggers + downstream effects)? (2) What are the handoff points / friction points you identified?

## Phase 3: Blind-Spot & Conflict Detection
- **Instruction**: Act as adversarial "Explorer". Find failure points.
- **Action**: 
  1. Identify exactly 3 **BLIND SPOTS**.
  2. Identify ≥1 **`!!! CONFLICT`** with architectural rules in `.agents/rules/` or project gotchas.

> **@@SCAN** Before feasibility check, PAUSE and INTERNALLY evaluate: (1) What are the 3 Blind Spots? (2) What is the `!!! CONFLICT` or risk to existing rules?

## Phase 4: Feasibility & Rules Check
- **Instruction**: Evaluate the idea against the project's rigid constraints.
- **Skill Refresh**: If the research shifted domains (e.g., started as "which database?" but now involves "auth architecture"), re-scan `.agents/skills/` for skills matching the new concern. Load 1-2 if relevant.
- **Action**: Read the workspace rules in `.agents/rules/`. Does the proposed idea violate any existing architecture or security constraints?

> **@@SCAN** Before writing deliverable, PAUSE and INTERNALLY evaluate: (1) Does the idea violate any workspace rules? (2) Is the recommendation Viable, Needs Redesign, or Reject?

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
- **Handoff**: Recommend next workflow. Do NOT generate `implementation_plan.md`.
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

## Final Phase: Hard Verification Gate (Script-Enforced)

> [!IMPORTANT]
> **No honor system.** You are FORBIDDEN from self-certifying completion with "Yes/No" answers. A deterministic script performs the audit instead. Follow these steps exactly.

<strict-instruction>

**Step 1 — Run the verification script:**
```
cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"
```
Substitute `{App Data Directory}` and `{Conversation ID}` with the values injected in your system context at session start.

**Step 2 — Interpret the result:**
- **Exit Code 0 (✅ PASS):** The workflow is officially complete. Share the script's output summary with the user and stop.
- **Exit Code 1 (❌ FAIL):** Read the exact error lines the script printed. Fix ONLY what the script reported. Run the script again.

**Step 3 — 2-Strike Rule:**
If the script fails **twice** on the same error after your fixes, you have hit an unresolvable blocker.
- STOP immediately.
- Write `handoff_[topic].md` describing the script error, what you tried, and what remains.
- Tell the user: *"Hard gate failed twice. Blocked on: [exact error]. See handoff file."*

</strict-instruction>