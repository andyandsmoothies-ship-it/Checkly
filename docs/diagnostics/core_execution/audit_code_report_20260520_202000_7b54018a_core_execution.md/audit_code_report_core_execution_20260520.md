# /audit-code Report — Core Execution Domain
**Generated:** 2026-05-20T20:30:00+07:00
**ShortID:** 7b54018a
**Scope:** Templates, Submissions, ActionPlans, Photos (server + Flutter)
**Role:** Sentinel (QA) | Read-Only Analysis

```
[Flutter lib/features/] --> [server/Features/] --> [Common/ DB]
         |                          |
    [templates]              [Templates]
    [audit]                  [Submissions]
    [action_plans]           [ActionPlans]
                             [Photos]
```

---

## Critical Findings

---

### CRIT-01: Dead Endpoint — `UploadProgramPhoto.cs` is a 410 Stub

**File:** `server/Features/Photos/UploadProgramPhoto.cs` (25 lines)
**Issue:** The entire handler body is a `TypedResults.Problem(statusCode: 410)` return.
The endpoint is still registered in `PhotoEndpoints.cs`. Dead API surface, dead code.

**Evidence (lines 17-23):**
```csharp
public static Task<IResult> HandleAsync(string photoLocalKey)
{
    return Task.FromResult<IResult>(TypedResults.Problem(
        statusCode: 410, title: "Gone",
        detail: "Program photo upload via this endpoint is deprecated..."));
}
```

**Fix:**
1. Remove the route registration from `PhotoEndpoints.cs`.
2. Delete `server/Features/Photos/UploadProgramPhoto.cs`.
3. Grep `lib/` for the URL `photos/programs/evidence` to confirm no Flutter call site.

**Complexity:** Low — file deletion + one line in PhotoEndpoints.

**Trade-offs:**
- PRO: Eliminates dead API surface and attack surface.
- CON: External clients relying on 410 will get 404 instead. Minimal risk — endpoint was already marked deprecated.

---

### CRIT-02: Magic Status Strings — Raw Literals Across 8 Files

**Files:** `FinalizeSubmission.cs`, `VoidSubmission.cs`, `CreateSubmission.cs`,
`UpdateSubmission.cs`, `ReviewSubmission.cs`, `ListSubmissions.cs`,
`GetSubmission.cs`, `StoreAnalyticsUpdater.cs`

**Issue:** Status values like "completed", "voided", "draft", "scheduled", "approved",
"rejected", "open", "in_progress" appear as raw string literals in 8+ files.
No shared constants class exists. One typo causes a silent business logic failure.

**Evidence (selected samples):**
```csharp
// VoidSubmission.cs:47,68
if (submission.Status == "voided") ...
submission.Status = "voided";

// StoreAnalyticsUpdater.cs:24,33
&& s.Status == "completed"
ap.Status == "open"

// ReviewSubmission.cs:64
var notifType = request.Status == "approved"
```

**Fix:** Create constants files mirroring the existing `SubmissionActions.cs` pattern:

```csharp
// server/Features/Submissions/SubmissionStatus.cs
public static class SubmissionStatus
{
    public const string Draft = "draft";
    public const string Scheduled = "scheduled";
    public const string Completed = "completed";
    public const string Voided = "voided";
}

// server/Features/Submissions/ReviewStatus.cs
public static class ReviewStatus
{
    public const string Approved = "approved";
    public const string Rejected = "rejected";
}

// server/Features/ActionPlans/ActionPlanStatus.cs
public static class ActionPlanStatus
{
    public const string Open = "open";
    public const string InProgress = "in_progress";
    public const string Closed = "closed";
}
```

Then find/replace within feature folders only. NEVER touch DB column names or migration files.

**Complexity:** Medium — 8 files touched. Must be a dedicated commit. Must not include feature work.

**Trade-offs:**
- PRO: Eliminates typo bugs. Enables IDE rename refactoring. Greppable status transitions.
- CON: Large diff. Risk if accidentally changing DB-stored strings instead of comparison code. Run full test suite before merging.

---

## Warning Findings

---

### WARN-01: 6 Dead Flutter Methods — Zero Call Sites

**File:** `lib/features/templates/services/template_api_service.dart` (lines 82-214)

**Issue:** Six methods declared but never called anywhere in `lib/`:
`createGroup()`, `updateGroup()`, `deleteGroup()`, `createCriterion()`, `updateCriterion()`, `deleteCriterion()`

The Template Builder uses only `saveTemplateTree()` for all mutations.

**Evidence:** Grep for any of the 6 method names across all `.dart` files = zero results.

**NOTE FOR BUILDER:** Server endpoints for these operations are still live
(`CreateGroup.cs`, `UpdateGroup.cs`, etc. still registered in `TemplateEndpoints.cs`).
If no other client calls them, delete both Flutter methods AND the server handlers + endpoint registrations in the same PR.

**Fix:** Delete lines 82-214 from `template_api_service.dart`.

**Complexity:** Low — pure deletion.

**Trade-offs:**
- PRO: Removes 130 lines of untested dead code.
- CON: If a future feature needs per-item CRUD, methods must be re-created. Low risk — `saveTemplateTree` is strictly superior.

---

### WARN-02: Cross-Feature Coupling in `TemplateEndpoints.cs`

**File:** `server/Features/Templates/TemplateEndpoints.cs` (lines 74-85)

**Issue:** Templates feature file directly references types from Submissions and Auth namespaces:

```csharp
syncGroup.MapGet("/submissions", Checkly.Api.Features.Submissions.SyncSubmissions.HandleAsync);
syncGroup.MapGet("/profile", Checkly.Api.Features.Auth.SyncProfile.HandleAsync);
```

The `/api/sync` route group is a cross-cutting concern, not part of the Templates feature.
This is a VSA boundary violation.

**Fix:** Create `server/Features/Sync/SyncEndpoints.cs`:

```csharp
public static class SyncEndpoints
{
    public static void MapSyncEndpoints(this WebApplication app)
    {
        var syncGroup = app.MapGroup("/api/sync")
            .WithTags("Sync")
            .RequireAuthorization();

        syncGroup.MapGet("/templates", SyncTemplates.HandleAsync).WithName("SyncTemplates");
        syncGroup.MapGet("/submissions", Submissions.SyncSubmissions.HandleAsync).WithName("SyncSubmissions");
        syncGroup.MapGet("/profile", Auth.SyncProfile.HandleAsync).WithName("SyncProfile");
    }
}
```

Remove the syncGroup block from `TemplateEndpoints.cs`. Wire `app.MapSyncEndpoints()` in `Program.cs`.

**Complexity:** Low — structural move, no logic change.

**Trade-offs:**
- PRO: Clean VSA boundaries. All sync routes in one file.
- CON: Requires touching `Program.cs`. No functional risk.

---

### WARN-03: Large File Sizing — 7 Files Near the 400-Line Mandatory Threshold

**Server:**

| File | Lines |
|---|---|
| `server/Features/Submissions/CreateSubmission.cs` | 365 |
| `server/Features/Templates/SaveTemplateTree.cs` | 354 |
| `server/Features/Submissions/FinalizeSubmission.cs` | 330 |

**Flutter:**

| File | Lines |
|---|---|
| `lib/features/templates/pages/template_builder_page_logic.dart` | 394 |
| `lib/features/templates/pages/template_wizard_page.dart` | 389 |
| `lib/features/audit/pages/audit_form_page.dart` | 373 |
| `lib/features/audit/manager/audit_manager.dart` | 365 |

**Proposed Decomposition (Server):**

`CreateSubmission.cs` (365L):
- `CreateSubmission.cs` — core handler orchestration
- `SubmissionFactory.cs` — `BuildNewSubmission(...)` builder
- `AnswerMapper.cs` — answer list mapping

`FinalizeSubmission.cs` (330L):
- `FinalizeSubmission.cs` — orchestration only
- `ScoringEngine.cs` — score computation
- `PostFinalizationNotifier.cs` — notification dispatch

**Complexity:** Medium-High — logic extraction requires careful dependency tracing. Dedicated housekeeping sprint only.

**Trade-offs:**
- PRO: Files become individually reviewable. AI agents perform better on smaller files.
- CON: More files. Extraction risks breaking parameter chains if not done carefully.

---

### WARN-04: Coverage Gap — 4 Critical Handlers With Zero Integration Tests

| Handler | Gap |
|---|---|
| `AddComment.cs` | Zero tests. Data also not persisted (see infra audit). |
| `UpdateActionPlan.cs` | Status transition logic has zero tests. |
| `ListActionPlans.cs` | AreaManager global fallback branch has zero tests (data leak risk). |
| `GetSurveyResults.cs` | Multi-choice comma-split aggregation has zero tests. |

**Fix:** Raise ATDD stubs. Priority: `AddComment` and `ListActionPlans` (area_manager) first.

**Complexity:** Medium — requires TestWebApplicationFactory + DB seeding per scenario.

---

### WARN-05: Duplicate Path-Traversal Guard in Two Photo Handlers

**Files:** `GetPhoto.cs:27-28` and `GetProgramPhoto.cs:27-28`

```csharp
// Identical in both:
if (fileName.Contains("..") || fileName.Contains('/') || fileName.Contains('\\'))
    return TypedResults.BadRequest();
```

**Fix:**
```csharp
// server/Features/Photos/PathValidator.cs
internal static class PathValidator
{
    internal static bool IsTraversal(string fileName)
        => fileName.Contains("..") || fileName.Contains('/') || fileName.Contains('\\');
}
```

Replace both inline guards with `if (PathValidator.IsTraversal(fileName)) return TypedResults.BadRequest();`

**Complexity:** Low — pure extraction, no logic change.

**Trade-offs:**
- PRO: Single place to add URL-encoded traversal checks later.
- CON: New file for 3 lines. Worth it for a security invariant.

---

## Optimization Findings

---

### OPT-01: `SectionScoreExploder` Swallows `JsonException` Silently

**File:** `server/Features/Submissions/SectionScoreExploder.cs:43-46`

Malformed `sectionScoresJson` produces zero section score rows with no log, no alert.

**Fix:** Add `ILogger` parameter to the method signature. Log at Warning when JSON is malformed.

---

### OPT-02: `StoreAnalyticsUpdater` — 4 Sequential DB Round-Trips

**File:** `server/Features/Submissions/StoreAnalyticsUpdater.cs:28-41`

Not recommended for immediate action — runs post-commit in background. Revisit if latency > 50ms.

---

## Severity Summary

| Finding | Severity | Effort |
|---|---|---|
| CRIT-01: Dead 410 endpoint | Critical | Low |
| CRIT-02: Magic status literals | Critical | Medium |
| WARN-01: Flutter dead CRUD methods | Warning | Low |
| WARN-02: Cross-feature coupling | Warning | Low |
| WARN-03: File sizing (7 files) | Warning | Medium-High |
| WARN-04: Coverage gaps (4 handlers) | Warning | Medium |
| WARN-05: Duplicate path guard | Warning | Low |
| OPT-01: Silent JsonException | Optimization | Low |
| OPT-02: 4 round-trips analytics | Optimization | High |

---

## Pass Categories

| Category | Result |
|---|---|
| Secrets / hardcoded credentials | CLEAN |
| TODO / FIXME stale markers | CLEAN (0 found) |
| Cross-feature DB imports | CLEAN |
| Circular namespace dependencies | CLEAN |
| Files over 400 lines (server) | CLEAN |
| Files over 400 lines (Flutter) | CLEAN |
| HATEOAS action constants | CLEAN |
| UI to DB direct imports | CLEAN |

---

## Handoff to Builder (@Forge)

**Priority order:**
1. CRIT-01 — Delete `UploadProgramPhoto.cs`
2. CRIT-02 — Create `SubmissionStatus` / `ActionPlanStatus` constants
3. WARN-01 — Delete dead Flutter CRUD methods
4. WARN-02 — Extract `SyncEndpoints.cs`
5. WARN-04 — Raise ATDD stubs for 4 handlers
6. WARN-05 — Extract `PathValidator.cs`
7. WARN-03 — Plan file splits in dedicated housekeeping sprint

**Hard rules:**
- Each finding = separate commit. Never bundle.
- `rtk dotnet test` after every server change.
- `flutter test` after every Flutter change.
- NEVER rename DB column strings when introducing status constants.
- Yield to user for approval before CRIT-02 bulk replacement.
