# Checkly Infrastructure & Architecture Audit Report
**Scope:** `server/Features`
**Date:** 2026-05-12

<latent_space_scratchpad>
- Evaluated `HasIndex` and `OnDelete` parameters in EF Core configurations. Identified missing `AssigneeId` index for performance on Program Assignments.
- Scanned for `Take(pageSize)` vs `.ToListAsync()`. Found pagination widely adopted, except for a subset projection in `ListAreas.cs`.
- Traced `RequireAuthorization` application across endpoints mapping (`app.MapGet` vs `app.MapGroup`). Confirmed top-level API guards, but spotted a logical bypass in `SearchUsers.cs` loading inactive user data due to missing Role Claim evaluations.
- Grepped `ILogger` and `SystemLog` adding. Found `SystemLog` in `/Admin` and `/GlobalRisks`, but none in core mutation logic like `CreateStore` or `UpdateProgram`.
</latent_space_scratchpad>

<forensic_evidence>
- Used `view_file` to inspect `ProgramAssignmentConfiguration.cs`, `SearchUsers.cs`, and `GetMyAssignments.cs`.
- Used `run_command` with PowerShell (`Select-String`) as a substitute for `grep_search` to scan all `HandleAsync` endpoints for `LogInformation` and `SystemLog`.
- Used `run_command` to scan configuration files for `OnDelete` policies.
- Used `run_command` to grep `RequireAuthorization` across minimal API route definitions.
</forensic_evidence>

## Assessment Summary

Overall, the server's data querying and authorization structure is solid, employing correct REST abstractions, global minimal API authorization defaults, and deliberate cascading rules in Entity Framework. However, the audit revealed one critical telemetry gap, one performance-bound array missing an index, one minor potential unbounded query, and a PBAC leakage issue.

### 🔴 Critical Findings

#### 1. Mutation Telemetry Gap (Phase 4.5)
- **Finding:** Except for `BanUser` and `GlobalRisks`, state-mutating endpoints (e.g. `CreateStore`, `UpdateSubmission`, `CreateProgram`, `ActionPlans`, etc.) perform no business logging. They rely solely on generic request logs without domain intent tracking (e.g. `ILogger` or `SystemLog` table).
- **Complexity:** Medium (Repetitive but structurally simple) - Adding an `ILogger` implementation or routing to the `SystemLog` sink across all features requires touching multiple files.
- **Trade-offs / Pros & Cons:** 
  - *Pros:* High visibility into who changed what and when, critical for debugging, security audits, and support.
  - *Cons:* Adds boilerplate to otherwise lean minimal API endpoints; increases DB size if stored in `SystemLog`.
- **Actionable Fix:** 
  Introduce an `AuditLogger` service or inject `ILogger<T>` into endpoints:
  ```csharp
  // Example for CreateStore.cs
  logger.LogInformation("Store {StoreId} created by User {UserId}", store.Id, callerId);
  ```

### 🟡 Warning Findings

#### 1. Data Leakage in SearchUsers (Phase 3)
- **Finding:** The `SearchUsers.cs` endpoint has `.RequireAuthorization()` but lacks an internal role gate or capability check. As a result, *any* authenticated app user (even an auditor) could theoretically execute `GET /api/users` to dump a paginated list of all system profiles (including inactive/locked out ones).
- **Complexity:** Low - Requires adding a standard claim extraction and Role authorization guard block to the endpoint handler.
- **Trade-offs / Pros & Cons:**
  - *Pros:* Locks down PII (Personally Identifiable Information) from unauthorized scraping or access.
  - *Cons:* Slightly restricts the API if there are valid non-admin uses for searching users.
- **Actionable Fix:** 
  ```csharp
  var callerRole = user.FindFirstValue(ClaimTypes.Role) ?? "";
  if (callerRole != "admin" && callerRole != "area_manager") // Specify valid roles
      return TypedResults.Forbid();
  ```

#### 2. Potential OOM / Unbounded Query in ListAreas (Phase 2)
- **Finding:** `ListAreas.cs` executes a query to pre-load all profiles with the role "area_manager" (`Where(r => r.Role == "area_manager").ToListAsync()`) into memory before paginating the areas.
- **Complexity:** Low - Fixing this requires using a proper SQL JOIN or adjusting the LINQ to let EF handle the projection automatically without pulling all managers to the App server RAM.
- **Trade-offs / Pros & Cons:**
  - *Pros:* Safeguards memory usage if the application scales to thousands of managers.
  - *Cons:* Requires a slight refactoring of the current dictionary projection pattern which was optimized to avoid N+1 queries.
- **Actionable Fix:**
  Use GroupJoin or LeftJoin natively in EF Core within the `areaQuery`.

#### 3. Missing Index on ProgramAssignment (Phase 2)
- **Finding:** `ProgramAssignmentConfiguration.cs` defines indexes for `(ProgramId, Status)` and `(StoreId, Status)`. However, it lacks an index targeting `AssigneeId`. If the `AssigneeId` query pattern (`Where(a => a.AssigneeId == userGuid)`) runs frequently for task fetching on mobile, it may trigger Seq Scans over time. Note: Current architecture seems to filter based on `StoreId`, but if `AssigneeId` querying is used, it will be slow.
- **Complexity:** Low - Adding a single line to the DB Context config and generating a migration.
- **Trade-offs / Pros & Cons:**
  - *Pros:* Significant speedup for assignee-based fetches.
  - *Cons:* Slightly slower INSERT/UPDATEs and a marginal increase in database storage size.
- **Actionable Fix:**
  ```csharp
  e.HasIndex(x => new { x.AssigneeId, x.Status });
  ```

### 🟢 Optimizations (Cleanups)

#### 1. Soft-Delete Consistency
- **Finding:** Soft deletes are implemented correctly via `.Where(x => x.IsActive == true)`. `SearchUsers.cs` does not filter out banned users (Identity lockout), which is working as intended for Admin visibility, but maybe should explicitly filter if used for assignments.

---
**Status:** Audit complete. Routing Matrix advises treating the `🔴 Telemetry` and `🟡 Data Leakage` as immediate candidates for `/analyze-feature` or `/implement`.
