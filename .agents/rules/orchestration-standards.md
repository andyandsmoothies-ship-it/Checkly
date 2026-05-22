---
trigger: model_decision
description: AI Orchestration, Workflow, and Handoff Standards.
---

# Orchestration Standards

## 1. Artifacts & Naming
- **Immutable Artifacts (Read-Only)**: NEVER update, overwrite, or append to an existing workflow artifact (research, task, analysis, audit, etc.) created by a previous agent or workflow. ALWAYS create a BRAND NEW file with a fresh timestamp and ID. Treat all past artifacts as strictly read-only historical context.
- **[ShortID]**: Use the first 8 chars of session ID (or random 8-char hex).
- **Topic Folders**: Group artifacts by Epic/Issue ID (e.g., `F-123_auth`). Extract and reuse this folder name for all downstream agents.
- **Dynamic File Naming**: Prevent collisions using `[type]_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` (e.g., `task_...`, `walkthrough_...`, `implementation_plan_...`).
- **Enterprise Storage**: NEVER save artifacts to `brain/`. Output to absolute paths via `write_to_file`:
  - `.agents/active_tasks/[topic]/` (Tasks, walkthroughs)
  - `docs/architecture/[topic]/` (Plans, analysis)
  - `docs/product/` (Requirements, research)
  - `docs/qa/[contracts|gates]/[topic]/` (Test specs, verification)
  - `docs/diagnostics/[topic]/` (Audits)

## 2. Output Formatting
- **ASCII-First**: Human-readable markdown artifacts MUST begin with a simple ASCII diagram (e.g., `[UI] -> [API]`). Execute analysis inside `<latent_space_scratchpad>` first, then output the diagram. NO Mermaid/C4 unless explicitly requested.
- **Absolute Paths**: Output absolute paths (`C:\Users\...`) in chat handoffs for easy user copy-pasting.
- **Context Portability**: Artifacts must embed constraints/gotchas for the next agent. Do not rely on chat history.

## 3. Testing Workflows: When to use ATDD vs TDD
- **ATDD (Acceptance/Integration)**: Use for **Business Features & API Contracts**. Run this *before* technical architecture. Tests *WHAT* the system does (e.g., API boundaries, JSON serialization, end-to-end workflows).
- **TDD (Unit)**: Use for **Algorithmic Logic & Internal Classes**. Run this *after* technical design, during implementation. Tests *HOW* the system computes (e.g., internal state, data formatting, complex math).
- **Universal Application**: If your project doesn't use these exact workflow names, follow the principle: Write contract/integration tests to define requirements, and write unit tests to drive class-level implementation.

## 4. Workflow Execution & Handoff
- **Pre-Flight**: Load `.agents/skills/`. Run `list_dir` to read local `GEMINI.md` files before designing.
- **Micro-Slicing**: If modifying >2 files or crossing boundaries, execute ONE file/boundary, verify, and YIELD to user. Do not bulk-execute in one prompt cycle.
- **Context Pruning**: Use JIT loading (`grep_search`/`view_file`). Never dump massive raw code into prompts.
- **Bypass Protocol**: If skipping a workflow phase, append: `> [!NOTE] AI Decision: Skipped [Phase] - [Reason]`.
- **Heavy Math Exception**: Complex permutational algorithms bypass ATDD directly to `[/tdd]` for isolated unit tests.
- **Handoff Gate**: Before terminating any session, you MUST:
  1. Verify ALL checkboxes in `task.md` are `[x]`.
  2. Prove required output artifacts exist on disk via `list_dir`.

## 5. Safety & Transparency
- **Zero Trust**: Treat upstream AI plans/code as untrusted. Verify before executing.
- **No Black-Box Scripts**: Do NOT write bulk terminal loops (e.g., `foreach`). Write out actions explicitly line-by-line so humans can review/comment out exceptions.
- **Terminal File System**: Pre-create target directories. Quote paths `""`. Always verify file operations visually via `list_dir` rather than trusting exit codes.
- **No Orphaned Assumptions**: If an analysis or research phase identifies a system dependency (e.g., missing security capabilities, DB migrations, or routing updates), it MUST be translated into explicit file-modification instructions before handoff. Builders must reject plans that leave "assumptions" to figure out.
- **No Dead Ends**: Every interactive element designed or built MUST have its downstream consequence fully mapped and implemented. Builders must never leave empty interaction stubs (e.g., `onPressed: () {}`, `href="#"`) and Verifiers must actively scan for and reject them.

## 6. Quality Principles (Global)
- **Structure**: Workflows must enforce clean architectural boundaries. Fail builds when boundaries breach.
- **Testing**: Overload tests with edge cases. Prefer mutation and property-based testing over simple happy paths.
- **Functions**: Break generated code into small, discrete functions (Max 30 lines, Max Complexity 10).
- **Modules**: Keep domains strongly partitioned. Reject "God" modules and tightly coupled designs.
- **Dependencies**: Whitelist third-party packages. Avoid bloat. Automatically scan for vulnerabilities in audits.