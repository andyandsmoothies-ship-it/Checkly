---
description: Architect's Strategic Research Workflow for System Architecture.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /research

> [!NOTE]
> Discovery & Architecture workflow. Used to explore ideas *before* spec writing. Handoff to `/analyze-epic` (for massive systems) or `/analyze-feature` (for tactical additions).

## Phase 0: Pre-Flight
> [!IMPORTANT]
> **[DATA_REQUIREMENT]**: Track reasoning exclusively via Matrix: `Hypothesis | Source Checked | Rejected/Approved | Architectural Implication`. PROHIBITED: Internal monologue in artifacts.

## Phase 1: Skill & E2E Context Alignment

| Vector | Execution Contract |
|---|---|
| **Task Tracking** | MANDATORY: Create `task_[YYYYMMDD_HHMMSS]_[ConversationID]_[topic].md` using the strict schema BEFORE proceeding. List ONLY the research artifact in the Artifact Inventory. Reserve target source code files for the subsequent implementation phase. |
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
| **Artifact Gen** | MANDATORY: Use `write_to_file` to save `research_[YYYYMMDD_HHMMSS]_[ConversationID]_[topic].md` to the `brain/` directory. NEVER output the research directly to the chat UI. |
| **Workspace Copy**| MANDATORY: Because the `brain/` folder is invisible to the user's IDE, you MUST copy the generated research artifact to `.agents/tmp/research/` so the user can review it. Output the absolute path to this visible file in your final message. |
### Final Generation Mandate (Suffix)
> [!IMPORTANT]
> **Payload Schema:** Your generated `research_[YYYYMMDD_HHMMSS]_[ConversationID]_[topic].md` MUST INCLUDE: 
> 1. `[ORIGIN_IDEA]`: A strictly preserved, 1:1 summary of the user's original business goal/idea from the prompt. This anchors all future workflows.
> 2. `<latent_space_scratchpad>`: Before writing your final plan, use this block to explicitly state your internal reasoning, debate architectural tradeoffs, and explore edge cases to artificially expand your test-time compute.
> 3. `E2E Workflow Map`
> 4. `Comparative Decision Matrix`
> 5. Strict `<forensic_evidence>` tags (proof of executed commands).
> 
> **Handoff Block Suffix:** You MUST append a `## Handoff Block` at the absolute EOF containing:
> 1. Final Verdict (Viable/Reject) & Persistent path.
> 2. Effort Sizing (Track C / Track A/B) and Concurrency Strategy.
> 3. **AI Agent Mission Brief** (A short, concise 1-2 sentence TL;DR so the next AI agent instantly knows exactly what to do).
> 4. The exact next workflow command the user should run, which MUST explicitly reference `{Absolute_Path_to_research_artifact.md}` instead of pasting contents.
> [!IMPORTANT]
> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Workflow complete. Tell user to pass artifact to next agent."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).