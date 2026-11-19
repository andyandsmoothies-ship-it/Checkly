# Top 5 Critical Issues Audit

```
[Repository Analysis]
         |
         +--> [1. Security: Hardcoded DB credentials & live connection in test]
         +--> [2. Security: Unprotected Admin buttons in UI (PBAC failure)]
         +--> [3. Infrastructure: AreaBenchmarkWorker not registered in Program.cs]
         +--> [4. Quality: 7 Skipped ATDD Security & Sync tests]
         +--> [5. Data Integrity: PostgreSQL NULL inequality translation risks]
```

## 1. Hardcoded Production DB Credentials in Test Suite
- **Location**: `server/tests/Checkly.Api.Tests/Features/Analytics/BodAnalyticsSlice1Tests.cs:375`
- **Description**: The test method `DumpRealDatabaseContent` directly initializes `AppDbContext` using a hardcoded connection string:
  `Host=localhost;Port=5432;Database=checkly;Username=postgres;Password=Aa1234567@`
- **Risk**: Violates database isolation rules. Targets the development database instead of `checkly_test`. Exposes credentials in source control and triggers unconditional `Assert.Fail()`.
- **Remediation**: Remove debug dump test or redirect to `checkly_test` using `TestWebApplicationFactory`.

---

## 2. Unprotected Admin Action Buttons in Flutter UI
- **Location**:
  - `lib/features/admin/pages/audit_approval_page.dart:95, 141`
  - `lib/features/admin/pages/store_management_page.dart:75`
  - `lib/features/admin/pages/widgets/risk_form_sheet.dart:266, 270`
- **Description**: Automated PBAC scanner `.agents/scripts/verify_pbac_ui.py` flagged 5 interactive buttons without capability guards.
- **Risk**: Violates PBAC architecture. Administrative mutations are exposed in UI without `ActionGuard` or `PermissionGuard` verification.
- **Remediation**: Wrap action triggers in `ActionGuard` bound to entity capabilities or permissions.

---

## 3. Unregistered Background Worker (`AreaBenchmarkWorker`)
- **Location**: `server/Features/Analytics/AreaBenchmarkWorker.cs`
- **Description**: `AreaBenchmarkWorker` implements `BackgroundService` with `DistributedLockManager` to calculate province benchmark snapshots on a periodic timer. The worker is not registered in `server/Program.cs`.
- **Risk**: Province benchmark aggregations will never execute in background runtime.
- **Remediation**: Add `builder.Services.AddHostedService<AreaBenchmarkWorker>();` in `server/Program.cs`.

---

## 4. Skipped ATDD Authorization & Sync Tests
- **Location**:
  - `server/tests/Checkly.Api.Tests/FilteredTemplateSyncTests.cs` (3 skipped)
  - `server/tests/Checkly.Api.Tests/Submissions/SubmissionAllowedActionsTests.cs` (4 skipped)
- **Description**: 7 integration tests are disabled via `[Fact(Skip = "...")]`.
- **Risk**: Critical security behavior (template visibility restricted by user group, allowed actions by role and status) has zero automated test enforcement.
- **Remediation**: Implement missing filter logic and enable tests to complete acceptance verification.

---

## 5. PostgreSQL NULL Inequality Filter Drift
- **Location**: `server/Features/` query handlers filtering nullable columns (e.g. `ReviewStatus`).
- **Description**: PostgreSQL evaluates `NULL != 'rejected'` as `NULL` (false in WHERE clauses). Any EF Core filter written as `s.ReviewStatus != "rejected"` silently excludes records where `ReviewStatus` is `NULL`.
- **Risk**: Unreviewed audits are excluded from aggregation metrics and queue endpoints.
- **Remediation**: Enforce `(s.ReviewStatus == null || s.ReviewStatus != "rejected")` across all query handlers.
