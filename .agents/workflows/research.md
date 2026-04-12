---
description: Architect's Strategic Research Workflow for System Architecture.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /research

> [!NOTE]
> Discovery & Architecture workflow. Used to explore ideas *before* spec writing. Handoff to `/analysis` or `/implement`.

## Phase 0: Pre-Flight
> [!IMPORTANT]
> **[DATA_REQUIREMENT]**: Track reasoning exclusively via Matrix: `Hypothesis | Source Checked | Rejected/Approved | Architectural Implication`. PROHIBITED: Internal monologue in artifacts.

## Phase 1: Skill & E2E Context Alignment

| Vector | Execution Contract |
|---|---|
| **Task Tracking** | MANDATORY: Create `task_[ConversationID].md` using the strict schema BEFORE proceeding. |
| **Skill Load** | Extract 2-3 architectural keywords -> Load 1-2 skills from `.agents/skills/`. |
| **Status Quo Audit** | MANDATORY: Before proposing any new architecture, you MUST `grep_search` to find existing native implementations (e.g., existing auth guards, parsers). Your artifact MUST document the "Current Codebase Reality" to prevent generic textbook hallucinations. |
| **Discovery** | IF (tech is very new/rare) THEN query Context7 MCP to save hallucination. ELSE rely on model baseline to save API credits. |
| **E2E Map** | MANDATORY: Map Upstream Triggers + Downstream Effects. Identify Status Quo friction. Map exact system Context Handoff points. If touching API/DTO/DB, `grep_search` BOTH `lib/` and `server/` — never treat either side as a black box. |

> **@@SCAN**: (1) Skills loaded? (2) Status Quo explicitly audited? (3) Full E2E Scope mapped across lib/ and server/?

## Phase 2: Strategy Assessment

| Vector | Execution Contract |
|---|---|
| **Impact Spectrum**| MANDATORY: Present 3 distinct options: (A) Strict native fit, (B) Pragmatic balance, (C) Enterprise textbook overhaul. |
| **Blind Spots**| MANDATORY: Identify EXACTLY 3 blind spots regarding NFRs (payload size, memory). |
| **Conflicts** | MANDATORY: Identify >= 1 Conflict with existing `.agents/rules/` or `GEMINI.md` gotchas. |

> **@@SCAN**: (1) Alternatives evaluated? (2) 3 Blind spots cited? (3) >1 Rules Conflict cited?

## Phase 3: Deliverable & Sizing

| Step | Execution Contract |
|---|---|
| **Artifact Gen** | Create `research_[topic]_[ConversationID].md` (IsArtifact: True). |
| **Persist Copy** | Copy deliverable to `.agents/tmp/research/research_[topic]_[ConversationID].md` via terminal. **MANDATORY: You must explicitly verify the file exists at the destination path before yielding control.** |
### Final Generation Mandate (Suffix)
> [!IMPORTANT]
> **Payload Schema:** Your generated `research_[topic]_[ConversationID].md` MUST INCLUDE: 
> 1. `<latent_space_scratchpad>`: Before writing your final plan, use this block to explicitly state your internal reasoning, debate architectural tradeoffs, and explore edge cases to artificially expand your test-time compute.
> 2. `E2E Workflow Map`
> 3. `Comparative Decision Matrix`
> 4. Strict `<forensic_evidence>` tags (proof of executed commands).
> 
> **Handoff Block Suffix:** You MUST append a `## Handoff Block` at the absolute EOF containing:
> 1. Final Verdict (Viable/Reject) & Persistent path.
> 2. Effort Sizing (Track C / Track A/B) and Concurrency Strategy.
> 3. The exact next workflow command the user should run (e.g. `/analyze-epic`).
> [!IMPORTANT]
> **Script Verification Gate**:
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Workflow complete. Tell user to pass artifact to next agent."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).