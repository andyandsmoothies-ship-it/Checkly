---
description: Execute a deterministic Python sweep on the Flutter UI codebase to flag hardcoded colors, missing Semantic tags, and rogue padding values.
---

# Workflow: /audit-design

> [!NOTE]
> This workflow acts as the Bouncer for the Design System. It ensures that developers are not hacking the UI with raw `Colors.xxx` or unscaled typography, enforcing absolute compliance.

## Pre-Flight Check
- [ ] Ensure `C:\Users\HP\Documents\GitHub\Checkly\.agents\scripts\scrape_a11y.py` exists.
- [ ] Load the `frontend-accessibility` skill (`view_file` from `.agents/skills/frontend-accessibility/SKILL.md`).

## Phase 1: Discovery & Auto-Chunking
- [ ] Ask the user: *"Which module or router map are we checking today?"* If they don't know, ask for the main `router.dart` file.
- [ ] Analyze the routing map and divide the application into logical "Chunks" (e.g., (1) Login Flow, (2) Admin Flow).
- [ ] Present the Chunks to the user and ask them to confirm starting with Chunk 1. Do NOT proceed until they confirm.

## Phase 2: Deterministic Extraction
// turbo
- [ ] Run the extraction script against the specific Chunk directory: `python .agents/scripts/scrape_a11y.py --dir [CHUNK_DIRECTORY] --out .agents/tmp/a11y_violations.json` (Run from project root).
- [ ] Verify `.agents/tmp/a11y_violations.json` exists.

## Phase 3: Remediation Mapping
- [ ] Read the output JSON: `view_file` on `.agents/tmp/a11y_violations.json`.
- [ ] Map all violations (e.g., `Colors.red` used instead of `AppTheme.error`) into a prioritized checklist.
- [ ] Correlate with the `frontend-accessibility` rules to define exactly what the correct replacement code should be.

## Phase 4: Reporting
- [ ] Generate an artifact named `a11y_compliance_report.md`.
- [ ] Format the report into a remediation punch list, explicitly stating the file names, line numbers, current bad practice, and the required Design System token replacement.
- [ ] Present this report to the user and mark the workflow complete.
