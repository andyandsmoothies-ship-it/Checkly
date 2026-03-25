---
name: UX Heuristic Evaluation
description: Structured UX heuristic evaluation based on Nielsen Norman Group methodology.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /ux-heuristic-eval

> [!NOTE]
> This is the **UX Heuristic Evaluation** workflow — a systematic review of UI screens against Jakob Nielsen's 10 Usability Heuristics to find usability and experience problems.
> Based on the [NN/G guide](https://www.nngroup.com/articles/how-to-conduct-a-heuristic-evaluation/).


## Phase 1: Preparation
- **Instruction**: Assume the role of a Senior UX Evaluator.
- **Skill**: Load the `ux-heuristic-evaluation` skill (`.agents/skills/ux-heuristic-evaluation/SKILL.md`). This is the primary reference for the 10 heuristics, severity scale, and evaluation protocol.
- **Set the Scope**: Ask the user (or determine from context):
  - Which screens, pages, or task flows to evaluate
  - Which user group (e.g., admin, field auditor, viewer)
  - Which device type (mobile, desktop, tablet)

> **@@SCAN** Before reading source code, answer: (1) What screens/flows are in scope? (2) Which user group and device type? (3) Did you load the ux-heuristic-evaluation skill?

## Phase 2: Source Code Walkthrough
- **Instruction**: Before the heuristic pass, read the target page's source code to build a complete mental model of the page's behavior — what the user sees, what they can do, what feedback they receive, and what happens at every edge (loading, empty, error, offline). This mental model replaces the need for a screenshot and catches structural issues that visual inspection alone cannot reveal.
- **Action**: Use `view_file` on the target page's source code. Trace widget trees, callbacks, and navigation flows.

> **@@SCAN** Before heuristic evaluation, answer: (1) What is the page's complete behavior model (loading, empty, error, offline states)? (2) What user actions are available and what feedback do they trigger?

## Phase 3: Evaluate
- **Instruction**: Follow the skill's **Evaluation Protocol** (Double Pass Pattern). Walk through the scoped task flow as the target user, then evaluate against all 10 heuristics on the second pass.
- **Documentation**: Use the skill's **Deliverable Format** for each violation found.

> [!IMPORTANT]
> A design choice violating a heuristic does NOT automatically mean it needs fixing — context matters. Note justified tradeoffs as exceptions, not issues.

> **@@SCAN** Before consolidating findings, answer: (1) Did you complete the Double Pass Pattern? (2) How many violations were found per severity level? (3) Were any justified tradeoffs documented?

## Phase 4: Consolidate & Deliver
- **Action**: Group similar issues, remove duplicates, and prioritize by severity.
- **Deliverable**: Create a `ux_heuristic_eval_[scope].md` artifact with:
  1. **Evaluation Summary**: Scope, date, device, user group
  2. **Findings**: All issues sorted by severity (highest first), using the skill's format
  3. **Heuristic Scorecard**: Per-heuristic summary (✅ Good / ⚠️ Issues found / ❌ Critical violations)
  4. **Top 3 Priority Fixes**: The most impactful issues to address first
  5. **Exceptions & Tradeoffs**: Documented justified violations
- **Handoff**: If fixes are needed, recommend the user route them through `/analysis` → `/implement` → `/verify`.
