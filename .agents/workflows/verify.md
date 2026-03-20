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
**Deliverable**: Update `walkthrough.md` with proof of stability (terminal logs, test summaries). This is for the human counterpart to see *what* was integrated, not to decide *if* it should be.
</strict-instruction>