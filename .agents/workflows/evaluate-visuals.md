---
description: Execute a screenshot-based visual and aesthetic audit using AI vision models. Use when evaluating UI components, spacing, proportion, and "taste."
---

# Workflow: /evaluate-visuals

> [!NOTE]
> This workflow evaluates the deployed visual rendering of a screen. It uses screenshot parsing rather than text/code inspection to judge proportion, whitespace harmony, and accessibility rendering.

## Pre-Flight Check
- [ ] Load the `ui-visual-validator` skill (`view_file`).
- [ ] Ensure the target screenshot exists in `.agents/tmp/` or the artifact directory (prompt the user to capture and upload a screenshot if missing).

## Phase 1: Visual Inspection
- [ ] Analyze the provided screenshot strictly applying the rules of `ui-visual-validator`.
- [ ] Scan for WCAG AA contrast failures (mathematically approximate from visual hex values if possible).
- [ ] Identify Tap Target violations (mobile elements that visually appear too small).
- [ ] Identify Aesthetic violations ("AI slop", claustrophobic padding, lack of hierarchy).

## Phase 2: Diagnostic Mapping
- [ ] Cross-reference the visual layout with the codebase (e.g. use `grep_search` to find where the bad widget is built).
- [ ] Formulate a strict remediation plan utilizing the `interaction-design` and `frontend-design` backup skills to generate premium aesthetic replacements.

## Phase 3: Reporting & Red Teaming
- [ ] Generate a markdown artifact `visual_qa_report.md`.
- [ ] For every identified flaw, map it directly back to the exact code file requiring editing.
- [ ] Hand the report back to the user to either approve the design changes or hand off to the Builder.
