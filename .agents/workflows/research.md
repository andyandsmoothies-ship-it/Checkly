---
name: Research Workflow
description: Architect's Strategic Research Workflow for System Architecture.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /research

> [!NOTE]
> Discovery & Architecture workflow. Used to explore ideas *before* spec writing. Handoff to `/analysis` or `/implement`.

## Phase 0: Pre-Flight
> [!IMPORTANT]
> **[DATA_REQUIREMENT]**: Track reasoning exclusively via Matrix: `Hypothesis | Source Checked | Rejected/Approved | Architectural Implication`. PROHIBITED: Internal monologue in artifacts.

## Phase 1: Skill & E2E Context Alignment

| Vector | Execution Contract |
|---|---|
| **Task Tracking** | MANDATORY: Create `task.md` using the strict schema BEFORE proceeding. |
| **Skill Load** | Extract 2-3 architectural keywords -> Load 1-2 skills from `.agents/skills/`. |
| **Discovery** | IF (tech is very new/rare) THEN query Context7 MCP to save hallucination. ELSE rely on model baseline to save API credits. |
| **E2E Map** | MANDATORY: Map Upstream Triggers + Downstream Effects. Identify Status Quo friction. Map exact system Context Handoff points. If touching API/DTO/DB, `grep_search` BOTH `lib/` and `server/` — never treat either side as a black box. |

> **@@SCAN**: (1) Skills loaded/Patterns discovered? (2) Full E2E Scope mapped across BOTH lib/ and server/? (3) Friction points identified?

## Phase 2: Strategy Assessment

| Vector | Execution Contract |
|---|---|
| **Comparables**| MANDATORY: Identify 2-3 top viable options. Evaluate against NFRs (Performance, Offline Limits, Tech Stack). |
| **Blind Spots**| MANDATORY: Identify EXACTLY 3 blind spots regarding NFRs (payload size, memory). |
| **Conflicts** | MANDATORY: Identify >= 1 Conflict with existing `.agents/rules/` or `GEMINI.md` gotchas. |

> **@@SCAN**: (1) Alternatives evaluated? (2) 3 Blind spots cited? (3) >1 Rules Conflict cited?

## Phase 3: Deliverable & Sizing

| Step | Execution Contract |
|---|---|
| **Artifact Gen** | Create `research_[topic].md` (IsArtifact: True). |
| **Persist Copy** | Copy deliverable to `.agents/tmp/research/research_[topic].md` via terminal `cp` command. |
### Final Generation Mandate (Suffix)
> [!IMPORTANT]
> **Payload Schema:** Your generated `research_[topic].md` MUST INCLUDE: an `E2E Workflow Map`, a `Comparative Decision Matrix`, and strict `<forensic_evidence>` tags (proof of executed commands).
> 
> **Handoff Block Template** (Must be appended at the absolute EOF):
> ```markdown
> ---
> ## Handoff Block
> - **Verdict**: Viable / Needs Redesign / Reject
> - **PoC Scope**: [Define PoC boundary if highly risky]
> - **Downsides & Risks**: [Explicitly list UX degradation, maintenance burden]
> - **Effort Sizing**: Sprint/Theme | Epic (Track C) | Feature (Track A/B)
> - **Recommended Next**: `shaping` | `/analyze-epic` | `/analyze-feature`
> - **Persistent Path**: `.agents/tmp/research/research_[topic].md`
> - **Blind Spots**: [3 explicit flaws]
> - **Conflicts**: [Explicit constraints broken]
> ```
> [!IMPORTANT]
> **Script Verification Gate**:
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Workflow complete. Tell user to pass artifact to next agent."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).