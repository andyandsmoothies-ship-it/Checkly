---
name: Antigravity Orchestration Standards
description: Team orchestration, role integrity, and artifact management standards.
trigger: always_on
---

# Antigravity Orchestration Standards

## Mandatory Integrity Audit & Context Attribution
Before ANY technical implementation, research, or audit, you MUST perform a mental (or explicit) audit. Every response involving code changes or architectural analysis SHOULD include a brief checklist and attribution block at the start or end of your message:
- **Skills Checked**: [List paths to SKILL.md files viewed]
- **Rules Compliance**: [Confirm coding patterns follow project governance and orchestration rules]
- **Context Inventory**: [Explicitly list all `.md` rule files, MCP schemas, or documentation URLs you referenced to produce this response/artifact]

## Pre-Flight Check (CANONICAL)
<pre-flight-check>
Before ANY workflow response that involves analysis, design, or implementation:
- [ ] Is this more than a 2-minute task? → Create `task_boundary`
- [ ] Does the answer have >5 paragraphs or require design? → Create an artifact
- [ ] **Skill Inventory**: Match the task to modular skills in `.agent/skills/`.
- [ ] **Rules Conflict**: Confirm no existing logic in `project-governance.md`, `csharp-standards.md`, or `plugin-development.md` conflicts.
- [ ] **Layer Check**: Identify target layer (Shell / Shared / Tool RCL) before planning.
- [ ] **Tool-Specific Rules**: If modifying a specific tool, also check that tool's rules (e.g., `email-standards.md` for VoucherSender).
</pre-flight-check>

## Skill Inventory Protocol (STRICT)
Before ANY technical implementation or research:
1. **Discovery**: Match the task to available skills in `.agent/skills/` (e.g., `clean_coder`, `systematic-debugging`).
2. **Invocation**: For project-specific business logic (C#, Excel, Email), refer to the Rules in `.agent/rules/`. For cross-project behaviors, refer to the Skills in `.agent/skills/`.
3. **Task-Based Application**: Apply the patterns defined in the relevant Rule or Skill for the current task.

## Artifact Protocol
<artifact-protocol>
- **Absolute Paths**: References to artifacts MUST use the full `file:///` URI.
- **Requirement Summary**: Every artifact MUST start with a `# Requirement Summary` section.
- **Context Inventory**: Every artifact MUST include a `# Context & References` section immediately after the summary, explicitly listing the `.agents/rules/` files, docs, or MCPs used to generate the artifact.
- **Single Source of Truth**: Artifacts reside ONLY in the agent's `brain/` folder.

### Artifact Naming Convention (CANONICAL)
> [!IMPORTANT]
> This is the **single source of truth** for artifact naming. Do NOT define naming patterns in workflow files.

| Category | Pattern | Example |
|----------|---------|---------|
| Analysis | `analysis_[topic].md` | `analysis_smtp_failure.md` |
| Implementation Plan | `implementation_plan_[feature].md` | `implementation_plan_batch_mode.md` |
| Concept Brief | `concept_brief_[feature].md` | `concept_brief_voucher_sender.md` |
| Failure Report | `failure_report_[topic].md` | `failure_report_email_timeout.md` |

### Artifact Tracking (MANDATORY)
Every `task.md` MUST include an `# Artifact Inventory` section listing all artifacts:
- **[NEW]** = Created in this task
- **[MOD]** = Modified in this task
- **[DEL]** = Deleted in this task

### Diagnostic & Temporary Files (STRICT)
Agents MUST NOT dump test logs, build outputs, or scratchpad files (`build.txt`, `test.txt`, `Fix.cs`, `.patch`) into the root directory of the project.
- **Rule**: All temporary diagnostic files MUST be written to `.agents/tmp/`.
- **Cleanup**: If you create a temporary file in the root directory by accident, you MUST delete it using `Remove-Item` before handing the task back to the user.
</artifact-protocol>

## Self-Maintenance & Governance

### Post-Task Reflection & Self-Curation (ALWAYS-ON)
After completing any significant implementation, debug, or refactor, assess whether a new LESSON, GOTCHA, or PATTERN was discovered that must be preserved. 

1. **Target File**: Update `.agent/rules/project-gotchas.md`. Do NOT use `AGENTS.md`.
2. **Curation Rules (Preventing Bloat)**:
   - **DO ADD**: Highly specific, project-breaking quirks (e.g., "MudBlazor layout rendermode crashes", "JS Interop kills SignalR circuit").
   - **DO ADD**: Architectural decisions that deviate from standard tutorials (e.g., "Use global Routes rendermode, not per-page").
   - **DO ADD**: Undocumented library bugs or workarounds specific to this stack.
   - **DO NOT ADD**: Generic C# or Blazor knowledge (e.g., "How to use a standard for loop", "What DI is").
   - **DO NOT ADD**: One-off typos or syntax errors that the compiler caught.
   - **DO NOT ADD**: Features or business logic that are already documented in `platform-rules.md` or other specific rule files.
3. **Self-Prune**: Before finishing, you MUST review the rest of `.agent/rules/project-gotchas.md`. Automatically consolidate duplicates, delete outdated/contradictory rules, and keep the file lean and highly dense with value.