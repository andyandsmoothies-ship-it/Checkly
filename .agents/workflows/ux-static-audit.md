---
description: Automated Static UX Audit for Semantic Tone and Accessibility
---

# The UX Static Audit Workflow

This workflow executes a deterministic, zero-hallucination UX audit on the Flutter UI codebase. It specifically targets Semantic Copywriting (Tone of Voice) and Tap-Depth metrics.

## Pre-Flight Check
1. Ensure `C:\Users\HP\Documents\GitHub\Checkly\.agents\scripts\scrape_strings.py` exists.
2. Load the UX Copywriting skill (`view_file` on `C:\Users\HP\Documents\GitHub\Checkly\.agents\skills\ux-copywriting\SKILL.md`).

## Phase 1: Deterministic Extraction
// turbo
1. Run the extraction script: `python .agents/scripts/scrape_strings.py --dir lib/features --out .agents/tmp/ui_strings_export.json` (Run from `C:\Users\HP\Documents\GitHub\Checkly`).
2. Verify the output file `ui_strings_export.json` exists in `.agents/tmp/`.

## Phase 2: AI Semantic Audit
1. Read the output JSON: `view_file` on `.agents/tmp/ui_strings_export.json`.
2. Evaluate the extracted strings against the 3 rules in the `UX Copywriting` skill.
3. Identify instances of Blaming, Developer Jargon, and weak CTAs.

## Phase 3: Reporting
1. Generate an artifact named `ux_copywriting_report.md`.
2. Format the report grouping violations by Dart file, showcasing a clear tabular comparison between the current string and the recommended rewrite.
3. Mark the workflow as complete and present the report to the user.
