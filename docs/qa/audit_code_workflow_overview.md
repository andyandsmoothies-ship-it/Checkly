# Audit Code Workflow Overview

The `@[/audit-code]` workflow is the primary mechanism for reviewing large batches of files for tech debt, dead code, architectural drift, and structural health. 

Because of the scale of modern codebases, this workflow relies on a **"Script-First Mandate"**. We do not read files line-by-line manually. Instead, we use automated scripts and analyzers to sweep the entire project, and then strategically zoom in on problematic files.

Here is the exact order and list of phases followed during this workflow:

## Phase 1: Scope & Skills
*   **Task Initialization**: Create a formal task tracking markdown file (e.g., `task_[date]_[id]_audit.md`).
*   **Skill Loading**: Load relevant SRE/QA skills (such as `de-sloppify` for cleanup heuristics or `flutter-architecture` for structural boundaries).

## Phase 2: Code Quality Scan
*   **Automated Sweeps**: Execute automated Python scripts (like `.agents/scripts/audit_dead_code.py` if available) and native tools (`rtk flutter analyze`) to scan the codebase.
*   **Primary Vectors**:
    *   **Dead Code**: Unreachable branches, unused functions, or abandoned logic.
    *   **Architectural Drift**: Layer violations (e.g., UI widgets directly calling database services).
    *   **Exposed Secrets**: Hardcoded API keys, bearer tokens, or exposed `.env` data.

## Phase 3: Structural Health
For any files flagged during the Code Quality Scan, we evaluate their structure against strict thresholds:
*   **File Sizing**: Anything over 400 lines receives a 🔴 Critical flag for mandatory splitting.
*   **Method Size**: Methods exceeding 150 lines are flagged for refactoring.
*   **Class Density**: Files containing >3 classes/widgets are flagged for violating the Single Responsibility Principle.

## Phase 4: Coverage & Hygiene
*   **Stale Markers**: Scan files for stale `TODO` or `FIXME` comments (older than 30 days or lacking ownership).
*   **Duplication**: Identify copy-pasted UI or API logic that should be extracted into shared primitives or managers.
*   **Coverage Gaps**: Highlight critical business-logic features that currently lack test coverage.

## Phase 5: Assessment Payload
*   **Report Generation**: Compile all findings into a formal markdown artifact (e.g., `audit_code_report_[date]_[id].md`) inside `docs/diagnostics/`.
*   **Actionable Fixes**: For every identified issue, provide:
    *   The exact fix or refactor command.
    *   A **Complexity** rating (Low, Medium, or High) explaining why it was rated that way.
    *   **Pros & Cons / Trade-offs** to allow the user to make an informed executive decision.

## Phase 6: Deliverable Handoff
*   **Verification Gate**: Execute the python verification script (`verify_workflow.py`) on the task tracker to ensure all checks were completed.
*   **Handoff**: Yield the final report back to the user. **No code is modified during the audit**—all implementation happens in a separate, user-approved cycle.
