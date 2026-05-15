# Code Audit Report: `lib/features`

**Date**: 2026-05-15
**Target**: `lib/features/`
**Skills Loaded**: `flutter-architecture.md`, `de-sloppify.md`

<latent_space_scratchpad>
Executed read-only analysis using custom Python script to measure file length distributions in lib/features. Checked database direct references using regex across all dart files. The target was to find layering violations (UI accessing DB directly). Evaluated flutter analyze warnings and dead code markers.
</latent_space_scratchpad>

<forensic_evidence>
Executed `flutter analyze lib/features` -> 2 warnings (unrelated to UI layout/dead code, mostly auto-gen code).
Executed `count_lines.py` script -> 45 files > 250 lines, 0 > 400.
Executed `grep_search` for `import.*(_shared/database|drift\.dart).*` -> 51 matches, 1 inside `program_execution_page.dart`.
</forensic_evidence>

## Executive Summary
An on-demand code audit was executed against the Checkly Flutter frontend features directory. The codebase demonstrates high hygiene with zero dead code markers (`TODO`/`FIXME`), zero leaked secrets, and comprehensive test coverage. However, one strict architectural boundary violation and several file sizing warnings were identified.

## Findings

### 1. Architectural Drift (Direct DB Access from UI)
- **File**: `lib/features/programs/pages/program_execution_page.dart`
- **Severity**: 🔴 Critical
- **Details**: The page imports `_shared/database/database_service.dart` directly. In Pragmatic Flutter Architecture (PFA), Pages must only communicate with Managers or Services, never directly with Data Access Objects (DAOs) or the Database context.
- **Complexity**: **Medium**. The underlying queries/commands must be relocated, and the UI must transition to `watch_it` or standard `FutureBuilder` consumption.
- **Proposed Fix Snippet**:
  ```dart
  // 1. Remove from program_execution_page.dart
  // import '../../../_shared/database/database_service.dart';

  // 2. Add to program_manager.dart
  Future<void> completeExecution(String programId) async {
    await _db.programDao.markCompleted(programId);
    notifyListeners();
  }

  // 3. Update UI to call manager
  onPressed: () => _di<ProgramManager>().completeExecution(widget.programId),
  ```
- **Trade-offs / Pros & Cons**:
  - **Pros**: Strictly enforces the separation of concerns. Makes `ProgramExecutionPage` unit-testable using a `MockProgramManager` instead of requiring a full SQLite in-memory database.
  - **Cons**: Adds a small layer of indirection for what might currently be a simple one-line database write.

### 2. Structural Health (File Sizing Thresholds)
- **Files**: 45 files detected over the `> 250 lines` Warning threshold. (0 files crossed the `> 400 lines` Critical threshold). Notable warnings include:
  - `template_builder_page_logic.dart` (394 lines)
  - `submission_row.dart` (393 lines)
  - `template_wizard_page.dart` (389 lines)
  - `store_form_sheet.dart` (377 lines)
- **Severity**: 🟡 Warning
- **Details**: While none of these files trigger a mandatory split, approaching 400 lines indicates a deterioration of the Single Responsibility Principle (SRP) and increases cognitive load.
- **Complexity**: **Medium**. Requires logically slicing large widgets into smaller, private structural widgets, or extracting business logic into Manager classes/Mixins.
- **Proposed Fix Snippet**:
  ```bash
  # Example decomposition strategy for large UI files:
  mkdir lib/features/dashboard/pages/widgets/submission_row_parts/
  touch lib/features/dashboard/pages/widgets/submission_row_parts/action_menu.dart
  touch lib/features/dashboard/pages/widgets/submission_row_parts/status_badge.dart
  ```
- **Trade-offs / Pros & Cons**:
  - **Pros**: Significantly improves readability. Prevents Git merge conflicts in highly trafficked files. Encourages widget reusability.
  - **Cons**: Increases the sheer number of files in the project. Developers must navigate a slightly deeper folder tree to find specific rendering code.

### 3. Coverage & Hygiene (Stale Markers / Dead Code)
- **Severity**: 🟢 Optimization (Clean)
- **Details**: Zero `TODO` or `FIXME` markers found. Zero `sk_live`, `Bearer`, or `password` secrets leaked.

---

> Pass audit report to Builder agent (@Forge) for /implement (Track B).
