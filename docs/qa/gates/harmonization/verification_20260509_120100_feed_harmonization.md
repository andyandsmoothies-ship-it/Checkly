# Verification Gate: Feed Harmonization (Home vs Activity Page)

## Context
The user observed that the "Recent Activity" feed on the Home Page was missing items and generally didn't reflect the same rich detail seen on the dedicated "Activity" page. 

## Investigation Findings
1. The **Activity page** (`HistoryManager`) fetched items from the `cached_submissions` database and actively merged in locally stored drafts (via `draft_answers`) and outbox items, sorting everything sequentially by `createdAt`.
2. The **Home Page** (`DashboardManager._getMergedRecentSubmissions`) was only fetching synced submissions from `cached_submissions` and manually appending outbox items, completely ignoring unsynced local drafts (`draft_answers`) resulting in an incomplete view.

## Resolution
*   Renamed the private `_applyLocalOverrides` method inside `HistoryManager` to be a public `applyLocalOverrides`.
*   Refactored `DashboardManager._getMergedRecentSubmissions` to bypass manual outbox appending and directly delegate the raw list from the DB to `_di<HistoryManager>().applyLocalOverrides(recent)`.
*   Both feeds are now fundamentally hydrated using exactly the same logic and single source of truth, yielding 100% parity across pages.

## Verification
*   `flutter analyze` passed with 0 issues.
*   `flutter test` passed all 467 tests, confirming zero regressions.

**Status:** COMPLETE AND VERIFIED.
