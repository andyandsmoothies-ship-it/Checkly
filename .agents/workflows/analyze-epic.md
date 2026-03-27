---
name: Deep Epic Analysis Workflow
description: Architect's Strategic Research Workflow for Massive Epic Systems (Track C).
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /analyze-epic

## Step 0: Context Initialization (CRITICAL FAIL-SAFE)
> [!IMPORTANT]
> Before you draft any plans, you MUST verify you fully understand the global governance rules.
> **Rule**: If you do not currently have the exact contents of `.agents/rules/governance-rules.md` in your active memory, you MUST use the `view_file` tool to read it right now. Do not proceed to Phase 1 until confirming adherence.

> [!NOTE]
> This is the **Deep Architecture Pipeline** — used for massive, multi-layer epics (Track C) that require extreme rigor, Red Team adversarial review, and formal use-case slicing. 
> For simple features or bugs, abort this workflow and switch to `/analyze-feature`.

## Pre-Flight Setup (ANTI-POISONING MANDATE)
> [!IMPORTANT]
> You MUST immediately create a `thinking_log_epic_[topic].md` artifact using `write_to_file` BEFORE starting your analysis. All internal reasoning, hypothesis generation, and rejected ideas must go there. Do NOT pollute structured artifacts with internal monologue.

## Phase 1: Technical Discovery & Reuse Audit
- **Instruction**: Assume the role of a Principal Software Engineer. Your first job is to determine if we should build this at all.
- **Consume Research (MANDATORY)**: Check if the user provided a `concept_brief_[topic].md` or `research_[topic].md` in the chat context. Read it to consume the E2E Workflow Map before beginning your analysis.
- **Skill Discovery**: Load high-level architectural skills (e.g., `first-principles-thinking`, `clean-architecture`, `ecosystem-advisor`). Declare which skills were loaded.
- **Reuse vs. Build (CRITICAL)**: Use `grep_search` and `codebase_search` to determine if the requirement can be met by configuring existing components. 

> **@@SCAN** Before proceeding, answer: (1) Which skills did you load and why? (2) Can this requirement be met by reusing existing code? (3) What are the core entities/tables this epic touches?

## Phase 2: Feasibility & System Impact Audit
- **Instruction**: Evaluate the business logic and system impact against all workspace rules in `.agents/rules/`.
- **System Impact Audit**: You MUST actively search for cross-feature conflicts. **Action**: Identify the core database tables, shared services, or global states this new epic touches. **You must use file-search tools (`grep_search`, `codebase_search`) to find all existing usages of those components in the workspace.** 
- **Action**: Identify logical flaws, unhandled edge cases, security risks, side-effects, and deviations from established project standards.

> **@@SCAN** Before proceeding, answer: (1) What existing features could break? (2) Which workspace rules from `.agents/rules/` constrain this epic? (3) Did you use file-search tools to find ALL existing usages of the affected components?

## Phase 3: Adversarial Review (Red Team)
- **Instruction**: Switch to a "Red Team Adversary" persona. Your goal is to destroy the proposed implementation plan before it is coded. Be aware of the "Expert Witness Trap" — AI models will pass flawed logic unless explicitly asked about scaling extremes.
- **Skill Refresh**: Re-scan `.agents/skills/` for skills related to error handling, concurrency, or debugging patterns. Load 1-2 if relevant.
- [ ] **Hostile Interrogation**: Run the **Hostile Interrogation** gate from `verification-loop` skill (Part C) to evaluate the design against domain scale extremes. Do not proceed until the 3 failure questions are answered.
- [ ] **Resolution**: Refine the solution to mitigate the identified failures. If the failures cannot be mitigated, reject the epic and request a redesign.

> **@@SCAN** Before proceeding, answer: (1) Did you run the Hostile Interrogation gate (verification-loop Part C)? (2) What are the 3 failure scenarios you identified? (3) Were any failures unmitigable?

## Phase 4: The Deliverable (Production-Grade Architecture Document)
- **Requirement**: You MUST create a rigorous, structured `analysis_epic_[topic].md` artifact. This is a Software Engineering Design Document.
- **The artifact MUST include the following mandatory sections**:
  1. **Executive Summary & Goals**: What are we building and why?
  2. **System Architecture & Data Flow**: Clear description of how the system will interact across the UI, Backend (API), and Database. Use a Mermaid diagram if complex.
  3. **Database & Schema Changes**: Table modifications, migrations, and index strategies.
  4. **API Contracts**: Request/Response payloads and endpoint designs.
  5. **System Impact & Blast Radius**: Explicit list of existing features/components that could break and how they are protected.
  6. **Adversarial Review & Edge Cases**: The 3 Red Team failures and their mitigations. Error handling strategies (offline, timeouts, invalid data).
  7. **Security & Permissions**: RLS, Auth, or authorization checks required.
  8. **Behavioral Expectations (EDD)**: You MUST generate 3-5 clear, plain-text expectations for the feature. Incorporate the "Hostile Expectations" generated by the Red Team. 

> **@@SCAN** Before proceeding, answer: (1) Does your artifact include ALL 8 mandatory sections? List any you skipped and why.

## Phase 5: Task Slicing & Dispatch
- **Instruction**: Because this is a Track C (Large Epic) task, you MUST NOT hand this directly to `/implement`. It must be sliced into Track A/B tactical pieces.
- **Action**: 
  1. Use the `view_file` tool to load the `.agents/skills/use-case-slicing/SKILL.md` skill.
  2. Following its methodology, slice the epic defined in `analysis_epic_[topic].md` into independent, end-to-end Track A or Track B slices.
  3. Append the list of Slices to the bottom of the `analysis_epic_[topic].md` document.
- **Handoff**: Present the slice list to the user. State clearly that each slice must now be run through `/analyze-feature` to generate a tactical implementation plan.

---

## Final Phase: Self-Correction Gate (CRITICAL)
<strict-instruction>
Before concluding this workflow and replying to the user, you MUST self-audit your output against the global rules of this specific project. You are required to literally type out the following checklist in your final message:

1. **Thinking Process Check**: Did I isolate my internal reasoning into a dedicated thinking log file as dictated by this project's artifact rules? (Yes/No)
2. **Template Check**: Did I include the mandatory header sections (e.g., `# Requirement Summary`) required by this project? (Yes/No)
3. **Tracking Update**: Did I update the primary task tracking document with an inventory of my generated artifacts? (Yes/No)
4. **Integrity Audit**: Did I include the mandatory attribution/compliance block in my final response? (Yes/No)

You are strictly FORBIDDEN from handing off this task to the user until you have achieved 'Yes' on all 4 checks. If any answer is 'No', use your file tools to correct the mistake immediately.
</strict-instruction>
