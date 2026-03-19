---
name: Verification Workflow
description: System Impact Audit for architectural changes.
---

# Workflow: /verify

> [!NOTE]
> This workflow acts as the final gatekeeper before declaring a task finished.

<!-- HUD:START — Delete this block to remove the Live Dashboard from all workflows -->
// turbo
3. **Launch Live Web Dashboard**: Run cmd /c "start /b node .agents\tools\agent-web-hud.js" to launch the background server and open the UI in the browser.
<!-- HUD:END -->
## Phase 1: Context & Side Effect Audit
<strict-instruction>
**Skill Discovery**: Derive 2-3 keywords from the changes being verified. Use `grep_search` on `.agents/skills/` to find any relevant verification, testing, or code-review skills. Load the top 1-2 `SKILL.md` files.
**Action**: Consult `.agents/rules/` to proactively check your recent code changes for unintended side effects (e.g., framework state loss, missing locks, or illegal ghost imports).
**Semi-Formal Reasoning Checklist**: You must explicitly write down what the code modifies, trace the exact execution path of the modified code line-by-line, and prove your conclusion with specific evidence from the local files. Do not skip reading the actual source files and assuming behavior based on names.
</strict-instruction>

## Phase 2: Execution & Output Parsing
<strict-instruction>
**Action**: Stop any running development servers that might block the build. Use the `run_command` tool to execute the project's standard build and test commands (e.g., `npm run build`, `dotnet build`, `make test`).
You MUST wait for the command to finish and explicitly parse the terminal output. If there are ANY red errors or warnings, you must automatically transition to the `/diagnose` workflow. Do not report success if the build fails.
</strict-instruction>

## Phase 3: Final Certification
<strict-instruction>
**Skill Refresh**: The concern has shifted from execution to assessment. Re-scan `.agents/skills/` for any broad code-review, security, or quality-gate skills that weren't loaded in Phase 1. Load 1-2 if relevant.
**Deliverable**: Output a `walkthrough.md` report (or update the existing one) to prove that the system is stable and verified.
</strict-instruction>