# Code Audit Report — `lib/`
**Date:** 2026-05-08T18:37:08+07:00
**ShortID:** `4cf3f41a`
**Role:** Sentinel (Read-Only)
**Scope:** `c:\Users\HP\Documents\GitHub\Checkly\lib\`

---

## Summary Dashboard

| Severity | Count | Status |
|---|---|---|
| 🔴 Critical | 3 | Requires immediate attention |
| 🟡 Warning | 5 | Should be addressed this sprint |
| 🟢 Optimization | 2 | Good-to-have improvements |

---

## 🔴 CRITICAL FINDINGS

---

### CRIT-1: Dead Code — `_isProductionReady` getter (Unreferenced Declaration)

**File:** `lib/features/templates/widgets/wizard_step_review.dart:67`
**Confirmed by:** `dart analyze` → `unused_element`

**What it is:** A boolean getter that checks if the template has ≥3 sections and ≥5 criteria. It was not wired to the UI or the V6 validation pipeline `_v6Errors`. The blocking validation logic runs through `_v6Errors` exclusively.

```dart
// DEAD — never read by any UI or logic path
bool get _isProductionReady =>
    widget.sections.length >= 3 && _totalCriteria >= 5;
```

**Fix:**
```dart
// Delete lines 67–68 entirely.
```

- **Complexity:** Low. One-line deletion. No callers exist anywhere in the file or project.
- **Trade-offs:** None. This is a clean delete with zero risk.

---

### CRIT-2: Async `BuildContext` Gap — `user_create_sheet.dart:171`

**File:** `lib/features/admin/widgets/user_create_sheet.dart:171`
**Confirmed by:** `dart analyze` → `use_build_context_synchronously`

**What it is:** The `_submit()` method `await`s `UserManagementDialogs.confirmTransfer(context, ...)` on line 170. The `context` is read directly after an `await` (the Dio exception catch block). If the widget was unmounted during the API call, reading `context` here crashes the app with a "mounted" error.

```dart
// BUG: context read after await, no mounted check
final confirm = await UserManagementDialogs.confirmTransfer(
  context,  // <-- dangerous
  responseData['existingManagerName'] as String,
);
```

**Fix:**
```dart
if (statusCode == 409 &&
    responseData is Map &&
    responseData['existingManagerName'] != null) {
  if (mounted) setState(() => isSubmitting = false);
  // ✅ Guard context usage with mounted check
  if (!mounted) return;
  final confirm = await UserManagementDialogs.confirmTransfer(
    context,
    responseData['existingManagerName'] as String,
  );
  if (confirm == true) {
    return _submit(forceReassign: true);
  }
  return;
}
```

- **Complexity:** Low. One-line guard `if (!mounted) return;` inserted before `context` is read.
- **Trade-offs:** No behavior change on the happy path. On unmount, the dialog silently cancels instead of crashing — strictly safer.

---

### CRIT-3: Architectural Drift — Widget Importing `AppDatabase` Directly

**File:** `lib/features/dashboard/pages/widgets/action_required_widget.dart:5`

**What it is:** A UI widget imports `app_database.dart` directly to reference the `CachedProgramAssignment` Drift row type. This breaks the `Page → Manager → DAO → Database` layer contract and couples the widget to Drift's generated type.

```
[action_required_widget.dart]  ← widget
      ↓ imports directly
[app_database.dart]            ← DB generated layer ❌
```

**Context note:** The file's comment admits "Reads directly from ProgramOutboxDao.watchPendingAssignments() via a StreamBuilder". The DAO is resolved via `GetIt`, which is acceptable. The problem is the `CachedProgramAssignment` type leaking into the widget layer.

**Fix — Option A (Preferred):** Create a simple view model / DTO inside the feature:
```dart
// lib/features/programs/model/pending_assignment_vm.dart
class PendingAssignmentVm {
  final String id;
  final int count;
  PendingAssignmentVm({required this.id, required this.count});
}
```
Then move the `StreamBuilder` logic into `DashboardManager` or a dedicated `ProgramOutboxWatcher` wrapper that exposes `Stream<PendingAssignmentVm>`.

**Fix — Option B (Minimal):** Re-export `CachedProgramAssignment` from a DAO-level barrel file so widgets never import `app_database.dart` directly.

- **Complexity:** Medium. Option A requires creating a small VM class and updating the widget. Option B is 2 lines but does not solve the coupling — it hides it. Recommend Option A.
- **Trade-offs:** Option A increases testability dramatically (can mock the Stream without needing Drift). Option B is faster but leaves the architectural smell in place.

---

## 🟡 WARNINGS

---

### WARN-1: File Size — `user_create_sheet.dart` Exceeds 400-Line Limit (MANDATORY SPLIT)

**File:** `lib/features/admin/widgets/user_create_sheet.dart` — **441 lines**

This file contains one class (`UserCreateSheet`) but its `build()` method runs from line ~197 to line 440 — a 243-line build method. This is the anti-pattern: logic is embedded inline in the widget tree.

**Proposed Split:**
```
user_create_sheet.dart          ← StatefulWidget shell (~80 lines)
user_create_sheet_logic.dart    ← _submit(), _loadStores(), validation helpers (~160 lines)  
user_create_sheet_body.dart     ← build() widget tree decomposed into named private widgets (~200 lines)
```

- **Complexity:** Medium. State variables need to remain in the StatefulWidget. Logic can extract cleanly. Consider `UserCreateSheetController` mixin.
- **Trade-offs:** Splitting improves testability (can unit-test `_submit` in isolation) at the cost of a refactor pass. The file is already working, so the risk is regression during the split.

---

### WARN-2: File Size — High-Warning Zone (250–400 lines)

28 files breach the 250-line warning threshold. The top 5 most urgent:

| File | Lines | Primary Smell |
|---|---|---|
| `template_builder_page_logic.dart` | 390 | Logic file with no class — all top-level functions/closures |
| `template_wizard_page.dart` | 377 | Single `build()` spanning ~250 lines |
| `admin/pages/widgets/store_form_sheet.dart` | 377 | Deep-nested widget tree inline |
| `admin/widgets/user_edit_sheet.dart` | 375 | Mirror of `user_create_sheet` (see WARN-1) |
| `programs/widgets/program_wizard_steps.dart` | 369 | 5 classes in one file (SRP violation — see WARN-3) |

**Recommended action:** Address `user_edit_sheet.dart` alongside `user_create_sheet.dart` (WARN-1) since they share structural patterns. Schedule `template_wizard_page.dart` separately.

- **Complexity:** Medium per file.
- **Trade-offs:** Each split is a targeted refactor with regression risk. Do one file per sprint. Prioritize by frequency of changes (hottest files break most often).

---

### WARN-3: Class Density — `program_wizard_steps.dart` Has 5 Classes (SRP Violation)

**File:** `lib/features/programs/widgets/program_wizard_steps.dart` — 369 lines, **5 classes**:
`StepInfo`, `StepTemplate`, `StepStores`, `StepReview`, `TemplatePicker`

Each class is a distinct wizard step widget. They should each live in their own file.

**Proposed Split:**
```
program_wizard_steps/
  step_info.dart
  step_template.dart
  step_stores.dart
  step_review.dart
  template_picker.dart
```

- **Complexity:** Low. Pure file extraction — no logic changes.
- **Trade-offs:** Import paths in the parent wizard page will need updating. No behavior change.

---

### WARN-4: Coverage Gap — 12 Manager Classes Have Zero Tests

The following `*_manager.dart` files have no corresponding test file:

| Manager | Risk Level |
|---|---|
| `template_manager.dart` | 🔴 High — orchestrates complex template tree mutations |
| `analytics_manager.dart` | 🔴 High — multi-step aggregation calculations |
| `program_manager.dart` | 🟡 Medium — sync-critical path for program assignments |
| `store_dashboard_manager.dart` | 🟡 Medium — mirrors DashboardManager patterns |
| `admin_user_manager.dart` | 🟡 Medium — write operations on user state |
| `admin_store_manager.dart` | 🟡 Medium — write operations on store state |
| `admin_audit_manager.dart` | 🟢 Low — primarily read/filter operations |
| `admin_area_manager.dart` | 🟢 Low — CRUD wrapper |
| `admin_dashboard_manager.dart` | 🟢 Low — read-only aggregation |
| `admin_global_risk_manager.dart` | 🟢 Low — CRUD wrapper |
| `survey_results_manager.dart` | 🟢 Low — display-only manager |
| `profile_manager.dart` | 🟢 Low — read-only with profile update |

**Recommended action:** Prioritize `template_manager` and `analytics_manager` for TDD in the next sprint via `/tdd`.

---

### WARN-5: `_modeLabel` Uses `switch` with String Literals (Magic Strings in Logic File)

**File:** `lib/features/templates/widgets/wizard_step_review.dart:135`

```dart
String get _modeLabel {
  switch (widget.scoringMode) {
    case 'penalty':      // ← magic string
    case 'accumulation': // ← magic string
    case 'checklist':    // ← magic string
    case 'survey':       // ← magic string
```

The `ScoringMode` enum already exists at `lib/_shared/services/scoring_mode.dart`. The widget layer should use the enum, not repeat the raw strings.

**Fix:**
```dart
// Pass scoringMode as ScoringMode enum instead of String
// Or call ScoringInputMapper.parseScoringMode() at widget level
String get _modeLabel => switch (widget.scoringMode) {
  ScoringMode.penalty      => 'Compliance Audit (Penalty)',
  ScoringMode.accumulation => 'Training Assessment (Accumulation)',
  ScoringMode.checklist    => 'Custom Checklist',
  ScoringMode.survey       => 'Feedback Survey',
};
```

- **Complexity:** Low if `WizardStepReview.scoringMode` type changes from `String` to `ScoringMode`. Medium if callers need updating.
- **Trade-offs:** Breaking change at the constructor call site (template_wizard_page.dart). Delivers type-safety and removes a magic-string duplication risk.

---

## 🟢 OPTIMIZATION SUGGESTIONS

---

### OPT-1: `user_create_sheet.dart` and `user_edit_sheet.dart` Have Duplicated Store-Picker Logic

Both files contain near-identical `_loadStores()` methods and store-picker dropdown/checkbox UI. This is classic WET code.

**Suggestion:** Extract a shared `_StorePicker` widget and a `_loadStores()` utility function into `admin/widgets/shared/store_picker.dart`. Complexity: Medium. Only extract when both files are split (WARN-1 first).

---

### OPT-2: `app_database.g.dart` Is 19,684 Lines (Auto-Generated — Exempt)

This is Drift's generated code. It is exempt from the 400-line rule. No action needed; do not commit to source control if avoidable, but standard Dart/Drift projects include it.

---

## Secrets Scan — CLEAN ✅

All 3 `Bearer` matches are runtime token interpolations:
- `'Bearer $token'` → runtime value from `FlutterSecureStorage`
- `'Bearer $adminToken'` → runtime value from auth flow

No hardcoded credentials, API keys, or `.env` file leakage found.

---

## Stale Markers — CLEAN ✅

Zero `TODO`, `FIXME`, `HACK`, or `XXX` markers found in `lib/`.

---

## Dependencies — CLEAN ✅

`pubspec.yaml` has 18 production dependencies. All appear actively referenced in the codebase. No obviously stale or redundant packages detected.

---

## Strict Implementation Constraints (for the Builder / Forge Agent)

> [!IMPORTANT]
> - Fix CRIT-1 (`_isProductionReady`) FIRST — it is a 1-line delete with zero risk. Run `dart analyze` to confirm zero warnings after.
> - Fix CRIT-2 (`mounted` check) second — insert the guard before the `confirmTransfer` call. Do NOT rewrite the surrounding error handler.
> - CRIT-3 (arch drift) requires a design decision. **YIELD to the user** before implementing. Recommend Option A (DTO/VM wrapper). Do not change the DAO or Manager behavior.
> - WARN-1/WARN-2 file splits are HIGH REGRESSION RISK. Only split one file per prompt cycle. Run `flutter test` between each file.
> - NEVER modify `app_database.g.dart` directly.
> - All test files go in `test/`, not `lib/`.
