---
name: Diagnostic Workflow
description: High-Compliance Diagnostic Workflow for System Errors.
---

@[../../../.gemini/GEMINI.md]

# Workflow: /diagnose

> [!NOTE]
> This workflow enforces systematic root cause analysis. No guessing is allowed.

## Pre-Flight Setup (ANTI-POISONING MANDATE)
> [!IMPORTANT]
> You MUST immediately create a `thinking_log_[topic].md` artifact using `write_to_file` BEFORE investigating. All internal reasoning, hypothesis generation, and rejected ideas must go there. Do NOT pollute structured artifacts with internal monologue.

## Phase 1: Symptom Isolation (NO GUESSING)
<strict-instruction>
You MUST NOT guess the root cause of an error.
**Action 1 (Execution Context)**: If the user has not provided a stack trace or runtime execution context, you MUST ask for it or use a terminal tool to generate it. You cannot debug by simply staring at static code.
**Action 2 (Targeted Reading)**: Do NOT read entire files. LLMs suffer from top-to-bottom attention bias and will miss bugs in the bottom half of long files. Use the `view_code_item` tool to read specific functions in isolation, or `grep_search` targeted strictly around the stack trace line number.

**Semi-Formal Reasoning Checklist (MANDATORY)**: Before proposing a fix, you must explicitly output:
1. **Explicit Premises**: Write down exactly what the code currently does based ONLY on the actual read file contents.
2. **Execution Trace**: Trace the exact execution path line-by-line using specific file names and line numbers.
3. **Formal Conclusion**: Prove your root cause conclusion with specific evidence from the runtime trace. Do not rely on assumptions or naming conventions.
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