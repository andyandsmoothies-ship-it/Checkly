# GEMINI.override.md — `lib/features/audit/manager/`

## [CONFIRMED] State Blindness: Remote Lists Must Merge Local SQLite Draft Overrides

**Date confirmed:** 2026-04-06 | **Fix commit:** Draft Visibility State Hydration

**Problem:** `HistoryManager` displayed remote API submissions without checking `DraftService` SQLite.
A submission the user had already started locally (creating a local draft) remained in `'scheduled'` state
on the server, so the Activity page showed it in "Todo" with a "Start" button instead of "Doing"/"Resume".

**Rule:** Any `ChangeNotifier` that renders a remote API list of submissions MUST call
`_applyLocalDraftOverrides()` (or equivalent) before emitting to `submissions.value`.
- Must apply on ALL paths: cached read, fresh API fetch, and pagination `loadMore()`.
- Must NOT write overrides back to Drift cache — cache is server ground truth on disk.

**Draft Key Format:** `"${templateId}:${storeId}:${userId}"` — colon separator.
Use `startsWith('$templateId:$storeId:')` for prefix matching (not `==`, not underscore separator).

**Exemption:** `startScheduledAudit()` can set status directly on its returned DTO since the server
has already confirmed the transition — no local draft prefix check needed there.
