---
trigger: always_on
description: AI Orchestration, Workflow, and Handoff Standards.
---

# Orchestration Standards
## 1. Artifacts & Naming
- **Immutable Artifacts (Read-Only)**: PROHIBITED: Modifying/overwriting existing workflow artifacts (research, task, plan, etc.) created in past sessions. ALWAYS write a new file with fresh timestamp/ID.
- **[ShortID]**: First 8 chars of session ID or random 8-char hex.
- **Topic Folders**: Group by Epic/Issue ID (e.g., `F-123_auth`). Carry folder name forward across all session boundaries.
- **Dynamic Naming**: Avoid collisions: `[type]_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` (e.g., `task_...`, `walkthrough_...`, `implementation_plan_...`).
- **Enterprise Storage**: PROHIBITED: Saving artifacts to `brain/`. Write to absolute workspace paths:
  - `.agents/active_tasks/[topic]/` (Tasks, walkthroughs)
  - `docs/architecture/[topic]/` (Plans, analysis)
  - `docs/product/` (Requirements, research)
  - `docs/qa/[contracts|gates]/[topic]/` (Test specs, test logs)
  - `docs/diagnostics/[topic]/` (Audits)
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