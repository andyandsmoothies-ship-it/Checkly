---
description: Synthesize and rigorously compare multiple research artifacts. Use this workflow when the user asks to compare options, pick a winner, or run the Thunderdome process.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /synthesize (The Thunderdome)

> [!NOTE]
> Used to compare multiple competing research artifacts from isolated `/research` sessions and force a mathematically backed, rigorously red-teamed decision.

## Phase 1: Ingestion & Task Setup
- [ ] **Task Tracking**: Create `task_[ConversationID].md` using the standard schema.
- [ ] **Load Research**: Execute `list_dir` on `.agents/tmp/research/` to find all competing research options.
- [ ] **Read Artifacts**: Use `view_file` to thoroughly read the contents of each competing option.
- [ ] **Normalize**: Extract the core "Hypothesis", "Blast Radius", and the `[ORIGIN_IDEA]` from each option.
- [ ] **Traceability Lock**: You MUST explicitly declare the original `[ORIGIN_IDEA]` at the top of your assessment.
> **@@SCAN**: (1) All competing artifacts loaded? (2) Hypothesis/Blast Radius distinctly gathered? (3) Origin Idea explicitly declared?

## Phase 2: Hostile Interrogation (Red Teaming)
- [ ] **MANDATORY**: For *every single option*, you MUST invent a catastrophic production failure scenario (e.g., memory leak, offline sync conflict, build failure, security bypass). 
- [ ] **Constraint Enforcement**: You are explicitly forbidden from being polite or making appeasing statements like "both are good." You must be highly skeptical.
> **@@SCAN**: (1) Hostile attack invented for EVERY option? (2) Safety mitigations analyzed without bias (No appeasement)?

## Phase 3: The Pugh Decision Matrix
- [ ] **Evaluate NFRs**: Create a Markdown table scoring each option against the project's strict Non-Functional Requirements (e.g., Offline Sync Capability, Main Thread Performance, Database Load, Blast Radius).
- [ ] **Origin Idea Alignment Gate**: You MUST include "Origin Idea Alignment" as the highest-weight row in the matrix. If a technically brilliant option does not solve the user's actual starting idea, it must be heavily penalized.
- [ ] **Scoring System**: Choose one option as the Baseline (`0`). Score competing options as Better (`+1`) or Worse (`-1`) relative to the baseline. Tabulate the final score.
> **@@SCAN**: (1) Matrix strictly tabulated? (2) Baseline declared? (3) Final mathematical winner identified?

## Phase 4: Architectural Decision Record (ADR) Generation
- [ ] **Generate ADR**: MANDATORY: Use `write_to_file` to save `decision_record_[topic]_[ConversationID].md` to the `brain/` directory. NEVER output the ADR directly to the chat UI.
- [ ] **Payload Schema**: The output MUST include:
    1. `[ORIGIN_IDEA]`: The immutable core business goal, preserved at the top.
    2. `<latent_space_scratchpad>` for internal debate.
    3. The normalized summary of options.
    4. The Red Team attack vectors.
    5. The Pugh Decision Matrix.
    6. The Final Verdict (The mathematical winner).
    6. **Executive Business Summary**: A plain-English translation for the Product Owner explaining *what this means in real life* (e.g., business benefits, operational tradeoffs, maintenance costs, and UX impact).
    7. **Handoff Block Suffix:** You MUST append a `## Handoff Block` at the absolute EOF containing: (1) Final Verdict, (2) Strict Constraints (critical context the next Agent must not ignore), (3) Execution Slices if applicable, (4) The exact next workflow command, which MUST explicitly reference `{Absolute_Path_to_decision_record.md}` instead of pasting contents.
- [ ] **Persist Copy**: Copy the deliverable to `.agents/tmp/research/decision_record_[topic]_[ConversationID].md` using the terminal. **MANDATORY: You must explicitly verify the file exists at the destination path (e.g. via `dir` or `list_dir`) before yielding control.**
- [ ] **Verification**: 
> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> **@@SCAN**: (1) ADR Schema respected (Latent Debate, Pugh Matrix)? (2) python verifier script executed and passed?
