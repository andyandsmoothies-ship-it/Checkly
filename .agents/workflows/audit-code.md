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
- **Action**: Derive 2-3 keywords from the audit scope (e.g., "cleanup", "health", "convention", "refactoring"). Search `.agents/skills/` for matching skills. Load the top 1-2 most relevant.
- **Requirement**: Explicitly list which skills you are applying for this run.

### Phase 2: Code Quality Scan
Hunt for "AI Slop" — code that works but deviates from established invariants.
- **Skill Refresh**: Re-scan `.agents/skills/` for skills matching issue patterns you're finding. Load 1-2 if relevant.
1. **Dead Code & Unused Assets**: Scan for files, functions, or dependencies that are imported but never used.
2. **Architectural Drift**: Verify layer boundaries have not been violated (e.g., a page importing from a service layer directly, circular dependencies).
3. **Stale Documentation**: Compare workspace docs against the actual codebase. Flag anything outdated or misleading.
4. **Format & Convention Compliance**: Check for naming convention deviations, missing patterns required by project rules.

### Phase 3: Structural Health
Scan for file-level code smells that indicate a need for decomposition.
1. **File Size**: Flag files over 500 lines (🟡 Warning). Flag files over 1000 lines (🔴 Critical — mandatory decomposition).
2. **Class Density**: Flag files containing more than 3 class/widget/component definitions (🟡 Warning — likely SRP violation).
3. **Private-Only Components**: Flag files where all components are private/unexported — they cannot be unit tested in isolation.
4. **Method Size**: Flag individual methods/functions over 150 lines (🔴 Critical — too complex to reason about).
5. **Recommendation**: For each flagged file, propose a decomposition plan following project structure conventions.

### Phase 4: Coverage & Hygiene
1. **Test Coverage Gaps**: Identify features, pages, or modules with zero or minimal test files. Flag any test file that only contains compile-gate tests (no behavioral assertions).
2. **Dependency Freshness**: Check package manifests (`pubspec.yaml`, `*.csproj`, `package.json`) for outdated or unused dependencies.
3. **TODO/FIXME/HACK Audit**: Search for stale markers. Flag any older than 30 days or with no owner/issue reference.
4. **Duplication Detection**: Identify copy-pasted logic across files (e.g., identical validation functions, repeated API calls). Flag for extraction into shared utilities.

### Phase 5: The Sentinel Assessment
Synthesize findings into a structured audit report.
- **No issues** → generate `audit_code_pass_[date].md`
- **Issues found** → categorize by severity:

| Severity | Definition | Example |
|----------|-----------|---------|
| 🔴 Critical | Breaks build, runtime errors, or untestable monolith | Missing import, 2400-line file, method > 150 lines |
| 🟡 Warning | Works but violates conventions or maintainability | Wrong naming, no tests, stale TODO, 3+ classes in one file |
| 🟢 Optimization | Cosmetic improvement | Dead code, redundant comment, outdated dependency |

- **Requirement**: For every issue, provide the specific fix command or code snippet.

### Phase 6: Deliverable
- Output `audit_code_report_[date].md` artifact into the agent's `brain/` folder.
- **Handoff**: Route all issues to `/implement` (code quality fixes are always Track B — mechanical).
