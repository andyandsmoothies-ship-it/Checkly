# Failure Report: Registration failed (Forbidden) in dotnet tests
**ID**: failure_report_20260521_163200_f3a1b800_registration_forbidden
**Date**: 2026-05-21
**Severity**: CRITICAL — 111/524 tests blocked

---

## Input Lineage
- **Source**: `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\store_address_required\task_20260521_162700_f3a1b800_qa_verify_slice1.md`
- **Trigger**: `rtk dotnet test tests/Checkly.Api.Tests/` — Exit code 1

---

## Symptom
```
System.Exception: Registration failed (Forbidden):
  at TestWebApplicationFactory.RegisterUserAsync(...) line 211
```
111 out of 524 tests fail with this same error. All failures are in tests that call `RegisterUserAsync` with a non-auditor role (e.g., `store_manager`, `area_manager`) **without** passing an `adminToken`.

---

## Root Cause

**File**: `server/Features/Auth/Register.cs` — lines 25-45

The register endpoint has `CRIT-01` security rule: only users with the `auditor` role may self-register anonymously. All other roles (`admin`, `store_manager`, `area_manager`) require an existing admin JWT in the `Authorization` header.

```csharp
// Line 26
private static readonly HashSet<string> AnonymousAllowedRoles = ["auditor"];

// Lines 39-45
if (!AnonymousAllowedRoles.Contains(request.Role))
{
    var callerRole = httpContext.User.FindFirst(ClaimTypes.Role)?.Value;
    if (callerRole != "admin")
        return TypedResults.Forbid(); // ← 403 returned here
}
```

**File**: `server/tests/Checkly.Api.Tests/TestWebApplicationFactory.cs` — line 192-200

`RegisterUserAsync` calls `/api/auth/register` using a plain `HttpClient` — no `Authorization` header — when `adminToken` is not explicitly passed by the calling test:

```csharp
public async Task<(string Token, Guid UserId)> RegisterUserAsync(
    HttpClient client, string email, string password, string fullName, string role,
    string? adminToken = null)  // ← Most tests pass null here
{
    var request = new HttpRequestMessage(HttpMethod.Post, "/api/auth/register")
    { Content = JsonContent.Create(new { email, password, fullName, role }) };

    if (adminToken is not null)
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);
    // ← When adminToken IS null and role is NOT "auditor": 403 is guaranteed
```

---

## Proposed Scope-Limited Fix

**Location**: `TestWebApplicationFactory.cs` — `RegisterUserAsync` method only.

**Change**: When `adminToken` is `null` AND role is not `"auditor"`, auto-fetch a bootstrap admin token before sending the register request. This is a 3-line change inside the existing helper.

```csharp
// Before sending the request, auto-elevate if needed
if (adminToken is null && role != "auditor")
    adminToken = await LoginBootstrapAdminAsync(client);

if (adminToken is not null)
    request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);
```

### Trade-offs

| | Pros | Cons |
|--|------|------|
| **Auto-elevate (RECOMMENDED)** | Zero test changes required. All 111 tests recover. Matches developer intent (they expected this to work). | Adds one extra login HTTP call per test that needs it. Negligible performance impact. |
| **Update each test manually** | Explicit admin token in every test — clear intent. | 111+ tests need editing. High blast radius, high risk of missing one. |

**Recommendation**: Auto-elevate inside `RegisterUserAsync`. This is the lowest blast radius fix — 1 file, 3 lines.

---

## Explicit Code Trace (Premises + Proof)

1. `Test calls RegisterUserAsync(client, "user@test", ..., "store_manager")` — no adminToken.
2. `RegisterUserAsync` line 197: `if (adminToken is not null)` → **FALSE** → no Authorization header set.
3. `POST /api/auth/register` reaches `Register.cs` line 39: `role = "store_manager"` NOT in `AnonymousAllowedRoles`.
4. Line 41: `callerRole = httpContext.User.FindFirst(Role)?.Value` → **null** (no JWT).
5. Line 42: `null != "admin"` → **TRUE** → `return TypedResults.Forbid()` → 403.
6. `RegisterUserAsync` line 208-211: `!response.IsSuccessStatusCode` → **TRUE** → throws `Exception("Registration failed (Forbidden)")`.

---

<forensic_evidence>
- Executed: `rtk dotnet test tests/Checkly.Api.Tests/` → Exit code 1, 111 failures
- Executed: `view_file TestWebApplicationFactory.cs lines 190-227` → confirmed no auto-elevation
- Executed: `view_file Register.cs` → confirmed CRIT-01 rule: only auditor self-registers
- Executed: `grep_search "users:create"` → 0 results (capability not used, pure role check)
</forensic_evidence>

---

## Handoff Block

**Verdict**: CONFIRMED ROOT CAUSE — Test infrastructure gap.
- The `CRIT-01` security rule in `Register.cs` is correct and must NOT be changed.
- The fix belongs **entirely inside `TestWebApplicationFactory.RegisterUserAsync`**.
- **Blast radius**: 1 file, 3 lines inserted. Zero production code changes.

**AI Agent Mission Brief**: `TestWebApplicationFactory.RegisterUserAsync` does not auto-fetch an admin token when registering non-auditor roles. Add a 3-line guard before the request loop: `if (adminToken is null && role != "auditor") adminToken = await LoginBootstrapAdminAsync(client);`

## Execution Queue
- [ ] Builder: Apply the 3-line fix to `server/tests/Checkly.Api.Tests/TestWebApplicationFactory.cs` inside `RegisterUserAsync`.
- [ ] Builder: Run `cmd /c rtk dotnet test tests/Checkly.Api.Tests/` and confirm 0 failures.
- [ ] QA: Re-run `/verify` on the store address slice after the fix.
