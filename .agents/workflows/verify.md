---
name: Verification Workflow
description: Verification gate for any upstream workflow — validates that analysis, research, implementation, or audit artifacts are correct, complete, and stable before declaring done.
---

# Workflow: /verify

> [!NOTE]
> This workflow is the **universal verification gate**. It can follow ANY upstream workflow — `/implement`, `/analysis`, `/research`, or `/audit-*`. Its job is to prove that the upstream output is correct, complete, and stable.


## Phase 1: Context & Side Effect Audit
<strict-instruction>
**Skill Discovery**: Derive 2-3 keywords from the changes being verified. Use `grep_search` on `.agents/skills/` to find any relevant verification, testing, or code-review skills. Load the top 1-2 `SKILL.md` files.
**Action**: Consult `.agents/rules/` to proactively check your recent code changes for unintended side effects (e.g., framework state loss, missing locks, or illegal ghost imports).
**Semi-Formal Reasoning Checklist**: You must explicitly write down what the code modifies, trace the exact execution path of the modified code line-by-line, and prove your conclusion with specific evidence from the local files. Do not skip reading the actual source files and assuming behavior based on names.
**First Principles Check**: Before running builds, verify that the *right thing* was produced:
  1. Read the upstream artifact (`implementation_plan.md`, `analysis_[topic].md`, `concept_brief_[topic].md`, or `audit_*_report.md`).
  2. For each acceptance criterion or finding, use `grep_search` / `view_file` to confirm it is addressed in the actual deliverable.
  3. If any criterion is missing or contradicts the codebase → flag as a gap before declaring verification complete.
**Expectation-Driven Development (EDD) Proof**:
  - Locate the "Behavioral Expectations" formulated during the analysis phase.
  - You MUST act as an **Adversarial Reviewer** (Sentinel persona). Do NOT accept "Generative Evidence" (the builder merely claiming it works).
  - You MUST demand **Executed Evidence**: exact terminal logs, API responses, or database query results proving the expectation is met. If the output is missing, you must run the code to verify.
**Non-Testable Accountability (UX & Efficiency)**:
  - DO NOT rely solely on test coverage. 100% coverage represents what executes, not what matters.
  - You MUST evaluate the changes for Big-O complexity, database query inefficiency (N+1), memory leaks, and UX degradation. If the code passes tests but wastes system resources or creates a poor user experience, flag it as a failure.
</strict-instruction>

## Phase 2: CI Gate — Validation & Output Parsing
<strict-instruction>
**Action**: Stop any running development servers. Run the project's standard build and test commands (e.g., `npm run build`, `dotnet build`, `make test`).
**Pass/Fail Protocol**:
- **PASS**: All tests green, zero warnings in build output. Proceed to Phase 3.
- **FAIL**: Any error, test failure, or structural warning. **Action**: You MUST automatically transition to the `/diagnose` workflow. Do not ask for permission. Treat the failure as a regression to be fixed before retry.
</strict-instruction>

## Phase 3: Continuous Verification (Knowledge Sharing)
<strict-instruction>
**Action**: If the build is green, treat this phase as a "Show" (Show and Tell) for knowledge sharing rather than a blocking gate.
**Skill Refresh**: Re-scan `.agents/skills/` for any broad code-review or security skills to ensure no long-term debt was introduced.
**Deliverable**: Create `walkthrough_[topic]_[date-time].md` containing the EDD **Executed Evidence**. Provide the exact terminal logs, test summaries, and screenshots representing concrete scenarios (e.g., Scenario 1, Scenario 2) that prove the EDD Expectations were successfully met. Avoid generative narratives. Use a unique name per verification to preserve history. This is for the human counterpart to see *what* was verified, not to decide *if* it should be.
</strict-instruction>