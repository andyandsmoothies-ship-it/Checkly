---
name: Diagnostic Workflow
description: High-Compliance Diagnostic Workflow for System Errors.
---

# Workflow: /diagnose

> [!NOTE]
> This workflow enforces systematic root cause analysis. No guessing is allowed.

## Phase 1: Symptom Isolation (NO GUESSING)
<strict-instruction>
You MUST NOT guess the root cause of an error.
**Action**: Use the `grep_search` tool to locate the exact file and line number where the error occurred. Use the `view_file` tool to read the surrounding 50 lines of code before forming any hypothesis.

**Semi-Formal Reasoning Checklist (MANDATORY)**: Before proposing a fix, you must explicitly output:
1. **Explicit Premises**: Write down exactly what the code currently does based ONLY on the actual read file contents.
2. **Execution Trace**: Trace the exact execution path line-by-line using specific file names and line numbers.
3. **Formal Conclusion**: Prove your root cause conclusion with specific evidence from the trace. Do not rely on assumptions or naming conventions.
</strict-instruction>

## Phase 2: Skill & Rule Discovery
<strict-instruction>
- **Action**: Derive 2-3 keywords from the error symptom. Use the `grep_search` tool in the `.agents/skills/` directory to load any specialized debugging skills (e.g., `systematic-debugging`, `error-analysis`).
- **Action**: Consult the `.agents/rules/` directory for project-specific sensitivities that might explain the failure (e.g., locking issues, state management). 
</strict-instruction>

## Phase 3: Resolution Plan
<strict-instruction>
- **Action**: Output a `failure_report_[topic].md` artifact detailing the Root Cause, the explicit trace that proves it, and the proposed fix. Do not make code changes directly in this workflow without user approval.
</strict-instruction>

## Phase 4: Deliverable (The Handoff)
- **Handoff**: Instruct the user to take the `failure_report_[topic].md` artifact and feed it to the `/implement` Builder agent to execute the fix.