---

description: Synthesize and rigorously compare multiple research artifacts. Use this workflow when the user asks to compare options, pick a winner, or run the Thunderdome process.

---

# Workflow: /synthesize (The Thunderdome)

> [!NOTE]

> Used to compare multiple competing research artifacts from isolated `/research` sessions and force a mathematically backed, rigorously red-teamed decision.

## Step 1: Ingestion & Task Setup

- [ ] **Task Tracking**: Create `docs/reports/research/[topic]/task_[topic]_[YYYYMMDD_HHMMSS].md` using the standard schema. Include an `## Input Lineage` section tracking the input links/directories. List ONLY the final decision artifact in the Artifact Inventory. Reserve target source code files for the subsequent implementation step.

- [ ] **Load Research**: Execute `list_dir` on `docs/reports/research/[topic]/` (or the specific directory provided by the user) to find all competing research options.

- [ ] **Read Artifacts**: Use `view_file` to thoroughly read the contents of each competing option.

- [ ] **Normalize**: Extract the core "Hypothesis", "Blast Radius", and the `[ORIGIN_IDEA]` from each option.

- [ ] **Traceability Lock**: You MUST explicitly declare the original `[ORIGIN_IDEA]` at the top of your assessment.

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) All competing artifacts loaded? (2) Hypothesis/Blast Radius distinctly gathered? (3) Origin Idea explicitly declared?

## Step 2: Hostile Interrogation (Red Teaming)

- [ ] **MANDATORY**: For *every single option*, you MUST invent a catastrophic production failure scenario (e.g., memory leak, offline sync conflict, build failure, security bypass).

- [ ] **Constraint Enforcement**: You are explicitly forbidden from being polite or making appeasing statements like "both are good." You must be highly skeptical.

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Hostile attack invented for EVERY option? (2) Safety mitigations analyzed without bias (No appeasement)?

## Step 3: The Pugh Decision Matrix

- [ ] **First Principles Evaluation**: Grade all options against the 4 First Principles questions:
  1. *Physics & Limit*: What is the ultimate ceiling/scale limit (e.g. TPS, DB locks, memory) and at what exact scale will this implementation fail?
  2. *Simplicity*: How can this design be implemented with 50% fewer files/classes/lines of code, and what bloat/complexity is being introduced?
  3. *Blast Radius*: If this component fails (e.g., deadlocks, timeout, DB down), what other systems are impacted and how does it fail-gracefully?
  4. *Observability*: What metric, log, or telemetry proves this feature is healthy, and what is the exact alert condition for failure?
  You MUST integrate these questions as critical rows/criteria in the Pugh Decision Matrix to mathematically score each option against them.

- [ ] **Evaluate NFRs**: Create a Markdown table scoring each option against the project's strict Non-Functional Requirements (e.g., Offline Sync Capability, Main Thread Performance, Database Load, Blast Radius).

- [ ] **Origin Idea Alignment Gate**: You MUST include "Origin Idea Alignment" as the highest-weight row in the matrix. If a technically brilliant option does not solve the user's actual starting idea, it must be heavily penalized.

- [ ] **Scoring System**: Choose one option as the Baseline (`0`). Score competing options as Better (`+1`) or Worse (`-1`) relative to the baseline. Tabulate the final score.

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) First Principles Evaluated? (2) Matrix strictly tabulated? (3) Baseline declared? (4) Final mathematical winner identified?

## Step 4: Architectural Decision Record (ADR) Generation

- [ ] **Generate ADR**: MANDATORY: Use `write_to_file` to save `decision_record_[YYYYMMDD_HHMMSS].md` to the `docs/features/[topic]/` directory. NEVER output the ADR directly to the chat UI. Output the absolute path to this file in your final message.

- [ ] **Payload Schema**: The output MUST include:

    1. `## Input Lineage`: Absolute paths to the compared research artifacts.

    2. `[ORIGIN_IDEA]`: The immutable core business goal, preserved at the top.

    3. `<latent_space_scratchpad>` for internal debate.

    4. The normalized summary of options.

    5. The Red Team attack vectors.

    6. `## First Principles Gate`: Detailed answers to the 4 First Principles questions for each option.

    7. The Pugh Decision Matrix.

    8. The Final Verdict (The mathematical winner).

    9. **Executive Business Summary**: A plain-English translation for the Product Owner explaining *what this means in real life* (e.g., business benefits, operational tradeoffs, maintenance costs, and UX impact).

    10. **Handoff Block Suffix:** You MUST append a `## Handoff Block` at the absolute EOF containing: (1) Final Verdict, (2) Strict Constraints (critical context the next Agent must not ignore), (3) Execution Slices if applicable, (4) **Requirements Alignment Check**: If the winning technical architecture alters the user flow or business logic previously defined in a `requirements.md` file, you MUST explicitly inform the user that the Requirements document needs to be updated. (5) **AI Agent Mission Brief** (A short, concise 1-2 sentence TL;DR so the next AI agent instantly knows exactly what to do), (6) The exact next workflow command, which MUST explicitly reference `{Absolute_Path_to_decision_record.md}` instead of pasting contents.

- [ ] **Verification**:

> **Script Verification Gate (MANDATORY)**:

> You MUST use the `run_command` tool to execute this script before considering the task complete.

> // turbo

> `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) ADR Schema respected (Latent Debate, Pugh Matrix)? (2) python verifier script executed and passed?

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>
