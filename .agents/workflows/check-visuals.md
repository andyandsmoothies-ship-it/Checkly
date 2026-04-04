---
description: Execute a screenshot-based visual and aesthetic audit using AI vision models. Use when evaluating UI components, spacing, proportion, and "taste."
---

# Workflow: /evaluate-visuals

> [!NOTE]
> This workflow evaluates the deployed visual rendering of a screen. It uses screenshot parsing rather than text/code inspection to judge proportion, whitespace harmony, and accessibility rendering.

## Phase 1: Discovery & Auto-Chunking
- [ ] Ask the user: *"Which module or router map are we checking today?"* If they don't know, ask for the main `router.dart` file.
- [ ] Analyze the routing map and divide the application into logical "Chunks" (e.g., (1) Login Flow, (2) Admin Flow).
- [ ] Present the Chunks to the user. Say: *"Let's start with Chunk 1. Please paste the screenshots for Chunk 1 into the chat."* Do NOT proceed until the screenshots are provided.
- [ ] Load the `ui-visual-validator` skill (`view_file`).

## Phase 2: Visual Inspection
- [ ] Analyze the provided screenshot strictly applying the rules of `ui-visual-validator`.
- [ ] Scan for WCAG AA contrast failures (mathematically approximate from visual hex values if possible).
- [ ] Identify Tap Target violations (mobile elements that visually appear too small).
- [ ] Identify Aesthetic violations ("AI slop", claustrophobic padding, lack of hierarchy).

## Phase 3: Diagnostic Mapping
- [ ] Cross-reference the visual layout with the codebase (e.g. use `grep_search` to find where the bad widget is built).
- [ ] Formulate a strict remediation plan utilizing the `interaction-design` and `frontend-design` backup skills to generate premium aesthetic replacements.

## Phase 4: Reporting & Red Teaming
- [ ] Generate a markdown artifact `visual_qa_report.md`.
- [ ] For every identified flaw, map it directly back to the exact code file requiring editing.
- [ ] Hand the report back to the user.

## Phase 5: Guided Handoff (MANDATORY)
> [!IMPORTANT]
> After presenting the report, output this block verbatim:

**✅ Chunk [N] visual review done. Next steps:**
1. **Fix** → Send `visual_qa_report.md` to the Builder Agent (`/implement`).
2. **Re-check** → After the fix, hot-reload the emulator, screenshot the same screens, and run `/check-visuals` again.
3. **Next chunk?** → Reply *"yes, continue to Chunk [N+1]"*.
