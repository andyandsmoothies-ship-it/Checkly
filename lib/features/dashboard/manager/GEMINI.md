# GEMINI.md — `lib/features/dashboard/manager/`

## [CONFIRMED] DashboardManager Reload Method Name

**Date confirmed:** 2026-04-06 | **Fix:** Intent-Driven Draft UI Revamp

**Problem:** Plan docs (and AI generation) consistently invent `loadDashboard()` — this method does NOT exist.
The correct public reload method is `loadStats()`.

**Rule:** Always call `_di<DashboardManager>().loadStats()` when triggering a dashboard refresh from any widget action.

**Example violation to avoid:**
```dart
// ❌ Wrong — does not exist, causes compile error
await _di<DashboardManager>().loadDashboard();

// ✅ Correct
await _di<DashboardManager>().loadStats();
```
