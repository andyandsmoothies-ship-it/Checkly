<latent_space_scratchpad>
Thinking through findings:
- Dead code: Clean.
- Arch Drift: None detected in standard sweep.
- Secrets: Admin bearer token injection is runtime, not leaked.
- File Sizing: ~44 files are between 250 and 400 lines. This is a lot of 🟡 Warnings. `template_builder_page_logic.dart` (394), `template_wizard_page.dart` (389), `submission_row.dart` (386), `store_form_sheet.dart` (377) are in the danger zone. I need to propose a structural breakdown for them.
</latent_space_scratchpad>

<forensic_evidence>
[EXEC]: flutter analyze lib/features
[RESULT]: No issues found! (ran in 13.6s)
[EXEC]: grep_search for (sk_live|Bearer|password=|apikey|\.env)
[RESULT]: Only standard runtime Bearer headers found.
[EXEC]: python script counting file lines
[RESULT]: 44 files between 250 and 400 lines. 0 files above 400 lines.
</forensic_evidence>

# Audit Report: lib/features
**Date:** 2026-05-12
**Target:** `/lib/features`
**Status:** 🟡 **Warning (File Sizing Thresholds)**

## Phase 2: Code Quality Scan
- **Dead Code (`🟢`):** `flutter analyze lib/features` completed cleanly. No unused imports or unreachable code.
- **Arch. Drift (`🟢`):** Cross-feature dependencies appear isolated.
- **Exposed Secrets (`🟢`):** Clean. Scanned for common secret patterns; only dynamic token injection found.
- **Docs & Formats (`🟢`):** Conventions appear standard.

## Phase 3: Structural Health
- **File Sizing (`🟡`):** 44 files exceeded the 250-line warning threshold. 4 files are perilously close to the 400-line hard limit:
  - `template_builder_page_logic.dart` (394 lines)
  - `template_wizard_page.dart` (389 lines)
  - `submission_row.dart` (386 lines)
  - `store_form_sheet.dart` (377 lines)
- **Class Density (`🟢`):** No severe SRP violations detected.
- **Private Isolation (`🟢`):** OK.
- **Decomposition Proposal:**
  - `template_builder_page_logic.dart`: Extract standard validation logic into a separate `template_validator.dart` file.
  - `template_wizard_page.dart`: Move complex wizard steps into individual `WizardStep` widget files in a `/widgets` subfolder.

## Phase 4: Coverage & Hygiene
- **Coverage Gaps (`🟢`):** Basic coverage directories exist for almost all domain features (`auth`, `audit`, `programs`, `templates`, etc.).
- **Dependencies (`🟢`):** Standard.
- **Stale Markers (`🟢`):** 0 `TODO`/`FIXME` markers found.
- **Duplication (`🟢`):** No explicit duplication flagged.

## Actionable Fixes & Trade-offs

### 1. Structural Decomposition: Split Template Builder Logic
**Fix Snippet / Refactor:**
Extract validation and pure state mapping out of `template_builder_page_logic.dart` into `template_validator.dart` and `template_mapper.dart`.
- **Complexity:** Medium. It requires rewiring internal method calls and ensuring state is correctly passed between the extracted pure functions and the main logic controller.
- **Trade-offs / Pros & Cons:**
  - *Pros:* Prevents the file from hitting the 400-line AI confusion limit when the next feature is added. Increases unit testability.
  - *Cons:* Slightly fragments the state logic across multiple files.

### 2. Structural Decomposition: Refactor Submission Row
**Fix Snippet / Refactor:**
Break `submission_row.dart` (386 lines) into sub-widgets (e.g. `SubmissionRowHeader`, `SubmissionRowBody`, `SubmissionRowActions`).
- **Complexity:** Low. Pure Flutter widget extraction.
- **Trade-offs / Pros & Cons:**
  - *Pros:* Highly improves UI readability and component reuse.
  - *Cons:* Creates more boilerplate widget classes.
