# Audit Code Report — System Core Domain
**Audit ID:** `audit_code_20260520_204118_7b54018a_system_core`
**Role:** Sentinel (QA)
**Date:** 2026-05-20
**Scope:** `server/Common/` · `lib/_shared/`
**Workflow:** `/audit-code`
**Skills Used:** `clean-architecture`, `de-sloppify`

---

## Executive Summary

The System Core Domain is the **engine room** of the application. It contains the shared auth cache, scoring verifier, background services, router, Drift schema, and Flutter services. The core is architecturally sound — no secret leaks, no hard import boundary violations. However, 8 findings exist across two stale placeholders, four near-threshold files, a silent data loss path, and a broken docs file.

| Severity | Count | Finding IDs |
|---|---|---|
| 🔴 Critical | 0 | — |
| 🟡 Warning | 5 | SC-1, SC-2, SC-3, SC-4, SC-5 |
| 🟢 Optimization | 3 | SC-6, SC-7, SC-8 |

---

## Phase 2: Code Quality Scan

### ✅ Secrets Scan — CLEAR
No hardcoded credentials detected in `server/Common/` or `lib/_shared/`.

### ✅ Architectural Drift — CLEAN
No inner-ring-imports-outer-ring violations. `server/Common/` does not import from `server/Features/`. `lib/_shared/` does not import from feature-layer DAOs. The router imports pages correctly (it is the composition root).

### 🟡 Docs — Duplicate Heading in `lib/_shared/GEMINI.md`
Lines 1 and 3 both contain `# Shared Flutter Rules & Gotchas`. Markdown renders two identical headings, breaking document navigation.

---

## Findings

---

### SC-1 🟡 — Dead Method: `SendScheduleReminders` in `ReminderService.cs`

**File:** `server/Common/Services/ReminderService.cs` — Lines 262–267

```csharp
// S7: Placeholder for scheduled audit reminders.
// Actual scheduled audits feature requires a ScheduledAudit entity — deferred.
private Task SendScheduleReminders(AppDbContext db, CancellationToken ct)
{
    _logger.LogDebug("S7: Schedule reminders — no scheduled audits entity yet");
    return Task.CompletedTask;
}
```

**Problem:** Always called from `ExecuteAsync` but produces zero business behavior. No issue number, no owner, no completion date. It is a stub masquerading as a real operation.

**Fix Option A — Delete (Recommended):**
```csharp
// In ExecuteAsync, remove this line:
// await SendScheduleReminders(db, tickCt);

// Then delete the entire method (lines 262–267).
```

**Fix Option B — Track it:**
```csharp
// TODO(#999): Implement SendScheduleReminders when ScheduledAudit entity exists.
private static Task SendScheduleReminders(AppDbContext db, CancellationToken ct)
    => Task.CompletedTask;
```

> **Complexity:** Low — one call-site deletion + method deletion.

> **Trade-offs:**
> - Delete (A): Clean `ExecuteAsync` call chain. Risk: developer must re-add hook when feature is built. Mitigate with a GitHub issue.
> - Track (B): Preserves wiring. Risk: stale TODO forever if ticket is never created.
> - **Recommendation:** Option A. `ScheduledAudit` entity does not exist today.

---

### SC-2 🟡 — Stale Placeholder + Silent Data Loss in `OutboxBackgroundService.cs`

**File:** `server/Common/Services/OutboxBackgroundService.cs` — Lines 92–113

**Stale comment (line 94):**
```csharp
// Basic placeholder for dispatch logic - this will be fully wired in Slice 2
```

**Silent data loss path (no else branch):**
```csharp
if (message.Type == "Notification")
{
    // ... dispatch ...
}
// No else — unknown types silently write ProcessedAt=now with no error, no log.
```

**Problem:**
1. "Slice 2" is a past sprint. The comment signals incomplete work to future agents.
2. Any future `message.Type` ("Email", "Webhook") silently succeeds — `ProcessedAt` is stamped but nothing runs. This is invisible data corruption.

**Fix:**
```csharp
if (message.Type == "Notification")
{
    var fcmService = scope.ServiceProvider.GetRequiredService<IFcmDispatchService>();
    using var doc = JsonDocument.Parse(message.Payload);
    if (doc.RootElement.TryGetProperty("UserId", out var userIdElement) &&
        userIdElement.TryGetGuid(out var userId))
    {
        await fcmService.DispatchSyncNeededAsync(userId);
    }
}
else
{
    logger.LogWarning(
        "OutboxBackgroundService: unhandled message type '{Type}' (id: {Id}). Writing error.",
        message.Type, message.Id);
    message.Error = $"Unhandled message type: {message.Type}";
}
```

> **Complexity:** Low — one stale comment deletion + one `else` block.

> **Trade-offs:**
> - Pro: Eliminates silent data loss. Future types fail loudly.
> - Con: None. Strictly safer.
> - **Recommendation:** Apply immediately.

---

### SC-3 🟡 — `app_router.dart` Exceeds 250-Line Warning Threshold

**File:** `lib/_shared/router/app_router.dart` — **382 lines**

**Problem:** Three concerns in one file:
1. 37 route declarations (correct — composition root)
2. `authRedirect` function (96 lines, 5 guard blocks, high cyclomatic complexity)
3. 37 `import` statements (implicit page dependency map)

`authRedirect` is already `@visibleForTesting` — signaling it should be independently testable — but testing it requires importing the entire page layer through `app_router.dart`.

**Proposed Split:**
```
lib/_shared/router/
├── app_router.dart       ← Route declarations only (~130 lines, 37 imports)
└── auth_redirect.dart    ← authRedirect() + guard helpers (~100 lines)
                             @visibleForTesting moves here. Imports only auth/policy types.
```

> **Complexity:** Medium — update `app_router.dart`'s `redirect: authRedirect` import. Update test files that import `authRedirect`.

> **Trade-offs:**
> - Pro: `authRedirect` testable without dragging in all 37 page imports. `app_router.dart` becomes a pure declaration file.
> - Con: Two files to navigate. Page imports stay in `app_router.dart` (needed for builders).
> - **Recommendation:** Yield to user. Correct architecture, no behavior change.

---

### SC-4 🟡 — `main_shell.dart` — 3 Classes in 1 File (SRP Violation)

**File:** `lib/_shared/router/main_shell.dart` — **363 lines, 3 classes**

**Problem:**
1. `_ShellTab` — tab data model
2. `MainShell` — shell widget (StatelessWidget)
3. `_NavItem` — private nav icon + badge widget

`_NavItem` is a fully self-contained, general-purpose widget trapped behind a private prefix. It cannot be widget-tested in isolation. Future developers building a custom nav chip would duplicate it.

**Proposed Split:**
```
lib/_shared/router/main_shell.dart    ← MainShell + _ShellTab only (~200 lines)
lib/_shared/widgets/nav_item.dart     ← NavItem (promoted to package-private, ~70 lines)
```

> **Complexity:** Low — rename `_NavItem` → `NavItem`, move file, update one import.

> **Trade-offs:**
> - Pro: `NavItem` becomes widget-testable. `MainShell` drops below 250 lines.
> - Con: `_` privacy removed; `NavItem` becomes accessible to the package.
> - **Recommendation:** Yield to user. Clean split, no behavior change.

---

### SC-5 🟡 — `ScoringVerifier.cs` — 10 Lines from Mandatory Split

**File:** `server/Common/Scoring/ScoringVerifier.cs` — **390 lines** (400 = 🔴 mandatory split)

**Problem:** One class, 4 scoring mode methods. `VerifyPenalty` alone spans 105 lines. The next feature addition (e.g., a new scoring mode or per-criterion cap rule) will breach 400.

**Proposed Split:**
```
server/Common/Scoring/
├── ScoringVerifier.cs          ← Verify() dispatch + VerificationResult record (~70 lines)
├── PenaltyModeVerifier.cs      ← VerifyPenalty() (internal static class, ~110 lines)
├── ChecklistModeVerifier.cs    ← VerifyChecklist() (~35 lines)
├── AccumulationModeVerifier.cs ← VerifyAccumulation() (~65 lines)
└── ScoringVerifierHelpers.cs   ← HasFaults, GetDeduction, BuildFailedSet, GetCriteriaForGroup (~80 lines)
```

> **Complexity:** Medium — methods move to `internal static` helper classes. Existing tests reference `ScoringVerifier` directly — they continue to compile unchanged.

> **Trade-offs:**
> - Pro: Each scoring mode independently testable. `VerifyPenalty` complexity isolated.
> - Con: 4 new files. Navigation requires jumping across files per mode.
> - **Recommendation:** Yield to user. Act before the file crosses 400.

---

### SC-6 🟢 — `tables.dart` Near Warning Threshold

**File:** `lib/_shared/database/tables.dart` — **375 lines**

**Problem:** 13 Drift table definitions in one file. Declaration-only (lower risk) but will cross 400 on the next slice.

**Recommendation:** Split into domain groups before the next table addition:
```
lib/_shared/database/
├── tables_audit.dart       ← CachedTemplates, CachedGroups, CachedCriteria, PendingSubmissions, PendingAnswers, PendingPhotos
├── tables_actions.dart     ← CachedActionPlans, PendingActionPlanUpdates
├── tables_sync.dart        ← CachedStores, CachedNotifications, CachedProfiles, CachedPolicies, SyncMeta, DraftAnswers
├── tables_programs.dart    ← CachedProgramAssignments
└── tables_risks.dart       ← CachedGlobalRisks, SubmissionRiskOutboxEntries
```

> **Complexity:** Medium — requires `dart run build_runner build` to regenerate `app_database.g.dart` (610KB). `@DriftDatabase(tables: [...])` annotation must import from all split files.

> **Recommendation:** Defer until next slice forces a new table addition.

---

### SC-7 🟢 — `_shared/services/` Missing Barrel Export

**Folder:** `lib/_shared/services/` — **38 files, no barrel export**

**Problem:** Every feature uses full relative path imports. Moving or renaming any file breaks all consumers.

**Fix:**
```dart
// lib/_shared/services/services.dart
export 'api_client.dart';
export 'scoring_engine.dart';
export 'sync_engine.dart';
export 'sync_module.dart';
export 'connectivity_service.dart';
export 'policy_manager.dart';
// ... all public-facing services
```

> **Complexity:** Low — one new file.

> **Recommendation:** Non-blocking. Apply in next cleanup pass.

---

### SC-8 🟢 — Duplicate Heading in `lib/_shared/GEMINI.md`

**File:** `lib/_shared/GEMINI.md` — Lines 1 and 3

**Fix:** Delete line 1 (or line 3). One `# Shared Flutter Rules & Gotchas` is correct.

> **Complexity:** Low — one-line deletion.

---

## Phase 3: Structural Health Summary

| File | Lines | Threshold | Status |
|---|---|---|---|
| `ScoringVerifier.cs` | 390 | 400 (critical) | 🟡 10 lines from mandatory split |
| `app_router.dart` | 382 | 250 (warning) | 🟡 Exceeds warning |
| `tables.dart` | 375 | 250 (warning) | 🟡 Exceeds warning |
| `main_shell.dart` | 363 | 250 (warning) | 🟡 Exceeds warning |
| `ReminderService.cs` | 296 | 250 (warning) | 🟡 Exceeds warning |
| `PbacCacheListenerService.cs` | 210 | — | ✅ Pass |
| All other files | < 165 | — | ✅ Pass |

**Method Size:**
- `VerifyPenalty()` = 105 lines. Approaches the 150-line limit.
- `authRedirect()` = 95 lines. Acceptable but 5 guard branches create high cyclomatic complexity.

---

## Phase 4: Coverage & Hygiene Summary

| Vector | Detail |
|---|---|
| **Stale Markers** | 2 — `OutboxBackgroundService.cs:94` ("Slice 2 placeholder"), `ReminderService.cs:262` ("S7: deferred"). Both lack issue numbers and owners. |
| **Coverage Gaps** | `OutboxBackgroundService` — no test for unknown `message.Type` (silent pass path). `SendScheduleReminders` — 0% testable behavior. |
| **Duplication** | `ReminderService.cs` lines 186–196 and 247–256 duplicate the FCM dispatch pattern. Extractable to `private async Task DispatchFcmBatch(HashSet<Guid> targets)`. |

---

## Handoff

Pass audit report to Builder agent (@Forge) for implementation **(Track B)**.

**Priority Order:**
| # | Finding | Effort | Action |
|---|---|---|---|
| 1 | SC-2 | Low | Fix `OutboxBackgroundService` — delete stale comment, add `else` branch |
| 2 | SC-1 | Low | Delete `SendScheduleReminders` dead stub + call site |
| 3 | SC-8 | Low | Fix duplicate heading in `GEMINI.md` |
| 4 | SC-3 | Medium | Split `app_router.dart` — get user approval first |
| 5 | SC-4 | Medium | Promote `_NavItem` to `nav_item.dart` |
| 6 | SC-5 | Medium | Split `ScoringVerifier.cs` — act before crossing 400 lines |
| 7 | SC-6 | Medium | Split `tables.dart` — defer to next slice |
| 8 | SC-7 | Low | Add barrel export for `_shared/services/` |
