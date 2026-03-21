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

## The Context Flushing Rule (Combating Context Decay)
LLMs suffer from context decay; instructions given earlier in long sessions lose their weight. Do not rely on conversational memory for long-running tasks.
- **Action**: Whenever you cross a new `/task_boundary` or shift to a new phase of work, you MUST physically re-read (`view_file`) the canonical `implementation_plan.md` and applicable workspace rules.
- **Purpose**: This refreshes the exact "shape of the container" at the top of your context window, erasing the time-bias decay. Treat `.md` artifacts as the true "Externalized Memory".

## Pre-Flight Check (CANONICAL)
<pre-flight-check>
Before ANY workflow response that involves analysis, design, or implementation:
- [ ] Is this more than a 2-minute task? → Create `task_boundary`
- [ ] Does the answer have >5 paragraphs or require design? → Create an artifact
- [ ] **Skill Inventory**: Match the task to modular skills in `.agents/skills/`.
- [ ] **Rules Conflict**: Confirm no existing logic in `.agents/rules/platform-rules.md` or `.agents/rules/project-gotchas.md` conflicts.
- [ ] **Layer Check**: Identify target layer (Server / Flutter / Shared) before planning.
</pre-flight-check>

## Skill Inventory Protocol (STRICT)
Before ANY technical implementation or research:
1. **Discovery**: Match the task to available skills in `.agents/skills/` (e.g., `clean_coder`, `systematic-debugging`).
2. **Invocation**: For project-specific business logic, refer to the Rules in `.agents/rules/`. For cross-project behaviors, refer to the Skills in `.agents/skills/`.
3. **Task-Based Application**: Apply the patterns defined in the relevant Rule or Skill for the current task.

## The Anti-MacGyver Protocol (STRICT)
Before implementing ANY local utility behavior, routing logic, data transformation, or UI component:
- **Rule**: You MUST execute a `grep_search` within `server/Common/` or `lib/_shared/`.
- **Purpose**: You must prove you are using the project's existing "Stove" (canonical tools) before you are allowed to build a "Lighter" (custom local logic).
- **Prohibition**: Do not write custom date parsers, unauthorized navigation extensions, or ad-hoc security guards. Use what exists.

## The Micro-Verification Mandate
During the implementation phase, do not wait until the entire feature is coded to verify stability.
- **Rule**: You MUST run `dotnet build`, `flutter analyze`, or the relevant test suite after **EVERY single file modification or major logical step**.
- **Purpose**: Catch "myopic" compiler-level decisions and state violations immediately before they pollute the rest of the causal chain.

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

1. **Target File**: Update `.agents/rules/project-gotchas.md`. Do NOT use `AGENTS.md`.
2. **Curation Rules (Preventing Bloat)**:
   - **DO ADD**: Highly specific, project-breaking quirks.
   - **DO ADD**: Architectural decisions that deviate from standard tutorials.
   - **DO ADD**: Undocumented library bugs or workarounds specific to this stack.
   - **DO NOT ADD**: Generic C#, Dart, or Flutter knowledge.
   - **DO NOT ADD**: One-off typos or syntax errors that the compiler caught.
   - **DO NOT ADD**: Features or business logic already documented in `platform-rules.md`.
3. **Self-Prune**: Before finishing, review `.agents/rules/project-gotchas.md`. Consolidate duplicates, delete outdated rules, keep the file lean.