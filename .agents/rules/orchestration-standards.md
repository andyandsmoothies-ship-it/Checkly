---
trigger: model_decision
description: Rules for AI agents on how to run workflows, manage context decay, load skills, and perform pre-flight checks.
---

# Orchestration Standards

## Mandatory Integrity Audit & Context Attribution
Before any implementation or analysis, include this checklist in your response:
- **Rules Compliance**: [Confirm project governance adherence]
- **Context Inventory**: [List rules, docs, or MCP schemas referenced]

## Artifact Naming Conventions & Terminology
- **`[ShortID]`**: An 8-character unique identifier for the current session. Because you may run inside different IDEs or CLIs (e.g., Cursor, Claude Code, Antigravity), determine it as follows:
  - If your environment provides a UUID or long Conversation/Session ID, use the **first 8 characters** (e.g., `2c7e5b91`).
  - If your environment provides a short ID, just use that.
  - If your environment provides NO session ID, generate a random 8-character alphanumeric string (e.g., `a8b2f9x1`) and use it consistently for the duration of the task.
  - Do not include parentheses or explanations in the actual filename.

## Zero Trust AI Governance (The "Untrusted Actor" Mandate)
**AI agents (including yourself) are treated as untrusted actors.**
- **Rule**: Never implicitly trust that an upstream AI's plan or code is secure, optimized, or correct.
- **Action**: Apply "Never Trust, Always Verify" to all AI outputs. Mandate Human-in-the-Loop (HITL) approval for architectural or security-boundary changes.

## Pre-Flight Check (CANONICAL)
Before ANY workflow response involving analysis, design, or implementation:
- [ ] > 1-minute task? → Create `task_boundary`
- [ ] > 2 paragraphs or requires design? → Create artifact
- [ ] **Skill Inventory**: Load modular skills from `.agents/skills/`.
- [ ] **Local Context Discovery**: Run `list_dir` on the target module to find and read any `GEMINI.md` files BEFORE designing solutions.
- [ ] **Proactive QA Triggers**: When discussing feature completion, proactively remind the user if they should run `[/ux-static-audit]` (for frontend text/UI changes) or hostile testing via the `red_team_playbook.md` (for backend/auth changes).

## Skill Inventory Protocol (STRICT)
1. **Discovery**: Match task to `.agents/skills/`.
2. **Invocation**: Business logic = Rules (`.agents/rules/`). General patterns = Skills (`.agents/skills/`).
3. **Application**: Apply patterns explicitly to the current task.

## Git Ownership Rule (NON-NEGOTIABLE)
**AI agents NEVER run `git add`, `git commit`, or `git push`.**
- Upon completion (Phase 5/Handoff) → **STOP. Notify user.**
- Output: "Implementation complete. Commit when ready: `git add -A ; git commit -m '...'`"
- Ignore any legacy "commit" instructions in workflows.

## Universal Handoff Integrity (The Wrap-Up Mandate)
**To prevent abandoned tasks and missing artifacts across ALL workflows:**
- **Rule**: Before terminating any workflow session (e.g., `/implement`, `/analyze-feature`, `/tdd`), you MUST explicitly perform a wrap-up scan.
- **Action**: Answer these two questions internally before generating your final response:
  1. Are ALL checkboxes in the active task tracker marked `[x]`?
  2. Are all required output artifacts (e.g., walkthroughs, test logs, plans) physically written to disk?
- **Enforcement**: You are STRICTLY PROHIBITED from yielding final handoff to the user until both conditions are met.

## The "Anti-Black-Box" Execution Rule (Transparency Mandate)
**Do not write automated loop scripts (like Python `os.listdir` or PowerShell `foreach`) for mass file manipulation.**
- **Problem**: Giant script loops are "black boxes" that strip the user of granular control.
- **Action**: When generating scripts for bulk actions (moving files, renaming, deleting), you MUST write out actions explicitly, 1-by-1, on individual lines (e.g. 50 distinct `Move-Item` statements).
- **Why**: This guarantees transparency. The user can see exactly what is being modified line-by-line and safely comment out (`#`) any specific exceptions before running the script.

## Absolute Path Output Mandate
**Always provide full absolute file paths.**
- **Rule:** In all UI responses and Handoff blocks, output the absolute path (`C:\Users\...`) so the user can instantly copy-paste it to the next agent.

## Cross-Session Context Continuity (Handoff Memory)
**Artifacts must be self-contained memory blocks.**
- **Rule:** Every generated artifact MUST embed a "Strict Implementation Constraints & Human Reminders" section. 
- **Action:** Do not expect the user to manually carry constraints. The artifact itself must carry all chat-log context, micro-decisions, and "Gotchas" to the next agent.

## The "Anti-Attention Collapse" Mandate (Micro-Slicing)
**To protect against context degradation during execution:**
- **Rule:** If a task requires modifying more than 2 files or spans multiple architectural boundaries (e.g., Frontend + Backend), you are STRICTLY PROHIBITED from executing it in a single prompt cycle.
- **Action:** You MUST slice the implementation into Micro-Steps. Execute ONE file or boundary, run the compiler/tests to verify, and explicitly YIELD to the user before starting the next file.

## Context Pruning & The "Pull Context" Mandate
**To cure Context Rot and AI Attention Collapse:**
- **Rule:** Workflows must NEVER "Push" massive raw code into prompts. 
- **Action:** Enforce JIT (Just-In-Time) loading via narrow `view_file` or `grep_search` ONLY at the macro step requiring it.
- **Pruning:** During long loops, actively summarize your state and explicitly state what old context you are dropping from memory to keep the working memory pristine.

## Terminal File System Protocol (STRICT)
When writing or moving files via terminal commands (e.g., `copy`, `move`):
1. **Idempotent Directories**: Pre-create target directories to prevent silent failures (e.g., `if not exist [dir] mkdir [dir]`).
2. **Quote Paths**: Always wrap full source and destination paths in `""`.
3. **Mandatory Verification**: Never trust command exit codes. You MUST execute `dir` or `list_dir` on the destination to mathematically prove the file exists before yielding.

## Workflow Bypassing (TRANSPARENCY MANDATE)
If an AI agent skips or merges a workflow phase (e.g. bypassing `[/tdd]` because `[/atdd]` provided enough coverage):
- **Rule**: No silent skips.
- **Action**: Add an explicit `> [!NOTE]` alert in `task.md` or `implementation_plan.md`.
- **The "Heavy Math" Exception**: You MUST NOT bypass TDD for pure domain logic. If the feature contains complex mathematical, algorithmic, or heavy permutational logic (e.g. scoring calculators, parsing engines, tax logic), you must STOP at Phase 2.5 and run `[/tdd]` to generate isolated, lightning-fast Unit Tests for that specific logic. ATDD integration tests alone are legally insufficient for heavy data permutations.
- **Format**:
  > [!NOTE]
  > **AI Decision:** Skipped Phase X
  > **Why:** [1-2 concise sentences stating exact coverage overlap or rule used. No filler.]

## The Anti-Agreeable Mandate (Pushback Protocol)
**AI is historically too agreeable and will confidently write plausible but wrong code based on a vague spec.**
- **Rule**: You are STRICTLY PROHIBITED from "inventing" business logic or edge-case handling just to please the user if the upstream spec (or prompt) is vague.
- **Action**: If a requirement is ambiguous or contains obvious UX/logic holes, you MUST push back. YIELD immediately, list the vague points, and force the human to clarify the business rule. Do not silently guess making "safe" assumptions. Be the skeptical Senior Developer.

## Executable Spec Supremacy
**An executable specification (Test) is worth a thousand markdown documents.**
- **Rule**: During the `[/implement]` phase, if the narrative markdown plan (`implementation_plan_[topic].md`) ever contradicts the ATDD/TDD test contracts, the **TEST ALWAYS WINS**.
- **Action**: Treat tests as the immutable source of truth. Markdown is intent; passing tests are the law. You must adapt your code to pass the immutable behavioral test, not rewrite the test to match a flawed markdown plan.


## SDLC Folder-Based Tracking (Traceability Mandate)
**To guarantee traceability across multiple workflows (Analyze -> ATDD -> Implement -> Verify), artifacts MUST be grouped by Topic/Issue Folder, NOT by long filenames.**
- **Prefixing**: Topics MUST start with an Issue/Epic ID (e.g., `F-123_auth_fixes`).
- **Context-Passing**: When invoked with an upstream artifact (e.g., `@[/implement] docs/architecture/F-123_auth_fixes/implementation_plan.md`), you MUST extract the parent folder name (`F-123_auth_fixes`) and use it EXACTLY for all output artifacts. Do NOT invent or guess topic names.
- **Folder Structure**: Always use exact filenames inside the topic folder:
  - `.agents/active_tasks/[topic]/task.md`
  - `.agents/active_tasks/[topic]/walkthrough.md`
  - `docs/architecture/[topic]/implementation_plan.md`
  - `docs/qa/contracts/[topic]/test_contracts.md`
  - `docs/qa/gates/[topic]/executed_tests.md`
  - `docs/diagnostics/[topic]/audit_report.md`

## Enterprise Artifact Storage Mandate
**To prevent artifact bloat in the AI session memory, generated files MUST be saved into the project's permanent repository structure.**
- **Rule**: Do not save generated markdown reports or plans in the default `brain/` directory. Use the designated project folders below.
- **Action**: Always use `write_to_file` to output to the absolute path of these locations:
  - `docs/architecture/[topic]/` : implementation_plan.md, etc.
  - `docs/product/` : Requirements, process models, research notes.
  - `docs/diagnostics/` : Audit reports (`audit_*_report.md`), incident/failure reports (`failure_report_*.md`).
  - `docs/qa/contracts/[topic]/` : test_contracts.md
  - `docs/qa/gates/[topic]/` : executed_tests.md
  - `.agents/active_tasks/[topic]/` : task.md, walkthrough.md

<mandatory_constraints>
- NEVER execute `git` commands. Yield to the user.
- TESTS ALWAYS WIN over Markdown plans.
</mandatory_constraints>