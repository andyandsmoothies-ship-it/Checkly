---
name: Diagnostic Workflow
description: High-Compliance Diagnostic Workflow for System Errors.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /diagnose

> [!NOTE]
> This workflow enforces systematic root cause analysis. No guessing is allowed.

## Pre-Flight Setup (ANTI-POISONING MANDATE)
> [!IMPORTANT]
> You must internally structure your reasoning before investigating. Do NOT pollute structured artifacts with internal monologue.
> 
> **MANDATORY ARTIFACT**: You MUST create a `task.md` document right now before investigating the codebase, using this exact schema:
> ```
> # Task: [Bug / Error Topic Name]
> Workflow: /diagnose | Track: [A / B1 / B2 / C]
> ## Phases
> - [ ] Phase 1: Symptom Isolation
> - [ ] Phase 2: Skill & Rule Discovery
> - [ ] Phase 3: Resolution Plan
> - [ ] Phase 4: Deliverable Handoff
> ## Artifact Inventory
> | Status | File Path | Type |
> |--------|-----------|------|
> ```
> This guarantees you will correctly satisfy Question 3 in the Final Phase Self-Correction Gate.
> 
> **MANDATORY REASONING PHASES**: You must process these progressively in your context:
> `## 1. Initial Hypothesis`: Brainstorm potential causes (Code, DB, Navigation, etc.) BEFORE reading deep code.
> `## 2. Evidence Gathered`: Document facts, code snippets, `grep` results, and execution traces here.
> `## 3. Root Cause Identified`: Explain the exact *why*, linking the evidence to the failure.
> `## 4. Fix Strategy`: List possible solutions and their tradeoffs before drafting the final failure report.

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

> **@@SCAN** Before proceeding, PAUSE and INTERNALLY evaluate: (1) What is the exact file and line number of the error? (2) What does the execution trace prove? (3) What is your root cause conclusion and its evidence?

## Phase 2: Skill & Rule Discovery
<strict-instruction>
- **Action**: Derive 2-3 keywords from the error symptom (e.g., "first-principles", "ground-truth"). Use `grep_search` in `.agents/skills/` to find any specialized debugging or error-analysis skills matching those keywords. Load the top 1-2 most relevant `SKILL.md` files.
- **Action**: Consult the `.agents/rules/` directory for project-specific sensitivities that might explain the failure (e.g., locking issues, state management). 
</strict-instruction>

> **@@SCAN** Before proposing a fix, PAUSE and INTERNALLY evaluate: (1) Which skills did you load? (2) Do any project rules in `.agents/rules/` explain this failure?

## Phase 3: Resolution Plan
<strict-instruction>
- **Skill Refresh**: If the root cause points to a different domain than the symptom (e.g., symptom was UI but root cause is a database issue), re-scan `.agents/skills/` for skills matching the root cause domain. Load 1-2 if relevant.
- **Action**: Output a `failure_report_[topic].md` artifact detailing the Root Cause, the explicit trace that proves it, and the proposed fix. Do not make code changes directly in this workflow without user approval.
</strict-instruction>

> **@@SCAN** Before handoff, PAUSE and INTERNALLY evaluate: (1) Does the failure report include the explicit execution trace? (2) Is the proposed fix scoped to the root cause only — no drive-by refactoring?

## Phase 4: Deliverable (The Handoff)
- **Handoff**: Instruct the user to take the `failure_report_[topic].md` artifact and feed it to the `/implement` Builder agent to execute the fix.
- **Gotcha Proposal (MANDATORY)**: At the very bottom of the `failure_report`, you MUST add a section titled `### Gotcha Addition Proposal`.
  - If the root cause was a project-specific constraint or a non-obvious learning, append a bullet point to the `GEMINI.override.md` file adjacent to the root cause (e.g., `server/Common/GEMINI.override.md`).
  - If it was just a generic syntax error, simply state: "No new gotcha detected."
  - This guarantees the human can review and approve new rules without you blindly modifying the root architecture file.

> [!CAUTION]
> **Clean Handoff Protocol**: If you are nearing your context limit or hit a blocking error before all phases are complete, do NOT silently stop. Write a `handoff_[topic].md` listing completed phases, remaining phases, and your current hypothesis/evidence state. Then tell the user: *"Context limit reached. Resume from `handoff_[topic].md` in a new session."*

---

## Final Phase: Self-Correction Gate (CRITICAL)
<strict-instruction>
Before concluding this workflow and replying to the user, you MUST self-audit your output. Each item requires a **one-line evidence citation** — not a bare Yes/No:

1. **Thinking Process Check**: Did I isolate my internal reasoning into a separate `thinking_log_[topic].md` artifact? → Cite: `thinking_log` file path created.
2. **Template Check**: Did I include the mandatory `# Requirement Summary` section in every artifact? → Cite: the exact artifact name and its first heading.
3. **Tracking Update**: Did I update `task.md` with an `# Artifact Inventory` listing every generated file as [NEW]/[MOD]/[DEL]? → Cite: the specific task.md entry added.
4. **Integrity Audit**: Did I include the mandatory context/attribution block (skills loaded, rules applied) in my final response? → Cite: the exact skills and rules referenced.
5. **Physical Verification (Anti-Optimistic-Checkboxing)**: Run `list_dir` on the brain/artifact directory right now. Confirm every `[NEW]` file in the `## Artifact Inventory` of `task.md` appears in the listing. → Cite: the directory path checked and the file names confirmed visible.

You are strictly FORBIDDEN from handing off this task to the user until all 5 evidences are produced. If any evidence is missing → use your file tools to correct the artifact immediately, then cite it.
</strict-instruction>