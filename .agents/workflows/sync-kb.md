---
name: sync-kb
description: Self-Maintaining Knowledge Base sync. Triggered automatically at the end of implementation workflows, or manually via /sync-kb to detect and resolve documentation drift.
---

# Workflow: /sync-kb

> [!NOTE]
> Detects architectural, database, design, or business rule drift caused by recent code changes. Drafts redline diffs for documentation and waits for human approval before applying. Prevents the Knowledge Base from turning into a bloated, contradictory dumping ground.

## Phase 1: Context Initialization & Detection
- [ ] **Analyze Recent Changes**: Review the `Conversation ID` logs or use `run_command` (e.g., `git status`, `git diff`) to understand exactly what files were modified during the session.
- [ ] **Identify the Truth**: Compare the *original spec/task plan* against the *actual code written*.
- [ ] **Determine Drift Triggers**: Did any of the following occur?
  - New business rule, validation, or edge case added? -> **Zone E** (`docs/features/`, `docs/product/`)
  - Database schema, EF migration, or API shape altered? -> **Zone B** (`docs/project/`, `docs/architecture/`)
  - A new UI component, spacing rule, or visual standard was introduced? -> **Zone F** (`docs/product/design_system.md` or `docs/features/`)
  - A new 3rd-party dependency/package was installed? -> **Zone A** (Whitelist in `GEMINI.md`) and **Zone B** (Architecture docs)
  - A technical gotcha or global rule was bypassed or learned? -> **Zone A** (`GEMINI.md`)
  - An AI workflow or skill instruction proved inefficient? -> **Zone D** (`.agents/skills/`, `.agents/workflows/`)
  - An Epic slice was officially completed? -> **Zone C** (`docs/epics/[epic_name]/_epic_ledger.md`)
- [ ] If NO drift is detected, inform the user that the KB is perfectly synced and exit the workflow.

## Phase 2: Smart Discovery & Targeted Pruning
- [ ] **Grep for Dead Knowledge**: For each detected drift, use the `grep_search` tool with specific domain keywords (e.g., "Shipment", "Password", "Button") in the target Zone directories. Do NOT blindly read files. Locate the exact lines of outdated rules.
- [ ] **Blast Radius Check**: Determine if modifying/deleting a rule in one document contradicts another. (e.g., if changing an architecture rule in `GEMINI.md`, verify if a related ADR in `docs/architecture/` must also be deprecated).
- [ ] **KB Refactoring Check (File Splitting)**: Check the length of the target documentation file. If a file exceeds 300 lines, do not just append to it. The draft must propose splitting the document into smaller, focused files (e.g., splitting `checkout.md` into `checkout_api.md` and `checkout_ui.md`) to maintain AI readability.

## Phase 3: Draft the Redline Artifact
- [ ] **Create Audit File**: Use the `write_to_file` tool to create a new artifact at `docs/reports/kb_sync/sync_[YYYYMMDD_HHMMSS].md`.
- [ ] **Draft Diffs**: Inside the audit file, write the proposed changes using Markdown diff blocks to show explicitly what is being removed and added.
  - `-` (Red): The outdated or dead knowledge to be deleted/pruned.
  - `+` (Green): The new reality or business rule to be added.
- [ ] **Document Rationale**: Include a 1-sentence explanation of *why* the change is needed based on the code execution.

## Phase 4: The Human Gate
- [ ] **Yield to User**: Stop execution. Present the Redline Draft artifact link to the user and explicitly ask: *"Please review the Redline draft. Do you approve the sync?"*
- [ ] **Wait for Approval**. Do NOT proceed to Phase 5 until the user explicitly approves.

## Phase 5: Execution
- [ ] **Apply Changes**: Upon user approval, use the `multi_replace_file_content` or `replace_file_content` tool to apply the exact diffs to the target documentation files.
- [ ] **Completion**: Report that the Knowledge Base is successfully synchronized with reality.
