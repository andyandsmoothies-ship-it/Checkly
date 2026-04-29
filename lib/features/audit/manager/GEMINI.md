# GEMINI.md — lib/features/audit/manager

## [CONFIRMED] Scheduled Audit Resume Gap: No Local Draft on First Start

**Problem:** `startAudit()` (called when opening a scheduled audit) transitions the server status
(scheduled → draft) but does NOT create a local SQLite draft immediately.
The local draft only starts saving after the first answer is changed (3s debounce via `DraftService.scheduleSave`).
If the auditor leaves before answering a single question, `hasDraft = false` and clicking "Resume"
opens a blank form.

**Impact:** First-time open of a scheduled audit always starts from zero — this is expected behavior.
But previously, navigating away before any answer would also start from zero on the next open — this was a bug.

**Fix Applied (2026-04-14):** In `startAudit()`, when `_targetSubmissionId != null`, immediately call
`_draftService.flushSave()` with an empty answers stub after the debounced `_scheduleDraftSave()`.
This guarantees `hasDraft = true` on the very next open, so the restore path fires correctly.

**Invariant:** Do NOT move this logic inside `_scheduleDraftSave()`. Debounced saves exist for
performance (answer input) — the flush is a targeted one-shot on scheduled audit open only.
- **Gotcha 18: Implicit Dependency Lookup Failure in Testing**
  - **Problem:** Using `?? _di<Service>()` fallbacks inside a constructor hides dependencies from the test suite, causing silent `GetIt` crashes when testing paths that don't mock it.
  - **Fix:** All required dependencies MUST be passed via explicit constructor parameters.
