---
name: Diagnostic Workflow
description: High-Compliance Diagnostic Workflow for System Errors.
---

# Workflow: /diagnose

> [!NOTE]
> This workflow enforces systematic root cause analysis. No guessing is allowed.

## Pre-Flight Setup (ANTI-POISONING MANDATE)
> [!IMPORTANT]
> You MUST immediately create a `thinking_log_[topic].md` artifact using `write_to_file` BEFORE investigating. All internal reasoning, hypothesis generation, and rejected ideas must go there. Do NOT pollute structured artifacts with internal monologue.

## Phase 1: Symptom Isolation (NO GUESSING)
<strict-instruction>
You MUST NOT guess the root cause of an error.
**Action**: Use the `grep_search` tool to locate the exact file and line number where the error occurred. Use the `view_file` tool to read the surrounding 50 lines of code before forming any hypothesis.

**Semi-Formal Reasoning Checklist (MANDATORY)**: Before proposing a fix, you must explicitly output:
1. **Explicit Premises**: Write down exactly what the code currently does based ONLY on the actual read file contents.
2. **Execution Trace**: Trace the exact execution path line-by-line using specific file names and line numbers.
3. **Formal Conclusion**: Prove your root cause conclusion with specific evidence from the trace. Do not rely on assumptions or naming conventions.
</strict-instruction>

> **@@SCAN** Before proceeding, answer: (1) What is the exact file and line number of the error? (2) What does the execution trace prove? (3) What is your root cause conclusion and its evidence?

## Phase 2: Skill & Rule Discovery
<strict-instruction>
- **Action**: Derive 2-3 keywords from the error symptom (e.g., "first-principles", "ground-truth"). Use `grep_search` in `.agents/skills/` to find any specialized debugging or error-analysis skills matching those keywords. Load the top 1-2 most relevant `SKILL.md` files.
- **Action**: Consult the `.agents/rules/` directory for project-specific sensitivities that might explain the failure (e.g., locking issues, state management). 
</strict-instruction>

> **@@SCAN** Before proposing a fix, answer: (1) Which skills did you load? (2) Do any project rules in `.agents/rules/` explain this failure?

## Phase 3: Resolution Plan
<strict-instruction>
- **Skill Refresh**: If the root cause points to a different domain than the symptom (e.g., symptom was UI but root cause is a database issue), re-scan `.agents/skills/` for skills matching the root cause domain. Load 1-2 if relevant.
- **Action**: Output a `failure_report_[topic].md` artifact detailing the Root Cause, the explicit trace that proves it, and the proposed fix. Do not make code changes directly in this workflow without user approval.
</strict-instruction>

> **@@SCAN** Before handoff, answer: (1) Does the failure report include the explicit execution trace? (2) Is the proposed fix scoped to the root cause only — no drive-by refactoring?

## Phase 4: Deliverable (The Handoff)
- **Handoff**: Instruct the user to take the `failure_report_[topic].md` artifact and feed it to the `/implement` Builder agent to execute the fix.