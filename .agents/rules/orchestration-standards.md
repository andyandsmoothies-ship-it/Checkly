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
- **Deterministic Naming**: Files MUST use the format `[type]_[YYYYMMDD_HHMMSS].md` (e.g., `task_20260530_144500.md` or `3_task_...`). Do NOT include `ConversationID` in the filename.
- **Metadata Preservation**: The `ConversationID` (e.g., `c3563378-9cd7-4609-ae6d-2aba9f71c9ff`) MUST be stored in the **YAML Frontmatter** of the file to keep filenames clean.
- **No Scripts**: The AI is strictly PROHIBITED from moving or renaming files via PowerShell/Python scripts (e.g., `organize_docs.ps1`). Write files directly to their permanent path.
## 2. Output Formatting
- **ASCII-First**: Markdown artifacts must start with a simple text diagram (e.g., `[UI] -> [API]`). Think inside `<latent_space_scratchpad>` first, then draw. No Mermaid/C4 unless requested.
- **Absolute Paths**: Always output absolute paths (`C:\Users\...`) in handoff logs to prevent user path confusion.
- **Context Portability**: Artifacts must self-contain all constraints and gotchas needed for the next agent.
## 3. Testing Workflows: ATDD vs TDD
- **Anti-Bias Law**: PROHIBITED: Writing both tests and implementation code in the same session. QA writes the failing test (Outer Loop), Builder writes code to pass it (Inner Loop).
- **ATDD (Acceptance/Integration)**: Business Features/APIs. Run *before* technical design. Tests *WHAT* system does (API, serialization, e2e flows).
- **TDD (Unit)**: Internal Logic/Math. Run *after* design, during coding. Tests *HOW* system computes (states, calculations).
- **Universal Application**: When names differ, write contract/integration tests to define requirements first, then unit tests to drive class-level code.
## 4. Workflow Execution & Handoff
- **Pre-Flight**: Load `.agents/skills/`. Run `list_dir` to read local `GEMINI.md` files before starting design.
- **Micro-Slicing**: If modifying >2 files or crossing boundaries, execute ONE slice/file, verify, and YIELD. PROHIBITED: bulk execution in one turn.
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
## 6. Quality Principles (Global)
- **Structure**: Enforce clean boundaries. Fail builds on illegal cross-ring imports.
- **Testing**: Overload tests with edge cases. Use property-based and mutation tests for core math.
- **Small Files**: Keep files small (Max 30 lines per function, Max 400 lines per file). Split components proactively.
- **Decoupled Domains**: Keep modules partitioned. Do not couple features directly.
- **Zero Bloat**: Whitelist external packages. Scan dependencies in audits.