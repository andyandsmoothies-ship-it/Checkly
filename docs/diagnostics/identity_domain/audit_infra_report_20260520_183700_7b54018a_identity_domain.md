# Audit Report: Identity Domain Infrastructure
**Workflow:** `/audit-infra`
**Role:** Sentinel (QA)
**Date:** 2026-05-20
**ShortID:** 7b54018a

```
[Flutter lib] --> [Server API] --> [AppDbContext] --> [PostgreSQL]
   auth/            Auth/            Profiles            user_roles
   admin/           Admin/           UserGroups          user_group_members
   user_groups/     UserGroups/      UserDeviceTokens    system_logs
   profile/         Users/           RoleCapabilities
```

> [!IMPORTANT]
> This report targets the Identity Domain only.
> Builder (Forge) must not act on these without explicit user approval.

---

## Severity Summary

| Severity | Count |
|---|---|
| 🔴 Critical | 3 |
| 🟡 Warning | 4 |
| 🟢 Optimization | 3 |

---

## 🔴 CRITICAL-01: Open Self-Registration — Anyone Can Become a Store Manager

**File:** `server/Features/Auth/Register.cs` lines 35-42
**Evidence:**
```csharp
if (request.Role == "admin")  // ONLY admin is guarded
{
    var callerRole = httpContext.User.FindFirst(ClaimTypes.Role)?.Value;
    if (callerRole != "admin") return TypedResults.Forbid();
}
```
**Problem:** Only `admin` role is guarded. Any unauthenticated actor can POST to `/api/auth/register` with `"role": "store_manager"` or `"area_manager"` and get a valid JWT. The endpoint is under `.AllowAnonymous()`.

**Fix Options:**

**Option A — Make non-auditor roles admin-provisioned only (Recommended):**
```csharp
private static readonly HashSet<string> AnonymousAllowedRoles = ["auditor"];

if (!AnonymousAllowedRoles.Contains(request.Role))
{
    var callerRole = httpContext.User.FindFirst(ClaimTypes.Role)?.Value;
    if (callerRole != "admin")
        return TypedResults.Forbid();
}
```
- **Complexity: Low** — 1-line change. No migration. No client changes.
- **Trade-offs:** Closes the security gap immediately. Breaks any existing dev flow that self-registers SMs — dev seeding must go through `POST /api/admin/users`.

**Option B — Remove Register endpoint entirely:**
- **Complexity: Medium** — Must confirm no Flutter client relies on it for SM/AM flows, then delete endpoint.
- **Trade-offs:** Zero attack surface. Admin must pre-provision every account.

> 🚨 Sentinel recommends Option A as minimum viable patch. User must decide which option to proceed with.

---

## 🔴 CRITICAL-02: Missing Flutter Client for FCM Device Token Registration

**Server:** `server/Features/Users/RegisterDeviceToken.cs` → `POST /api/users/me/device-tokens`
**Flutter:** No method exists in any service. `grep "device.token" lib/` = 0 results.

**Problem:** FCM push notification registration is completely dead. Backend stores tokens in `user_device_tokens`. Flutter never calls this endpoint. No device token is ever registered. Push notifications cannot be delivered.

**Fix — Add to `lib/features/auth/services/auth_api_service.dart`:**
```dart
/// POST /users/me/device-tokens — registers FCM token for push notifications.
Future<void> registerDeviceToken({
  required String token,
  required String platform,
}) async {
  await _dio.post(
    '/users/me/device-tokens',
    data: {'token': token, 'platform': platform},
  );
}
```
Call this from the auth manager after successful login, passing the FCM token from `firebase_messaging`.

- **Complexity: Low** — 1 method + 1 call site.
- **Trade-offs:** Unblocks entire push notification system. Requires `firebase_messaging` package to be initialized before the call.

---

## 🔴 CRITICAL-03: Missing Flutter Client for UpdateGroupMembers

**Server:** `server/Features/UserGroups/UpdateMembers.cs` → `PUT /api/user-groups/{id}/members`
**Flutter:** `lib/features/user_groups/services/user_group_api_service.dart` has only `listGroups` and `createGroup`. `grep "updateMembers" lib/` = 0 results.

**Problem:** Any UI for managing group members cannot persist changes. The write path is a dead end.

**Fix — Add to `lib/features/user_groups/services/user_group_api_service.dart`:**
```dart
/// PUT /user-groups/{id}/members — replaces full member list of a group.
Future<void> updateGroupMembers(String groupId, List<String> profileIds) async {
  await _dio.put(
    '/user-groups/$groupId/members',
    data: {'profileIds': profileIds},
  );
}
```
- **Complexity: Low** — 1 method, 1 call site.
- **Trade-offs:** None. This is a missing implementation of an existing backend contract.

---

## 🟡 WARNING-01: Missing Audit Log on CreateUser

**File:** `server/Features/Admin/CreateUser.cs` — No `SystemLog` written anywhere in the handler.
**Comparison:** `UpdateUser`, `BanUser`, `TransferStoreManager` all write SystemLogs. `CreateUser` is the only Admin mutation that does not.

**Fix — Add inside the `try` block, before `SaveChangesAsync`:**
```csharp
var callerId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
db.SystemLogs.Add(new SystemLog
{
    Id = Guid.NewGuid(),
    UserId = callerId,
    Action = "create_user",
    Category = "admin",
    EntityType = "user",
    EntityId = appUser.Id,
    Message = $"Created user {request.FullName} ({request.Email}): role={request.Role}",
    Path = "/api/admin/users",
    Level = "info",
    CreatedAt = DateTimeOffset.UtcNow
});
```
- **Complexity: Low** — Copy pattern from `BanUser.cs`. No migration needed.
- **Trade-offs:** Closes the audit hole. `callerId` is already resolvable from the injected `ClaimsPrincipal user`.

---

## 🟡 WARNING-02: Missing Audit Log on ResetPassword

**File:** `server/Features/Admin/ResetPassword.cs` — No `SystemLog` written. No `AppDbContext` even injected.

**Fix — Add `AppDbContext db` and `ClaimsPrincipal user` to `HandleAsync` signature, then before the final return:**
```csharp
db.SystemLogs.Add(new SystemLog
{
    Id = Guid.NewGuid(),
    UserId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!),
    Action = "reset_password",
    Category = "admin",
    EntityType = "user",
    EntityId = id,
    Message = $"Admin reset password for {targetUser.Email}",
    Path = $"/api/admin/users/{id}/reset-password",
    Level = "warning",
    CreatedAt = DateTimeOffset.UtcNow
});
await db.SaveChangesAsync();
```
- **Complexity: Low** — Same pattern as other admin mutations.
- **Trade-offs:** `AppDbContext` is already registered globally in DI. No extra wiring needed.

---

## 🟡 WARNING-03: Missing DB Index on `user_roles.user_id`

**File:** `server/Common/Persistence/Configurations/UserRoleConfiguration.cs`
**Hot path:** `Login.cs:53` — `db.AppUserRoles.Where(r => r.UserId == user.Id)` runs on every login with a full table scan.
**Evidence:** No `e.HasIndex(x => x.UserId)` in `UserRoleConfiguration.Configure()`.

**Fix:**
```csharp
// Add to UserRoleConfiguration.Configure():
e.HasIndex(x => x.UserId)
    .HasDatabaseName("IX_user_roles_user_id");
```
Then: `rtk dotnet ef migrations add AddUserRoleUserIdIndex`

- **Complexity: Low** — 2 config lines + 1 migration. Zero application code changes.
- **Trade-offs:** Eliminates full table scan on every login. Index write overhead is negligible — UserRole writes are rare.

---

## 🟡 WARNING-04: CapabilityCatalog Endpoint Has No Capability Gate

**File:** `server/Features/Admin/AdminEndpoints.cs` lines 53-55
**Evidence:**
```csharp
group.MapGet("/capabilities/catalog", Roles.GetCapabilityCatalog.HandleAsync)
    .WithName("GetCapabilityCatalog");
// No extra capability gate — any authenticated admin may read the catalog.
```
**Problem:** Any user with a valid JWT (including `auditor` or `store_manager`) can enumerate the full PBAC capability catalog. Leaks the internal permission model.

**Fix Option A — Add capability gate:**
```csharp
.RequireCapability(AppCapabilities.AdminManageRoles);
```
**Fix Option B — Document as intentional:** The catalog is static and read-only.

- **Complexity: Low** — 1 line for Option A.
- **Trade-offs (A):** Enforces least-privilege. May break any non-admin feature pre-loading capabilities.
- **Trade-offs (B):** No change. Acceptable if capability names are not considered sensitive.

> User must decide.

---

## 🟢 OPTIMIZATION-01: Double-Guard Pattern (Redundant Manual Role Check)

**Files:** `CreateUser.cs:37`, `UpdateUser.cs:34`, `BanUser.cs:25`, `TransferStoreManager.cs:26`
**Pattern:** Each handler checks `if (callerRole != "admin") return Forbid()` AFTER the endpoint already enforces `RequireCapability(UsersManage)`.

**Problem:** The PBAC gate already rejects non-admins at the framework level. The inner guard creates a maintenance trap — if a future role ever gets `UsersManage`, the inner guard silently over-restricts it.

**Fix:** Remove the 3-line manual guard block from each of the 4 handlers.

- **Complexity: Low** — Delete 12 lines total.
- **Trade-offs:** Removes a defense-in-depth layer. If PBAC middleware is ever misconfigured, there's no fallback. Your call.

---

## 🟢 OPTIMIZATION-02: `profiles.email` — Consider trgm Index for Search at Scale

**File:** `server/Common/Persistence/Configurations/ProfileConfiguration.cs`
**Hot query:** `SearchUsers.cs:51` — `p.Email.Contains(search)` compiles to `ILIKE '%...%'` — cannot use B-tree index.

**Fix (only at scale, 50k+ users):**
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX CONCURRENTLY IX_profiles_email_trgm
ON profiles USING gin (email gin_trgm_ops);
```
- **Complexity: Medium** — Requires raw SQL migration + `pg_trgm` extension enabled.
- **Trade-offs:** Sub-10ms email search at scale. GIN indexes are larger and slower to write. Not worth it below 50k users.

---

## 🟢 OPTIMIZATION-03: UserGroup Has No Delete Endpoint

**Server:** No `DELETE /api/user-groups/{id}` exists.
**Problem:** Groups can be created but never deleted. Stale groups accumulate indefinitely.

**Fix:**
```csharp
// In UserGroupEndpoints.cs
group.MapDelete("/{id}", DeleteUserGroup.HandleAsync)
    .WithName("DeleteUserGroup")
    .RequireCapability(AppCapabilities.UsersManage);
```
New handler `DeleteUserGroup.cs` — loads the group, removes it, saves. Cascade on `UserGroupMembers` handles member cleanup.

- **Complexity: Low** — 1 handler + 1 endpoint.
- **Trade-offs:** Closes the CRUD gap. Hard-delete destroys all member history. Consider soft-delete if audit history is required.

---

## Routing Map

| ID | Severity | Route |
|---|---|---|
| CRITICAL-01: Open Self-Registration | 🔴 | `/analyze-feature` for design decision → `/implement` |
| CRITICAL-02: Missing FCM Token Client | 🔴 | `/implement` directly |
| CRITICAL-03: Missing UpdateGroupMembers Client | 🔴 | `/implement` directly |
| WARNING-01: Missing CreateUser AuditLog | 🟡 | `/implement` directly |
| WARNING-02: Missing ResetPassword AuditLog | 🟡 | `/implement` directly |
| WARNING-03: Missing `user_roles.user_id` Index | 🟡 | `/implement` directly |
| WARNING-04: CapabilityCatalog gate | 🟡 | User decision → `/implement` |
| OPT-01: Double-Guard removal | 🟢 | Batch → `/implement` |
| OPT-02: Profile email trgm index | 🟢 | Deferred (scale only) |
| OPT-03: UserGroup Delete endpoint | 🟢 | Batch → `/implement` |

---

## Constraints for Builder (Forge)

- `GEMINI.md`: After adding `user_roles.user_id` migration, use `rtk dotnet ef migrations add`. Never write migration files manually.
- `GEMINI.md`: `TestWebApplicationFactory` — any new admin capability gate requires `PbacDictionaryCache.InitializeAsync()` after seeding in tests (see server/Admin/GEMINI.md).
- `GEMINI.md`: The double-guard pattern (OPT-01) removal must be confirmed by user first — do not remove without approval.
- **Ghost Protocol:** Sentinel does NOT modify production code. All findings above are for Forge to action after user approval.
