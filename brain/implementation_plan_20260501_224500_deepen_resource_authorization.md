# Implementation Plan: Deepen Resource Authorization (Secure Query Extensions)

## Objective
Replace the fragmented and unoptimized `SubmissionAccessGuard.cs` and `OwnershipScopeFilter.cs` with a single, highly performant `IQueryable` extension. The new architecture translates the role hierarchy logic into a single EF Core expression tree, pushing the security check entirely into PostgreSQL.

## Architectural Changes (The Seam & Adapter)
1. **The Seam (Extension Method)**: `ApplyReadSecurity(Guid userId)` — An extension method on `IQueryable<Submission>` (and any other entities mapped to Stores/Areas) that callers must append to their queries.
2. **The Adapter (Expression Tree)**: `SecurityQueryExtensions` — Internally uses LINQ joins to cross-reference the `Profiles` and `AppUserRoles` tables against the entity's `StoreId`, `AreaId`, or `AuditorId` without ever materializing intermediate results into memory.

## Migration Strategy
1. Introduce `server/Common/Security/SecurityQueryExtensions.cs`.
2. Migrate `ListSubmissions.cs` to use the new extension instead of `OwnershipScopeFilter`.
3. Migrate `GetSubmission.cs` (or another handler using `SubmissionAccessGuard`) to use the new extension.
4. Mark `SubmissionAccessGuard.cs` and `OwnershipScopeFilter.cs` as `[Obsolete("Use SecurityQueryExtensions.ApplyReadSecurity instead.")]`.

## Proposed Changes

### 1. `server/Common/Persistence/Entities/RoleCapability.cs` [MODIFIED]
- **Change**: Add `public string DataScope { get; set; } = "Global";` (or an Enum: `Global, Area, Store, Self`).
- **Change**: Run an EF Core migration (`rtk dotnet ef migrations add AddDataScopeToRoleCapabilities`) and update the seed data in `AppDbContext` to populate `DataScope` for existing rows.

### 2. `server/Common/Security/SecurityQueryExtensions.cs` [NEW]
```csharp
using System.Linq;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Common.Security;

public static class SecurityQueryExtensions
{
    /// <summary>
    /// Applies row-level security directly inside the SQL execution plan.
    /// Validates that the user has the required PBAC capability, and applies 
    /// the appropriate hierarchical filter based on the capability's DataScope.
    /// </summary>
    public static IQueryable<Submission> ApplySubmissionSecurity(
        this IQueryable<Submission> query, 
        Guid userId, 
        string requiredCapability,
        AppDbContext db)
    {
        return from s in query
               join p in db.Profiles on userId equals p.Id
               join ur in db.AppUserRoles on p.Id equals ur.UserId
               join rc in db.RoleCapabilities on ur.Role equals rc.Role
               where rc.Capability == requiredCapability
               where
                   (rc.DataScope == "Global") || 
                   (rc.DataScope == "Self" && s.AuditorId == userId) ||
                   (rc.DataScope == "Store" && s.StoreId == p.StoreId) ||
                   (rc.DataScope == "Area" && s.StoreId != null && 
                    db.Stores.Any(store => store.Id == s.StoreId && store.AreaId == p.AreaId))
               select s;
    }
}
```

### 3. Handlers using `OwnershipScopeFilter` [MODIFIED]
- **Target**: Handlers like `ListSubmissions.cs`
- **Change**: Remove `OwnershipScopeFilter.ApplyAsync` and replace with `.ApplySubmissionSecurity(userId, AppCapabilities.SubmissionsList, db)`.

### 4. Handlers using `SubmissionAccessGuard` [MODIFIED]
- **Target**: Handlers like `GetSubmission.cs`
- **Change**: Pre-filter the retrieval query: `await db.Submissions.ApplySubmissionSecurity(userId, AppCapabilities.SubmissionsList, db).FirstOrDefaultAsync(...)`.
- **Contract Change**: Unauthorized lookups return `404 Not Found`.

### 5. `SubmissionAccessGuard.cs` and `OwnershipScopeFilter.cs` [MODIFIED]
- **Change**: Add `[Obsolete]`.

## Risk Assessment
- **Severity**: Medium. Modifying the core IDOR gate requires strict testing. However, since the logic perfectly mirrors the existing `switch` statement but translates it to SQL, structural correctness is maintained.
- **Blast Radius**: High (within the Submissions module). Modifying the read path for Submissions affects list endpoints, exports, and single-item fetches.
- **Contract Impact**: Callers querying a forbidden ID will receive `404 Not Found` instead of `403 Forbidden`. This is a standard security best practice (opaque resource existence) but may require minor adjustments to frontend or test expectations if they specifically asserted `403`.

## Verification Plan
1. Recompile the server to ensure extension methods resolve.
2. Run `rtk dotnet test server/tests --filter SubmissionAccessGuardUnitTests` (these might fail if they mock the DbContext in-memory, requiring actual integration tests).
3. Run `rtk dotnet test server/tests --filter Submission` to prove that all existing integration tests (which run against a real Postgres DB in `TestWebApplicationFactory`) still pass with the new SQL translations.
4. Verify that `403` assertions in existing ATDD tests are properly transitioned to `404` assertions if necessary.
