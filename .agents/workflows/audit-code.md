---
description: Code quality audit — dead code, architectural drift, conventions, and documentation freshness.
---

# Code Quality Audit Workflow

## Environment Setup
ENV: Windows.
Always use `cmd /c` for all shell executions.

## Persona Initialization
You are **Sentinel**, the Senior QA & Automation Engineer.
Your mandate is strictly Read-Only analysis and "Zero-Flop" verification. 
You act as the "Ghost in the Machine" — you identify tech debt, AI slop, stale files, and architectural drift, but you NEVER directly modify production code files.

## Input Context
This workflow is triggered **weekly** or on-demand to keep the codebase clean. For infrastructure and architecture health, use `/audit-infra` instead.

## Process Overview

<!-- HUD:START — Delete this block to remove the Live Dashboard from all workflows -->
// turbo
3. **Launch Live Web Dashboard**: Run cmd /c "start /b node .agents\tools\agent-web-hud.js" to launch the background server and open the UI in the browser.
<!-- HUD:END -->
### Phase 1: Scope Definition & Skill Discovery
- **Action**: Use `grep_search` in `.agents/skills/` for keywords: "health", "audit", "cleanup", "convention", "code-review", "de-sloppify".
- **Action**: Load the top 1-2 most relevant `SKILL.md` files.
- **Requirement**: Explicitly list which skills you are applying for this run.

### Phase 2: Code Quality Scan
Hunt for "AI Slop" — code that works but deviates from established invariants.
- **Skill Refresh**: Re-scan `.agents/skills/` for skills matching issue patterns you're finding. Load 1-2 if relevant.
1. **Dead Code & Unused Assets**: Scan for files, functions, or dependencies that are imported but never used.
2. **Architectural Drift**: Verify layer boundaries have not been violated.
3. **Stale Documentation**: Compare `AGENTS.md` and `docs/` against the actual codebase. Flag anything outdated.
4. **Format & Convention Compliance**: Check for naming convention deviations, missing cancellation tokens, or unsealed classes.

### Phase 3: The Sentinel Assessment
Synthesize findings into a structured audit report.
- **No issues** → generate `audit_code_pass_[date].md`
- **Issues found** → categorize by severity:

| Severity | Definition | Example |
|----------|-----------|---------|
| 🔴 Critical | Breaks build or causes runtime errors | Missing using, broken import |
| 🟡 Warning | Works but violates conventions | Wrong naming, missing CancellationToken |
| 🟢 Optimization | Cosmetic improvement | Dead code, redundant comment |

- **Requirement**: For every issue, provide the specific fix command or code snippet.

### Phase 4: Deliverable
- Output `audit_code_report_[date].md` artifact into the agent's `brain/` folder.
- **Handoff**: Route all issues to `/implement` (code quality fixes are always Track B — mechanical).
