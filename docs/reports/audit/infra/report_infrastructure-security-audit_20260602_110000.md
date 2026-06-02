---
ConversationID: 99faccbc-6112-4ccd-aea4-306dbdfd3452
---

# Infrastructure, Database & Security Audit Report

This report presents a thorough analysis of the database configurations, query performance, security authorization guards, and audit logs for Checkly.

```
 [Flutter Offline App]
         │ (Syncs Local DB tables to Backend via API)
         ▼
 ┌───────────────┐
 │  ASP.NET API  │ ──(Enforces PBAC Capability Guards & logs mutations)
 └───────────────┘
         │ (Queries & persists data using Entity Framework Core)
         ▼
 ┌───────────────┐
 │ PostgreSQL DB │ ──(Enforces Unique Indexes & Cascades)
 └───────────────┘
```

---

## 📋 Audit Checklist Progress (@@SCAN)

### 1. Database & Query Audit
- **Unbounded queries count**: **0**. Standard list endpoints (e.g. `ListStores`, `ListUsers`, `ListSystemLogs`) have pagination with safe page size clamps. `SearchUsers` has a limit clamp of `.Take(100)`.
- **Missing indexes**: **2 identified**. The `system_logs` table lacks indexes on `trace_id` and `user_email` despite being queryable fields in `ListSystemLogs.cs`.
- **Delete strategy aligned**: **Yes**. Foreign key relationships on `submissions` and `profiles` use `DeleteBehavior.SetNull`, preventing cascading wipes of historical audits when metadata is deleted.

### 2. Security & Data Integrity
- **Endpoints missing auth guards**: **0**. Every mutation and read group enforces authorization.
- **Deactivated entities loaded**: **No**. `ListStores` filters by `IsActive == true` by default.
- **Data leakage risks**: **No**. Scoping queries automatically filter stores and assignments based on the caller's role (Auditor vs. Store Manager vs. Area Manager).

### 3. Telemetry & NFR Check
- **Missing logs on mutations**: **1 identified**. `CreateUser.cs` lacks code to write to `system_logs` or `AuditLogger`.
- **Missing resilience handlers**: **No**. All major sync operations and external queries are protected.

---

## 🔍 Detailed Findings & Actionable Fixes

### Finding 1: Missing Mutation Logging in User Creation (`🟡 Warning`)
* **File**: `server/Features/Admin/CreateUser.cs`
* **What it lacks**: Every mutation endpoint in the admin module (`UpdateUser`, `BanUser`, `TransferStoreManager`) logs actions into the `system_logs` table. However, `CreateUser.cs` saves the user but does not insert a log record into the database.
* **Risk if not fixed**: Admin creation actions are untrackable, creating a blind spot in compliance logs.
* **Complexity**: **Low**. Adding a logging block identical to `BanUser.cs` requires minimal effort.

#### Exact Fix Proposal
```diff
             db.AppUserRoles.Add(userRole);
 
             if (request.Role == "area_manager" && request.AssignedStoreIds is not null)
             {
                 // ... (code omitted for brevity)
                 db.ProfileStoreAssignments.AddRange(newAssignments);
             }
 
+            // Log the admin action
+            db.SystemLogs.Add(new SystemLog
+            {
+                Id = Guid.NewGuid(),
+                UserId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!),
+                Action = "create_user",
+                Category = "admin",
+                EntityType = "user",
+                EntityId = appUser.Id,
+                Message = $"Created user {profile.FullName} ({profile.Email}) with role {request.Role}",
+                Path = "/api/admin/users",
+                Level = "info",
+                CreatedAt = DateTimeOffset.UtcNow,
+            });
+
             await db.SaveChangesAsync(ct);
         }
```

* **Complexity Rationale**: This is a direct injection of a standard Logging database write inside an existing `try-catch` transaction block.
* **Trade-offs / Pros & Cons**:
  * *Pros*: Completely eliminates the compliance audit gap; maintains structural symmetry with other admin endpoints.
  * *Cons*: Adds a minor database write overhead on user creation (extremely negligible as user creation is an infrequent administrative action).

---

### Finding 2: Missing Performance Indexes on `system_logs` (`🟢 Optimization`)
* **File**: `server/Common/Persistence/Configurations/SystemLogConfiguration.cs`
* **What it lacks**: The table `system_logs` has indexes on `created_at` and the composite `(entity_type, entity_id)`. However, the endpoint `ListSystemLogs.cs` allows filtering by `trace_id` and `user_email`. As system logs grow to millions of rows, querying these unindexed fields causes slow sequential table scans.
* **Risk if not fixed**: Slower performance on the Admin Log screen when filtering by Trace ID or Email.
* **Complexity**: **Low**. Requires updating the EF Core configuration file and running a database migration.

#### Exact Fix Proposal
Add performance indexes to `SystemLogConfiguration.cs`:
```diff
         // Performance indexes
         e.HasIndex(x => x.CreatedAt).IsDescending();
         e.HasIndex(x => new { x.EntityType, x.EntityId });
+        e.HasIndex(x => x.TraceId).HasFilter("trace_id IS NOT NULL");
+        e.HasIndex(x => x.UserEmail).HasFilter("user_email IS NOT NULL");
```

* **Complexity Rationale**: Adding a standard single-column index with a null filter is a highly safe, standard database operation in EF Core.
* **Trade-offs / Pros & Cons**:
  * *Pros*: Dramatically speeds up log searches when troubleshooting specific system errors (Trace ID) or user behaviors.
  * *Cons*: Marginally increases database size and writes duration on new log insertions.

---

### Finding 3: Missing Pagination on Search Users API (`🟢 Optimization`)
* **File**: `server/Features/Users/SearchUsers.cs`
* **What it lacks**: `SearchUsers.cs` uses a hard ceiling `.Take(100)` to prevent OOM errors. However, if there are more than 100 matching users, there is no way for the UI to query or display the remaining matches.
* **Risk if not fixed**: Users matching the search criteria beyond the 100th row are unreachable.
* **Complexity**: **Medium**. Requires refactoring the return type to a paged result schema.

#### Exact Fix Proposal
Adopt the same pagination pattern used in `ListUsers.cs`:
```diff
-        var users = await query
-            .OrderBy(x => x.p.FullName)
-            .Take(100)
-            .Select(x => new SimpleUserDto
-            {
-                Id = x.p.Id,
-                FullName = x.p.FullName,
-                Email = x.p.Email,
-                Role = x.r.Role,
-                StoreId = x.p.StoreId != null ? x.p.StoreId.ToString() : null
-            })
-            .ToListAsync(ct);
-
-        return TypedResults.Ok(new { items = users });
+        var page = int.TryParse(httpContext.Request.Query["page"], out var pg) ? Math.Max(1, pg) : 1;
+        var pageSize = int.TryParse(httpContext.Request.Query["pageSize"], out var ps) ? Math.Clamp(ps, 1, 100) : 50;
+
+        var total = await query.CountAsync(ct);
+        var users = await query
+            .OrderBy(x => x.p.FullName)
+            .Skip((page - 1) * pageSize)
+            .Take(pageSize)
+            .Select(x => new SimpleUserDto
+            {
+                Id = x.p.Id,
+                FullName = x.p.FullName,
+                Email = x.p.Email,
+                Role = x.r.Role,
+                StoreId = x.p.StoreId != null ? x.p.StoreId.ToString() : null
+            })
+            .ToListAsync(ct);
+
+        return TypedResults.Ok(new PagedResult<SimpleUserDto>(users, total, page, pageSize));
```

* **Complexity Rationale**: Modifies endpoint return contracts, which requires making sure any consumer (e.g. Flutter mobile service) parses the nested `PagedResult` structure instead of a raw list.
* **Trade-offs / Pros & Cons**:
  * *Pros*: Enables infinite scrolling or paginated searching for stores or area assignments inside administrative forms.
  * *Cons*: Breaks direct compatibility with older Flutter call sites that expect `{ items: [...] }` without the paging metadata wrapper.

---

## 🚀 Recommendation & Next Actions

1. **User Approval**:
   - We recommend implementing **Finding 1** (`CreateUser` Logging) immediately.
   - We recommend batching **Finding 2** (Indexes) in the next scheduled database migration cycle.
   - We recommend postponing **Finding 3** until a client-side rewrite is requested to avoid interface contract drift.

2. **Next Steps**:
   - Awaiting user approval to run the verification gate and hand off.
