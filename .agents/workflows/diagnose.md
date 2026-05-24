---

description: High-Compliance Diagnostic Workflow for System Errors.

---

# Workflow: /diagnose

> [!NOTE]

> Enforces systematic root cause analysis. PROHIBITED: Guessing.

## Step 1: Pre-Flight (Anti-Poisoning Mandate)

- **Task Tracking**: MANDATORY: Create `.agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[ShortID]_[topic]_[ConversationID].md` using the strict schema below BEFORE proceeding. List ONLY the diagnostic artifact in the Artifact Inventory. Reserve target source code files for the subsequent implementation step.

- **Reasoning Steps**: Structure internal thoughts via exactly 4 steps: `Initial Hypothesis`, `Evidence Gathered`, `Root Cause Identified`, `Fix Strategy`. PROHIBITED: Outputting monologue outside `.agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[ShortID]_[topic]_[ConversationID].md`.

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

| [NEW]  | docs/diagnostics/failure_report_[YYYYMMDD_HHMMSS]_[ShortID]_[topic]_[ConversationID].md | Report |

```

## Step 2: The Feedback Loop & Isolation

- **The Feedback Loop**: MANDATORY: Before guessing, construct a fast, deterministic pass/fail signal. Use a failing test, a `curl` script, or a throwaway harness. PROHIBITED: Hypothesizing without a reproducible loop.

- **Log Extraction**: Script-First: Check if `.agents/scripts/collect_logs.py` exists. Execute it to aggregate trace logs into `docs/diagnostics/`.

- **Origin Trace**: MANDATORY: Trace data flows to their origin (the Write-Path). PROHIBITED: Stopping at the Read-Path symptom.

- **Pattern Identification**: Explicitly identify the System Design Pattern where the failure occurred (e.g., "This is a Two-Step Commit failure" or "This is a Cache Stampede"). Diagnosing the pattern reveals the root cause much faster than reading logs blindly.

- **Formal Reasoning**: MANDATORY: 1. Generate 3-5 *falsifiable* Hypotheses ("If X is the cause, then changing Y will prove it"). 2. Log them strictly to the `task_` file.

- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Did you build a fast, deterministic feedback loop (curl/test)? (2) Did you trace back to the Write-Path origin? (3) Are 3-5 falsifiable hypotheses explicitly written in the `task_` file?

## Step 3: Skill & Rule Discovery

- **Skill Load**: Extract 2-3 keywords (e.g., "ground-truth"). `grep_search` `.agents/skills/`. Load Top 2 Error/Debug skills.

- **Rule Bounds**: Consult `.agents/rules/` for known locking/state gotchas that explain failure.

- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Debug skills loaded? (2) Any `.agents/rules/` explain failure?

## Step 4: Resolution Plan

- **Skill Refresh**: IF (Root cause domain != Symptom domain) THEN Re-scan and load new Domain `SKILL.md`.

- **Redundancy Check**: MANDATORY: Before proposing a fix that swaps in a shared utility/widget, verify if it makes surrounding `if` guards or boilerplate redundant. Delete the redundant code.

- **Artifact Gen**: Export `failure_report_[YYYYMMDD_HHMMSS]_[ShortID]_[topic]_[ConversationID].md`.

- **Constraint (Micro-Experiments)**: PROHIBITED: Broad code refactors. ALLOWED: "Micro-Experiments" (max 5 lines) to falsify hypotheses. IF a test fails twice, you MUST formally reject it in the `task_` file and pivot.

- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) If code was changed, was it strictly under 5 lines? (2) Did you delete redundant guards when applying shared tools? (3) If a test failed twice, did you officially pivot to a new hypothesis?

## Step 5: Deliverable Handoff

- **Gotcha Protocol**: MANDATORY: Propose edits to the local sub-folder's `GEMINI.md` (e.g., `server/GEMINI.md` or `lib/GEMINI.md`) if a project-specific rule caused the bug. ELSE: State "No new gotcha".

- **Routing**: MANDATORY: Output an "Execution Queue" checklist in the final chat response containing the exact implementation command (e.g., `- [ ] Execute Build Step: docs/diagnostics/failure_report.md`) so the user can easily invoke the Builder Agent. -> YIELD.

### Final Generation Mandate (Suffix)

> [!IMPORTANT]

<output_schema>

> **Payload Schema:** Your `failure_report_[YYYYMMDD_HHMMSS]_[ShortID]_[topic]_[ConversationID].md` MUST INCLUDE: `## Input Lineage` (the absolute path of the input bug report/log), `Root Cause`, `Explicit Code Trace (Premises + Proof)`, `Proposed Scope-Limited Fix`, and `<forensic_evidence>` tags logging all terminal tools/commands executed.<br><br>**CRITICAL:** For the `Proposed Scope-Limited Fix`, you MUST present the **Trade-offs / Pros & Cons** of the solution (e.g., performance impact, edge cases). Yield to the user to make the final executive decision before jumping to implementation.

>

> **Handoff Block Suffix:** You MUST append a `## Handoff Block` at the absolute EOF containing:

> 1. Final Diagnostic Verdict & Persistent path.

> 2. The required fix and its blast radius.

> 3. **AI Agent Mission Brief** (A short, concise 1-2 sentence TL;DR so the next AI agent instantly knows exactly what to do).

> 4. An "Execution Queue" checklist of the exact commands for the user to copy-paste (e.g., `- [ ] Execute Build Step: docs/diagnostics/failure_report.md`).

>

> **Update .agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[ShortID]_[topic]_[ConversationID].md**: Convert `[/]` to `[x]` and detail absolute file paths.

>

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
