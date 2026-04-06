# GEMINI.override.md — `lib/features/audit/services/`

## [CONFIRMED] DraftService is NOT registered in GetIt

**Date confirmed:** 2026-04-06 | **Fix:** Draft Safety Enhancements

**Problem:** `DraftService` uses `GetIt.instance<DatabaseService>().db` internally, but the class itself
is NOT registered in `locator.dart`. Calling `GetIt.instance<DraftService>()` will throw.

**Rule:** Use `DraftService()` direct construction for one-shot calls (e.g., startup GC in `main.dart`).
`AuditManager` owns the long-lived singleton via `_draftService` field (constructed at line 103).

---

## [CONFIRMED] Drift Data Class: DraftAnswers Table → DraftAnswer Type

**Problem:** Drift auto-singularizes table class names to produce data row types.

| Table class | Data row type | Companion type |
|---|---|---|
| `DraftAnswers` | `DraftAnswer` | `DraftAnswersCompanion` |

**Anti-pattern to avoid:**
```dart
// ❌ Wrong — type does not exist
Future<void> _helper(DraftAnswersData row) { ... }

// ✅ Correct
Future<void> _helper(DraftAnswer row) { ... }
```
