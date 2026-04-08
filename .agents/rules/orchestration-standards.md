---
trigger: model_decision
description: Rules for AI agents on how to run workflows, manage context decay, load skills, and perform pre-flight checks.
---

# Orchestration Standards

## Mandatory Integrity Audit & Context Attribution
Before any implementation or analysis, include this checklist in your response:
- **Rules Compliance**: [Confirm project governance adherence]
- **Context Inventory**: [List rules, docs, or MCP schemas referenced]

## Pre-Flight Check (CANONICAL)
Before ANY workflow response involving analysis, design, or implementation:
- [ ] > 1-minute task? → Create `task_boundary`
- [ ] > 2 paragraphs or requires design? → Create artifact
- [ ] **Skill Inventory**: Load modular skills from `.agents/skills/`.
- [ ] **Local Context Discovery**: Run `list_dir` on the target module to find and read any `GEMINI.override.md` files BEFORE designing solutions.
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

## The "Anti-Black-Box" Execution Rule (Transparency Mandate)
**Do not write automated loop scripts (like Python `os.listdir` or PowerShell `foreach`) for mass file manipulation.**
- **Problem**: Giant script loops are "black boxes" that strip the user of granular control.
- **Action**: When generating scripts for bulk actions (moving files, renaming, deleting), you MUST write out actions explicitly, 1-by-1, on individual lines (e.g. 50 distinct `Move-Item` statements).
- **Why**: This guarantees transparency. The user can see exactly what is being modified line-by-line and safely comment out (`#`) any specific exceptions before running the script.

## SDLC Artifact Storage
- **Generate Default**: Always create ALL artifacts in the `brain/` folder first.
- **Copy High-Value**: Explicitly copy ADRs, Test Contracts, and Audits to `docs/` after creation.
- **Discard Transients**: Leave Implementation Plans and tasks in `brain/`. DO NOT copy them to `docs/`.