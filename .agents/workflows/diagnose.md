---

description: High-Compliance Diagnostic Workflow for System Errors.

---

# Workflow: /diagnose

> [!NOTE]

> Enforces systematic root cause analysis. PROHIBITED: Guessing.

## Step 1: Pre-Flight (Anti-Poisoning Mandate)

- **Task Tracking**: MANDATORY: Create `docs/features/[topic]/task_[topic]_[YYYYMMDD_HHMMSS].md` using the strict schema below BEFORE proceeding. List ONLY the diagnostic artifact in the Artifact Inventory. Reserve target source code files for the subsequent implementation step.

- **Reasoning Steps**: Structure internal thoughts via exactly 4 steps: `Initial Hypothesis`, `Evidence Gathered`, `Root Cause Identified`, `Fix Strategy`. PROHIBITED: Outputting monologue outside `docs/features/[topic]/task_[topic]_[YYYYMMDD_HHMMSS].md`.

```markdown

# Task: [Bug / Error Topic Name]

Workflow: /diagnose | Track: [A / B1 / B2 / C]

## Input Lineage

- **Source Input**: `[Absolute_Path_to_Source_File_or_Input]`

## Steps

- [ ] Step 2: Symptom Isolation

- [ ] Step 3: Skill & Rule Discovery

- [ ] Step 4: Resolution Plan

- [ ] Step 5: Deliverable Handoff

## Artifact Inventory

| Status | File Path | Type |

| [NEW]  | docs/reports/diagnostics/failure_report_[YYYYMMDD_HHMMSS].md | Report |

```

## Step 2: The Feedback Loop & Isolation

- **The Feedback Loop**: MANDATORY: Before guessing, construct a fast, deterministic pass/fail signal. Use a failing test, a `curl` script, or a throwaway harness. PROHIBITED: Hypothesizing without a reproducible loop.

- **Log Extraction**: Script-First: Check if `.agents/scripts/collect_logs.py` exists. Execute it to aggregate trace logs into `docs/reports/diagnostics/`.

- **Origin Trace**: MANDATORY: Trace data flows to their origin (the Write-Path). PROHIBITED: Stopping at the Read-Path symptom.

- **Pattern Identification**: Explicitly identify the System Design Pattern where the failure occurred (e.g., "This is a Two-Step Commit failure" or "This is a Cache Stampede"). Diagnosing the pattern reveals the root cause much faster than reading logs blindly.

- **Formal Reasoning**: MANDATORY: 1. Generate 3-5 *falsifiable* Hypotheses ("If X is the cause, then changing Y will prove it"). 2. Log them strictly to the `task_` file.

- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Did you build a fast, deterministic feedback loop (curl/test)? (2) Did you trace back to the Write-Path origin? (3) Are 3-5 falsifiable hypotheses explicitly written in the `task_` file?

## Step 3: Skill & Rule Discovery

- **Skill Load**: Extract 2-3 keywords (e.g., "ground-truth"). `grep_search` `.agents/skills/`. Load Top 2 Error/Debug skills.

- **Rule Bounds**: Consult `.agents/rules/` for known locking/state gotchas that explain failure.

- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Debug skills loaded? (2) Any `.agents/rules/` explain failure?

## Step 4: Root Cause Synthesis & Validation

- **Skill Refresh**: IF (Root cause domain != Symptom domain) THEN Re-scan and load new Domain `SKILL.md`.

- **First Principles Gate**: MANDATORY: Evaluate and answer these 4 questions in your report:
  1. *Physics & Limit*: What physical system limit (network, memory, lock, CPU) causes this, and what is the absolute source of truth?
  2. *Simplicity Check*: What is the simplest way to describe the failure mechanism to a human or another agent?
  3. *Blast Radius*: If this root cause is left unaddressed, what is the worst-case system impact?
  4. *Observability*: How can we observe/detect the symptoms of this failure in production logs or metrics?

- **Artifact Gen**: Export `failure_report_[YYYYMMDD_HHMMSS].md`.

- **Constraint (Micro-Experiments)**: PROHIBITED: Proposing or writing permanent fix code. ALLOWED: "Micro-Experiments" (max 5 lines) only to trigger the failure or verify the root cause. IF the test fails to reproduce the bug twice, you MUST formally reject your hypothesis in the `task_` file and pivot.

- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Is the code change strictly under 5 lines and only used for validation? (2) If a test failed to reproduce the issue twice, did you officially pivot to a new hypothesis? (3) Did you answer all 4 First Principles Gate questions?

## Step 5: Deliverable Handoff

- **Gotcha Protocol**: MANDATORY: Propose edits to the local sub-folder's `GEMINI.md` (e.g., `server/GEMINI.md` or `lib/GEMINI.md`) if a project-specific rule caused the bug. ELSE: State "No new gotcha".

- **Routing**: MANDATORY: Output an "Execution Queue" checklist in the final chat response containing the exact build command (e.g., `- [ ] Execute Diagnostic Step: docs/reports/diagnostics/failure_report.md`) so the user can easily pass the diagnostic report to a planning/implementation agent. -> YIELD.

### Final Generation Mandate (Suffix)

> [!IMPORTANT]

<output_schema>

> **Payload Schema:** Your `failure_report_[YYYYMMDD_HHMMSS].md` MUST INCLUDE: `## Input Lineage` (the absolute path of the input bug report/log), `Root Cause Description`, `Explicit Code Trace (Premises + Proof)`, and `<forensic_evidence>` tags logging all terminal tools/commands executed. Do NOT propose fixes or write fix code in this report; focus strictly on root-cause verification.

>

> **Handoff Block Suffix:** You MUST append a `## Handoff Block` at the absolute EOF containing:

> 1. Final Diagnostic Verdict & Persistent path.

> 2. The identified root cause and its blast radius.

> 3. **AI Agent Mission Brief** (A short, concise 1-2 sentence TL;DR so the planning or builder agent instantly knows exactly what root cause they need to address).

> 4. An "Execution Queue" checklist of the exact commands for the user to copy-paste (e.g., `- [ ] Execute Diagnostic Verification: docs/reports/diagnostics/failure_report.md`).
>
> **Analysis Trace**: If requested, record the step-by-step trace of all analyzing activities from start to end in `docs/reports/diagnostics/traces/trace_analysis_[YYYYMMDD_HHMMSS].md` (short and concise).
>
> **Update docs/features/[topic]/task_[topic]_[YYYYMMDD_HHMMSS].md**: Convert `[/]` to `[x]` and detail absolute file paths.

> **Document Cleanup (Required)**:
> Automatically clean up and organize newly created markdown plans into their correct topic folders:
> // turbo

> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`

> - `Code 0`: *"Handoff complete."*

> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>

</output_schema>
