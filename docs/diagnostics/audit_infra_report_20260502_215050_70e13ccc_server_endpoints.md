# Infrastructure Audit Report — Server Endpoints
**Workflow**: /audit-infra | **Role**: Sentinel  
**Date**: 2026-05-02T21:50:50+07:00  
**ConversationID**: 70e13ccc  
**Scope**: `server/Common/ResourceAccessGuard.cs`, `ResourceScope.cs`, `Features/ActionPlans/UpdateActionPlan.cs`, `Features/GlobalRisks/*`, `Features/Photos/*`, `Features/Submissions/*`

---

## Skills Loaded
- `backend-architect` — API design, auth patterns, service boundaries
- `postgres-best-practices` — Index strategy, query safety, delete rules

---

## Finding Summary

| ID | Severity | File | Title |
|----|----------|------|-------|
| IS-1 | 🔴 Critical | `ReviewSubmission.cs` | Privilege Escalation: Auditor Can Self-Approve Their Own Submission |
| IS-2 | 🔴 Critical | `FinalizeSubmission.cs` | Debug File Write in Production Code |
| IS-3 | 🔴 Critical | `FinalizeSubmission.cs` | Unbounded `SubmissionRisks` Query (OOM Risk) |
| IS-4 | 🟡 Warning | `SubmissionEndpoints.cs` | Missing `RequireCapability` on `GetSubmission`, `FinalizeSubmission`, `VoidSubmission` |
| IS-5 | 🟡 Warning | `ReviewSubmission.cs` | Double `SaveChangesAsync` — Audit Log Can Be Lost on Failure |
| IS-6 | 🟡 Warning | `UploadProgramPhoto.cs` | `IsValidImageMagicBytes` Duplicated Across Two Files |
| IS-7 | 🟢 Optimization | `GetProgramPhoto.cs` | No `IsActive` Check on Assignment Before Serving Photo |
| IS-8 | 🟢 Optimization | `ResourceAccessGuard.cs` | Two DB Round-trips Per Auth Check for `IsUserAreaAsync` |

---

## 🔴 IS-1 — Privilege Escalation: Auditor Can Self-Approve Their Own Submission

**File**: `server/Features/Submissions/ReviewSubmission.cs` Lines 45–49

### Problem
`ReviewSubmission` calls `ResourceAccessGuard.CanAccessAsync` for IDOR. The guard resolves auditor access as:

```csharp
"auditor" => scope.OwnerId == userId,
```

An auditor whose `AuditorId` matches the submission passes this check. If the auditor role ever receives the `SubmissionsReview` capability, they can **approve their own audit**. 

**UPDATE**: The user confirmed that **admin AND the person who created/started the audit** are allowed to review/approve the submission (Self-Assessment pattern). Therefore, the current IDOR guard (`CanAccessAsync`) is actually **correct** for this business rule.

### Fix

Instead of changing the IDOR guard, we only need to ensure that the route has the `RequireCapability(AppCapabilities.SubmissionsReview)` gate (it already does) and that the `SubmissionsReview` capability is properly seeded for `admin` and `auditor` roles in the database.

No code changes required in `ReviewSubmission.cs`.

**Complexity**: None.

**Trade-offs**: None.

---

## 🔴 IS-2 — Debug File Write in Production Code

**File**: `server/Features/Submissions/FinalizeSubmission.cs` Line 172

### Problem

```csharp
try { System.IO.File.AppendAllText(".agents/tmp/bad_request.txt", logMsg); } catch { }
```

A dev-only debug artifact is in production code. It:
- Writes to a hardcoded relative path that won't exist in a container.
- Bypasses the structured `Serilog` logging pipeline.
- The silent `catch {}` swallows disk errors — the real debug info is lost silently.

### Fix

Delete the file write. The structured log call is sufficient:

```csharp
// DELETE line 172 entirely. Replace with:
Log.Warning("FinalizeSubmission 400: Score mismatch. Client: {Client}, Server: {Server}. Reason: {Reason}",
    request.ClientScore, verification.ServerScore, verification.Reason);
```

**Complexity**: Low — delete 1 line.

**Trade-offs**: None. Structured logging is strictly better.

---

## 🔴 IS-3 — Unbounded `SubmissionRisks` Query (OOM Risk)

**File**: `server/Features/Submissions/FinalizeSubmission.cs` Lines 51–56

### Problem

```csharp
var globalRisks = await db.SubmissionRisks
    .Include(r => r.GlobalRisk)
    .Where(r => r.SubmissionId == submission.Id)
    .ToListAsync(ct);  // No Take() limit!
```

No `.Take()`. The unique index on `(submissionId, globalRiskId)` prevents duplicates today, but if that index is dropped or bypassed, this loads unbounded rows into memory.

### Fix

```csharp
var globalRisks = await db.SubmissionRisks
    .Include(r => r.GlobalRisk)
    .Where(r => r.SubmissionId == submission.Id)
    .Take(500) // Safety cap — a submission will never legitimately have 500 global risks
    .ToListAsync(ct);
```

**Complexity**: Low — add `.Take(500)` on one line.

**Trade-offs**: None meaningful.

---

## 🟡 IS-4 — Missing `RequireCapability` on 3 Sensitive Routes

**File**: `server/Features/Submissions/SubmissionEndpoints.cs` Lines 29–43

### Problem

Three routes have **no capability gate** — only the group `RequireAuthorization()`:

```csharp
group.MapGet("/{id}", GetSubmission.HandleAsync)        // ← No capability
group.MapPut("/{id}/finalize", FinalizeSubmission.HandleAsync)  // ← No capability
group.MapPost("/{id}/void", VoidSubmission.HandleAsync) // ← No capability
```

The handlers have IDOR guards, but there's no PBAC layer preventing unauthorized roles from even reaching the handler body.

### Fix

```csharp
group.MapGet("/{id}", GetSubmission.HandleAsync)
    .WithName("GetSubmission")
    .RequireCapability(AppCapabilities.SubmissionsRead);

group.MapPut("/{id}/finalize", FinalizeSubmission.HandleAsync)
    .WithName("FinalizeSubmission")
    .RequireCapability(AppCapabilities.SubmissionsCreate);

group.MapPost("/{id}/void", VoidSubmission.HandleAsync)
    .WithName("VoidSubmission")
    .RequireRole("admin"); // USER CONFIRMED: Admin ONLY
```

**Complexity**: Low — 3 one-liners.

**UPDATE**: The user confirmed that **only admins** should be able to void a submission. We will use `.RequireRole("admin")` for the `VoidSubmission` endpoint.

---

## 🟡 IS-5 — Double `SaveChangesAsync` — Audit Log Loss Risk

**File**: `server/Features/Submissions/ReviewSubmission.cs` Lines 87–91

### Problem

```csharp
await db.SaveChangesAsync(ct);   // Line 87 — saves submission + notification
AuditLogger.Log(db, user, ...);  // Line 88 — stages audit log row in context
await db.SaveChangesAsync(ct);   // Line 91 — saves audit log row
```

If the second save fails, the review action is committed but the audit trail is **silently lost**.

### Fix

Stage audit log **before** the single save:

```csharp
// Stage all changes
submission.ReviewStatus = request.Status;
// ... other field assignments ...
if (submission.AuditorId.HasValue)
    db.Notifications.Add(new Notification { ... });

// Stage audit log BEFORE saving
AuditLogger.Log(db, user, "submission_reviewed", "Submission", submission.Id,
    message: $"Submission '{submission.Id}' reviewed as '{request.Status}'",
    userEmail: user.FindFirstValue(ClaimTypes.Email));

// Single atomic flush
await db.SaveChangesAsync(ct);

// FCM dispatch AFTER successful save (outside DB transaction, acceptable)
if (submission.AuditorId.HasValue)
    await fcm.DispatchSyncNeededAsync(submission.AuditorId.Value);
```

**Complexity**: Low — reorder 3 lines.

---

## 🟡 IS-6 — `IsValidImageMagicBytes` Duplicated Across Two Files

**Files**: `UploadPhoto.cs` lines 102–130, `UploadProgramPhoto.cs` lines 81–106

### Problem

Magic byte validation logic is copy-pasted identically. A new format (e.g., AVIF) requires changes in two places.

### Fix

```csharp
// NEW FILE: server/Common/ImageValidation.cs
namespace Checkly.Api.Common;

public static class ImageValidation
{
    public static bool IsValidImageMagicBytes(byte[] header, int bytesRead)
    {
        if (bytesRead < 3) return false;
        if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) return true;
        if (bytesRead >= 8 && header[0] == 0x89 && header[1] == 0x50 ...) return true;
        if (bytesRead >= 12 && header[0] == 0x52 && header[1] == 0x49 ...) return true;
        if (bytesRead >= 8 && header[4] == 0x66 && header[5] == 0x74 ...) return true;
        return false;
    }
}
```

Then replace the private methods in both handlers with `ImageValidation.IsValidImageMagicBytes(header, bytesRead)`.

**Complexity**: Low — pure extraction, zero behavior change.

---

## 🟢 IS-7 — No `IsActive` Check on Assignment in `GetProgramPhoto`

**File**: `server/Features/Photos/GetProgramPhoto.cs` Line 35

### Fix

```csharp
if (assignment is null || !assignment.IsActive)
    return TypedResults.NotFound();
```

**Complexity**: Low — 1 condition.

---

## 🟢 IS-8 — Two DB Round-trips in `ResourceAccessGuard.IsUserAreaAsync`

**File**: `server/Common/ResourceAccessGuard.cs` Lines 42–52

### Fix

Replace `FirstOrDefaultAsync` + separate store lookup with a single `AnyAsync`:

```csharp
// Single query instead of two
return await db.Stores.AsNoTracking()
    .AnyAsync(s => s.Id == storeId && s.AreaId == profile.AreaId, ct);
```

**Complexity**: Low — replaces 2 lines with 1.

---

## Routing Map & Implementation Order

| Order | Finding | Severity | Route |
|-------|---------|----------|-------|
| 1 | IS-2 Debug File Write | 🔴 Critical | `FinalizeSubmission.cs` (Delete line 172) |
| 2 | IS-3 Unbounded Query | 🔴 Critical | `FinalizeSubmission.cs` (Add `.Take(500)`) |
| 3 | IS-4 Missing Capabilities | 🟡 Warning | `SubmissionEndpoints.cs` (Add capability/role gates) |
| 4 | IS-5 Double SaveChanges | 🟡 Warning | `ReviewSubmission.cs` (Reorder save logic) |
| 5 | IS-6 Duplicated Validator | 🟡 Warning | Extract `ImageValidation.cs` and update Photos endpoints |
| 6 | IS-7 No IsActive Check | 🟢 Optimization | `GetProgramPhoto.cs` (Add `!IsActive`) |
| 7 | IS-8 Two DB Round-trips | 🟢 Optimization | `ResourceAccessGuard.cs` (Consolidate queries) |
| N/A | IS-1 Privilege Escalation | 🟢 Resolved | No change needed; user confirmed Self-Assessment intent. |

---

## Strict Implementation Constraints

- **IS-1 is resolved** (intended self-assessment feature).
- **IS-4 is resolved** (admin-only for void).
- **All fixes are ready to implement** and isolated to single files — no cross-boundary blast radius.
