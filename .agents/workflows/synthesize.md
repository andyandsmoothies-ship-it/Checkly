---
description: Synthesize and rigorously compare multiple research artifacts. Use this workflow when the user asks to compare options, pick a winner, or run the Thunderdome process.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /synthesize (The Thunderdome)

> [!NOTE]
> Used to compare multiple competing research artifacts from isolated `/research` sessions and force a mathematically backed, rigorously red-teamed decision.

## Phase 1: Ingestion & Task Setup
- [ ] **Task Tracking**: Create `task.md` using the standard schema.
- [ ] **Load Research**: Execute `list_dir` on `.agents/tmp/research/` to find all competing research options.
- [ ] **Read Artifacts**: Use `view_file` to thoroughly read the contents of each competing option.
- [ ] **Normalize**: Extract the core "Hypothesis" and "Blast Radius" from each option.
> **@@SCAN**: (1) All competing artifacts loaded? (2) Hypothesis/Blast Radius distinctly gathered?

## Phase 2: Hostile Interrogation (Red Teaming)
- [ ] **MANDATORY**: For *every single option*, you MUST invent a catastrophic production failure scenario (e.g., memory leak, offline sync conflict, build failure, security bypass). 
- [ ] **Constraint Enforcement**: You are explicitly forbidden from being polite or making appeasing statements like "both are good." You must be highly skeptical.
> **@@SCAN**: (1) Hostile attack invented for EVERY option? (2) Safety mitigations analyzed without bias (No appeasement)?

## Phase 3: The Pugh Decision Matrix
- [ ] **Evaluate NFRs**: Create a Markdown table scoring each option against the project's strict Non-Functional Requirements (e.g., Offline Sync Capability, Main Thread Performance, Database Load, Blast Radius, Token Payload Size).
- [ ] **Scoring System**: Choose one option as the Baseline (`0`). Score competing options as Better (`+1`) or Worse (`-1`) relative to the baseline across all NFRs. Tabulate the final score.
> **@@SCAN**: (1) Matrix strictly tabulated? (2) Baseline declared? (3) Final mathematical winner identified?

## Phase 4: Architectural Decision Record (ADR) Generation
- [ ] **Generate ADR**: Produce a final artifact named `decision_record_[topic].md` (IsArtifact: True).
- [ ] **Payload Schema**: The output MUST include:
    1. `<latent_space_scratchpad>` for internal debate.
    2. The normalized summary of options.
    3. The Red Team attack vectors.
    4. The Pugh Decision Matrix.
    5. The Final Verdict (The mathematical winner).
- [ ] **Persist Copy**: Copy the deliverable to `.agents/tmp/research/decision_record_[topic].md` using the terminal.
- [ ] **Verification**: Run `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"` to validate the output format.
> **@@SCAN**: (1) ADR Schema respected (Latent Debate, Pugh Matrix)? (2) python verifier script executed and passed?
