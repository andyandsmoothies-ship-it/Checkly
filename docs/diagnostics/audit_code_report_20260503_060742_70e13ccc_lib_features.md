# Code Audit Report — lib/features
**Workflow**: /audit-code | **Role**: Sentinel
**Date**: 2026-05-03T06:07:42+07:00
**ConversationID**: 70e13ccc
**Scope**: `lib/features/` — 12 feature folders, 239 Dart files

---

## Executive Summary

| Metric | Result |
|--------|--------|
| Total files scanned | 239 |
| Critical findings (>400 lines) | 0 |
| Warning findings (>250 lines) | 45 files |
| Arch drift violations | 2 files |
| Hardcoded secrets | ✅ None |
| TODO/FIXME/HACK markers | ✅ Zero |
| Dead code | 1 minor (no-op callback body) |
| Managers/services with zero test coverage | **30 of 43** |

---

## Finding Summary

| ID | Severity | File | Title |
|----|----------|------|-------|
| CF-1 | 🔴 Critical | `dashboard/pages/widgets/action_required_widget.dart` | Widget imports DAO layer directly (Arch Drift) |
| CF-2 | 🔴 Critical | `profile/widgets/sign_out_tile.dart` | Widget imports DAO layer directly (Arch Drift) |
| CF-3 | 🟡 Warning | `admin/pages/schedule_audit_page.dart` (399 lines) | Two public classes in one file (SRP violation) |
| CF-4 | 🟡 Warning | `templates/pages/template_builder_page_logic.dart` (387 lines) | `_validate()` contains a nested closure factory — method too complex |
| CF-5 | 🟡 Warning | Multiple features | 30/43 managers and services have zero behavioral tests |
| CF-6 | 🟢 Optimization | `templates/pages/template_builder_page_logic.dart:311` | Dead no-op `addPostFrameCallback` body |

---

## 🔴 CF-1 — `action_required_widget.dart` imports DAO directly

**File**: `lib/features/dashboard/pages/widgets/action_required_widget.dart` Lines 5–6

### Problem
```dart
import '../../../../_shared/database/app_database.dart';      // DB layer
import '../../../../_shared/database/dao/program_outbox_dao.dart'; // DB layer
```
A dashboard **widget** (UI layer) is bypassing the service layer entirely and calling `ProgramOutboxDao.watchPendingAssignments()` directly. This violates the architecture boundary.

The file even acknowledges this in its own comment:
> "Reads directly from ProgramOutboxDao.watchPendingAssignments() via a StreamBuilder — no DashboardManager involvement."

### Correct Architecture
```
[Widget] → [DashboardManager] → [ProgramOutboxDao]
```

### Fix Option A — Expose the stream through `DashboardManager` (Recommended)
```dart
// In DashboardManager — add:
Stream<List<CachedProgramAssignment>> watchPendingAssignments() =>
    _di<ProgramOutboxDao>().watchPendingAssignments();

// In ActionRequiredWidget — replace:
final dao = GetIt.instance<ProgramOutboxDao>();
// with:
final mgr = GetIt.instance<DashboardManager>();
// stream: mgr.watchPendingAssignments()
```

### Fix Option B — Move to a dedicated `ProgramManager` (Better long-term)
As `programs` has its own `ProgramManager`, expose the stream from there instead of `DashboardManager`.

**Complexity**: Low — one-liner delegation method added to a manager. Widget gets updated to use the manager.

**Trade-offs**:
- ✅ Fixes layer violation — widget never talks to DB
- ✅ Widget becomes testable by mocking the manager
- ✅ Future managers can intercept/transform the stream (e.g., filtering, sorting)
- ⚠️ Option A adds a method to `DashboardManager` that is really a `programs` concern. Option B is cleaner but touches more files.

---

## 🔴 CF-2 — `sign_out_tile.dart` imports DAO directly

**File**: `lib/features/profile/widgets/sign_out_tile.dart` Line 4

### Problem
```dart
import '../../../_shared/database/dao/outbox_dao.dart';  // DB layer
```
The docstring says:
> "Outbox status is fetched via SyncEngine to avoid UI coupling to DAOs."

**But the code directly calls `OutboxDao.syncableCount()` and `exhaustedCount()` — contradicting its own docstring.** This is a broken promise and an arch violation.

Interestingly, the previous session's audit (CS-2) already caught that `main_shell.dart` also does this and proposed moving the delegation to `SyncEngine`.

**Once CS-2 is fixed** (delegation methods on `SyncEngine`), this fix becomes a 3-line swap:
```dart
// Remove import:
import '../../../_shared/database/dao/outbox_dao.dart';

// Replace in _confirmSignOut():
final syncable = await _di<OutboxDao>().syncableCount();    → await _di<SyncEngine>().syncableCount();
final exhausted = await _di<OutboxDao>().exhaustedCount();  → await _di<SyncEngine>().exhaustedCount();
```

**Complexity**: Low — 2-line swap after CS-2 is done. Depends on CS-2 being implemented first.

**Trade-offs**:
- ✅ Docstring and code finally agree
- ✅ UI becomes testable (mock `SyncEngine` instead of mocking `OutboxDao`)
- ✅ Single authority for all outbox-related query routing
- ⚠️ Blocked by CS-2 (from the `_shared` audit)

---

## 🟡 CF-3 — `schedule_audit_page.dart` has 2 public classes in 1 file (SRP)

**File**: `lib/features/admin/pages/schedule_audit_page.dart` (399 lines)

### Problem
The file contains:
1. `ScheduleAuditPage` — a thin scaffold wrapper (25 lines)
2. `ScheduleAuditForm` + `_ScheduleAuditFormState` — the real 374-line form

The form has legitimate reuse — the docstring notes it's used both as a page AND as a bottom sheet. But having 2 public classes in one file violates SRP and pushes the file dangerously close to the 400-line mandatory split threshold.

### Fix
Extract `ScheduleAuditForm` into its own file:
```
admin/
  pages/
    schedule_audit_page.dart      ← just ScheduleAuditPage (25 lines)
  widgets/
    schedule_audit_form.dart      ← ScheduleAuditForm + _State (374 lines)
```

**Complexity**: Low — move code to new file, update 2 import sites.

**Trade-offs**:
- ✅ Each file has one responsibility
- ✅ `ScheduleAuditForm` becomes independently testable
- ✅ Reduces `schedule_audit_page.dart` to 25 lines (safely under all thresholds)
- ⚠️ Requires updating any bottom sheet callers that import `schedule_audit_page.dart` to import the new `schedule_audit_form.dart`

---

## 🟡 CF-4 — `template_builder_page_logic.dart` — nested closure factory in `_validate()`

**File**: `lib/features/templates/pages/template_builder_page_logic.dart` Lines 140–234

### Problem
`_validate()` (94 lines) contains a **nested local function** `validateGroups()` that is **recursively defined inside the method body**. This is legal Dart but makes the method unreadable and untestable in isolation:

```dart
ValidationErrors _validate() {
  ...
  void validateGroups(List<EditableGroup> groups, String prefix) { // ← defined inside _validate
    for (...) {
      validateGroups(g.subSections, ...); // ← recursive call
    }
  }
  validateGroups(_sections, 'section:'); // ← called once
  ...
}
```

The recursion also re-evaluates `_weightedDensity` and `_scoringMode` instance fields on every call, making it dependent on UI state.

### Fix
Extract `validateGroups` as a private static helper method on the extension:
```dart
// Extract as private method in the extension:
void _validateGroups(
  List<EditableGroup> groups,
  String prefix,
  ValidationErrors errors,
  Map<String, GlobalKey> errorKeys,
  {required bool weightedDensity, required String scoringMode}
) {
  ...
}
```

This makes it unit-testable by passing state as parameters instead of reading instance fields.

**Complexity**: Medium — method extraction with 5 parameters. Requires rewriting the closure to accept injected state.

**Trade-offs**:
- ✅ `_validateGroups` becomes unit-testable with a mock `EditableGroup` list
- ✅ Removes hidden dependency on instance fields
- ⚠️ Method signature grows (5 params) — could use a record type instead

---

## 🟡 CF-5 — 30 of 43 Managers/Services Have Zero Test Coverage

### High-Risk Untested Files

The following files have **complex branching logic** and **zero behavioral tests**, ordered by impact:

| Priority | Feature | File | Risk Reason |
|----------|---------|------|-------------|
| **P1** | `action_plans` | `action_plan_manager_transitions.dart` | State machine transitions. Logic bugs = silently wrong AP status. |
| **P1** | `audit` | `audit_manager_submit.dart` | Submission pipeline. Errors = data loss |
| **P1** | `audit` | `audit_manager_draft.dart` | Draft save/restore. Errors = lost audit work |
| **P2** | `auth` | `auth_manager.dart` | **Already tested** ✅ |
| **P2** | `dashboard` | `dashboard_manager.dart` | **Already tested** ✅ |
| **P2** | `audit` | `history_manager.dart` | Pagination + filter logic |
| **P2** | `admin` | `admin_audit_manager.dart` | Cross-filter logic (store × auditor) |
| **P3** | All API services | `*_api_service.dart` | HTTP contract verification |

### Recommended First Targets
Focus tests on files with **complex branching** first, not API services:

```
1. action_plan_manager_transitions.dart  ← State machine (finite transitions, easy to unit test)
2. audit_manager_draft.dart              ← Draft key generation + restore logic  
3. audit_manager_submit.dart             ← Outbox insert + error recovery
```

**Complexity**: Medium per file (requires mock setup with `mocktail`).

**Trade-offs**:
- ✅ Each test prevents production silent failures
- ✅ These managers are mostly pure logic (no Flutter widgets) = fast unit tests
- ⚠️ Full test suite for all 30 is a significant investment; prioritize P1 targets

---

## 🟢 CF-6 — Dead No-Op `addPostFrameCallback` in `template_builder_page_logic.dart`

**File**: `lib/features/templates/pages/template_builder_page_logic.dart` Lines 311–313

### Problem
```dart
void _addSection() {
  setState(() { ... });
  // Auto-scroll to the new section after frame renders
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // The new section is at the bottom of the ScrollView   ← COMMENT ONLY, NO CODE
  });
}
```
A `addPostFrameCallback` is registered with an **empty body**. This schedules a no-op callback on every frame after `_addSection()` is called. It's dead code — likely a placeholder that was never implemented.

### Fix
```dart
// Delete lines 311-313 entirely:
WidgetsBinding.instance.addPostFrameCallback((_) {
  // The new section is at the bottom of the ScrollView
});
```

**Complexity**: Low — delete 4 lines. Zero behavior change.

**Trade-offs**:
- ✅ Removes misleading placeholder comment
- ✅ Stops registering no-op callbacks (micro-performance)
- ⚠️ If auto-scroll was intentional, it should be implemented properly

---

## File Size Hot Spots (Warning Tier)

| Lines | File | Action |
|-------|------|--------|
| 399 | `admin/pages/schedule_audit_page.dart` | CF-3 fix → split immediately |
| 387 | `templates/pages/template_builder_page_logic.dart` | Extract `_validateGroups`, delete dead callback |
| 377 | `admin/pages/widgets/store_form_sheet.dart` | Watch — approaching limit |
| 377 | `templates/pages/template_wizard_page.dart` | Watch |
| 365 | `admin/widgets/user_create_sheet.dart` | Watch |
| 364 | `admin/widgets/dropdown_card.dart` | Watch |
| 363 | `audit/pages/audit_form_page.dart` | Watch |

> All "Watch" files should be reviewed before adding new features to prevent crossing the 400-line mandatory split threshold.

---

## Recommended Fix Order

| Priority | ID | File(s) | Action |
|----------|----|---------|--------|
| 1 (Arch) | CF-2 | `sign_out_tile.dart` | After CS-2: replace `OutboxDao` with `SyncEngine` |
| 2 (Arch) | CF-1 | `action_required_widget.dart` | Route `watchPendingAssignments()` through manager |
| 3 (Size) | CF-3 | `schedule_audit_page.dart` | Extract `ScheduleAuditForm` to `widgets/` |
| 4 (Dead) | CF-6 | `template_builder_page_logic.dart` | Delete dead `addPostFrameCallback` |
| 5 (Quality) | CF-4 | `template_builder_page_logic.dart` | Extract `_validateGroups` to testable method |
| 6 (Tests) | CF-5 | `action_plans`, `audit` | Write tests for P1 manager files |

---

> *Pass audit report to Builder agent (@Forge) for /implement (Track B).*
