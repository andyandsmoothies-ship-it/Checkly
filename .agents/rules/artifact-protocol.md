---
name: Artifact Protocol
description: Strict rules for generating, formatting, and naming markdown artifacts (.md files), diagnosing logs, and bypassing IDE file locks.
trigger: model_decision
---

# Artifact Protocol

<artifact-protocol>
- **Executive Manager Strategy**: Issue tasks via workflows (e.g., `/diagnose`). Do NOT monitor real-time terminal output. ONLY review the final Markdown artifact in the `brain/` folder.
- **Thinking Process Separation (Anti-Poisoning)**: NEVER pollute structural artifacts (`implementation_plan.md`, `walkthrough.md`) with internal monologue or rejected ideas. Write ALL rationale to a separate `thinking_log_[topic].md`. Downstream agents MUST NOT read `thinking_log` files.
- **Absolute Paths**: Artifact references MUST use the full `file:///` URI.
- **Visibility Rule**: Display explicit clickable markdown links to artifacts in your final response (e.g. `[Walkthrough](file:///...)`). The UI will NOT auto-display them.
- **Requirement Summary**: All artifacts MUST start with a `# Requirement Summary` section.
- **Context Inventory**: All artifacts MUST include a `# Context & References` section listing `.agents/rules/` files, docs, or MCPs used.
- **Single Source of Truth**: Artifacts reside ONLY in the agent's `brain/` folder.

## Artifact Naming Convention (CANONICAL)
> [!IMPORTANT]
> This is the **single source of truth** for artifact naming. Do NOT define naming patterns in workflow files.

| Category | Pattern | Example |
|----------|---------|---------|
| Analysis | `analysis_[topic].md` | `analysis_smtp_failure.md` |
| Implementation Plan | `implementation_plan_[feature].md` | `implementation_plan_batch_mode.md` |
| Concept Brief | `concept_brief_[feature].md` | `concept_brief_voucher_sender.md` |
| Failure Report | `failure_report_[topic].md` | `failure_report_email_timeout.md` |
| Thinking Log | `thinking_log_[topic].md` | `thinking_log_batch_mode.md` |

## Artifact Tracking (MANDATORY)
Every `task.md` MUST include an `# Artifact Inventory` section listing all artifacts:
- **[NEW]** = Created in this task
- **[MOD]** = Modified in this task
- **[DEL]** = Deleted in this task

## Diagnostic & Temporary Files (STRICT)
- **Rule**: NEVER write test logs, builds, or scratchpads (`build.txt`, `Fix.cs`) to the project root. Write them to `.agents/tmp/`.
- **Cleanup**: Delete accidental root files using `Remove-Item` before handoff.

## File Interaction Safety (IDE Bypassing)
> [!WARNING]
> `write_to_file` outside `brain/` triggers IDE previews. For large files in `.agents/tmp/`, this **freezes the IDE**.
- **Safe Write Pattern**: To save a persistent report outside `brain/`:
  1. Write it as an Artifact into `brain/` (`IsArtifact: true`).
  2. Copy it to `.agents/tmp/` using `cmd /c copy`.
  3. NEVER write directly to `.agents/tmp/` using text editing tools.
</artifact-protocol>
