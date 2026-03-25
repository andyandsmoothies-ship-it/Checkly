---
trigger: manual
---

# Artifact Protocol

<artifact-protocol>
- **The "Executive Manager" Strategy (Firehose Mitigation)**: You are highly discouraged from monitoring real-time agent terminal outputs or line-by-line coding. Treat the AI like a direct report: issue the workflow (e.g., `/diagnose`), ignore the execution "firehose," and ONLY review the final Markdown artifact outputted to the `brain/` folder.
- **Thinking Process Separation (Anti-Poisoning Rule)**: Do NOT pollute structural artifacts (like `implementation_plan.md` or `walkthrough_[topic].md`) with the AI's internal monologue, rejected ideas, or "thinking processes." This bloats the context window for downstream agents (e.g., Builder or Sentinel) and causes hallucination. All "thinking" and rationale MUST be written to a dedicated separate file: `thinking_log_[topic].md`. Downstream agents are strictly FORBIDDEN from reading `thinking_log` files.
- **Absolute Paths**: References to artifacts MUST use the full `file:///` URI.
- **Requirement Summary**: Every artifact MUST start with a `# Requirement Summary` section.
- **Context Inventory**: Every artifact MUST include a `# Context & References` section immediately after the summary, explicitly listing the `.agents/rules/` files, docs, or MCPs used to generate the artifact.
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
Agents MUST NOT dump test logs, build outputs, or scratchpad files (`build.txt`, `test.txt`, `Fix.cs`, `.patch`) into the root directory of the project.
- **Rule**: All temporary diagnostic files MUST be written to `.agents/tmp/`.
- **Cleanup**: If you create a temporary file in the root directory by accident, you MUST delete it using `Remove-Item` before handing the task back to the user.
</artifact-protocol>
