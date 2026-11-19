---
trigger: always_on
description: AI Orchestration, Workflow, and Handoff Standards.
---

# Orchestration Standards
## 1. Artifacts & Naming
- **Immutable Artifacts (Read-Only)**: PROHIBITED: Modifying/overwriting existing workflow artifacts (research, task, plan, etc.) created in past sessions. ALWAYS write a new file with fresh timestamp/ID.
- **3-Bucket Taxonomy**: Write files directly to their permanent location in these absolute workspace paths:
  - **Epics**: `docs/epics/[epic_name]/slice_[N]/` (for multi-stage work)
  - **Features**: `docs/features/[feature_name]/` (for standalone features/bugs)
  - **Reports**: `docs/reports/[type]/[topic]/` (for audits, diagnostics, research)
- **Epic Ledger**: For Epics, a mandatory `_epic_ledger.md` must be maintained at `docs/epics/[epic_name]/` serving as the single source of truth for progress, linking to the most recent plans and tasks.
- **Deterministic Naming**: Files MUST use the format `[type]_[topic]_[YYYYMMDD_HHMMSS].md` (e.g., `task_accumulation-weighted_20260530_144500.md` or `task_accumulation-weighted_slice2_20260530_144500.md`). Do NOT include `ConversationID` in the filename.
- **Metadata Preservation**: The `ConversationID` (e.g., `c3563378-9cd7-4609-ae6d-2aba9f71c9ff`) MUST be stored in the **YAML Frontmatter** of the file to keep filenames clean.
- **No Scripts**: The AI is strictly PROHIBITED from moving or renaming files via PowerShell/Python scripts (e.g., `organize_docs.ps1`). Write files directly to their permanent path.
## 2. Output Formatting
- **ASCII-First**: Markdown artifacts must start with a simple text diagram (e.g., `[UI] -> [API]`). Think inside `<latent_space_scratchpad>` first, then draw. No Mermaid/C4 unless requested.
- **Absolute Paths**: Always output absolute paths (`C:\Users\...`) in handoff logs to prevent user path confusion.
- **Context Portability**: Artifacts must self-contain all constraints and gotchas needed for the next agent.
- **Chat Payload Truncation**: Write large outputs (audits, reviews, reports) to files under `docs/reports/` instead of printing in chat. Present only a bulleted executive summary and the path in chat.

## 3. Testing Workflows: ATDD vs TDD
- **Anti-Bias Law**: PROHIBITED: Writing both tests and implementation code in the same session. QA writes the failing test (Outer Loop), Builder writes code to pass it (Inner Loop).
- **ATDD (Acceptance/Integration)**: Business Features/APIs. Run *before* technical design. Tests *WHAT* system does (API, serialization, e2e flows).
- **TDD (Unit)**: Internal Logic/Math. Run *after* design, during coding. Tests *HOW* system computes (states, calculations).
- **Universal Application**: When names differ, write contract/integration tests to define requirements first, then unit tests to drive class-level code.
- **No Existence-Only Tests**: PROHIBITED: Tests asserting only imports/compilation (e.g. `expect(MyClass, isNotNull)`). Every test must verify at least one behavioral output (UI rendering, mock API responses, or state changes).
## 4. Workflow Execution & Handoff
- **Pre-Flight**: Load `.agents/skills/`. Run `list_dir` to read local `GEMINI.md` files before starting design.
- **Context Pruning**: Use JIT loading (`grep_search`/`view_file`). Never dump massive source files into chat prompts.
- **Bypass Protocol**: If skipping a workflow step, document: `> [!NOTE] AI Decision: Skipped [Step] - [Reason]`.
- **Heavy Math Exception**: Complex calculations bypass ATDD directly to `[/tdd]` for isolated unit tests.
- **Handoff Gate**: Before concluding, you MUST: (1) Verify all `task.md` checkboxes are `[x]`, (2) Verify required files exist on disk via `list_dir`.
## 5. Safety & Transparency
- **Zero Trust**: Treat upstream AI plans/code as untrusted. Verify compilation and tests before checking off tasks.
- **No Black-Box Loops**: Do NOT write bulk terminal loops (e.g., `foreach`). Write commands explicitly line-by-line.
- **Visual Verification**: Quote paths `""`. Always verify file operations visually via `list_dir` instead of trusting success exit codes.
- **No Orphaned Assumptions**: If analysis finds a dependency (e.g. DB migration, config change), translate it to explicit file instructions. Do not leave assumptions to the Builder.
- **No Dead Ends**: Interactive elements must be fully wired. PROHIBITED: empty interaction stubs (e.g. `onPressed: () {}`, `href="#"`).
- **Blast Radius Map**: During planning/analysis, you MUST trace imports of proposed changes to list all dependent files and test suites. For Flutter/Dart, you can run the change mapping script `powershell .agents/scripts/test_changed.ps1` to find and run affected tests.
- **Regression Verification**: If a modified file has dependents in the codebase, you MUST execute the corresponding test suites before declaring work done, preventing silent regressions. Verify database and DTO contracts alignment by running the contract checker `python .agents/scripts/verify_sync_contracts.py`.
- **Analysis Trace Recording**: If requested or when performing complex analysis, research, diagnostics, or audits, record the step-by-step trace to `docs/reports/diagnostics/traces/trace_analysis_[YYYYMMDD_HHMMSS].md`. The trace must exactly record all analyzing activities step-by-step from start to end, listing prompts, tools used, folders/files accessed with rationale, and decisions made, keeping it short and concise.
## 6. Quality Principles (Global)
- **Structure**: Enforce clean boundaries. Fail builds on illegal cross-ring imports.
- **Testing**: Overload tests with edge cases. Use property-based and mutation tests for core math.
- **Small Files**: Keep files small (Max 30 lines per function, Max 400 lines per file). Split components proactively.
- **Decoupled Domains**: Keep modules partitioned. Do not couple features directly.
- **Zero Bloat**: Whitelist external packages. Scan dependencies in audits.
- **Model-Agnostic Heuristics**: To ensure high quality from any model: (1) Research the codebase using `grep_search`/`view_file` before suggesting candidates or code changes. (2) Restrict analysis scope to a specific feature/folder instead of the entire project to prevent token overflow. (3) Propose 3 distinct design options (Minimalist, Flexible, Ergonomic) and use a Pugh Matrix to evaluate them before coding.