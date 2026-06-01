---
conversation_id: dcbfac81-a3e9-4fad-af42-bc281b403b75
created_at: 2026-05-31T20:15:00+07:00
topic: bod-analytics-v2
type: diagnostics
---

# BOD Analytics V2 Catch-Flops Diagnostics Audit Report

This report presents the security, calculation, offline sync, and layout diagnostics for the **BOD Analytics V2** epic.

## 1. System Logic Flow

The following diagram maps the access flow and the multi-role security guard:

```text
[Store/Area Manager] ──► [GET /api/analytics/stores/{id}/bod-summary]
                                 │
                                 ├──► Checks ClaimsPrincipal for AnalyticsBod capability
                                 ├──► If lacking Admin, matches storeId to Profile.StoreId
                                 └──► Enforces strict tenancy (403 if mismatch)
```

---

## 2. Identified Flops & Risks

### Risk 1: Insecure Direct Object Reference (IDOR) on GetStoreBodSummary
- **Severity**: 🔴 Critical
- **Details**: The endpoint `/api/analytics/stores/{storeId}/bod-summary` receives `storeId` but lacks a check for the calling user's assigned store(s). Any user with the `AnalyticsBod` capability can view the BOD summary of any store in the system.
- **System Impact**: Store Managers can access other stores' data, violating multi-tenant boundaries.
- **Remediation**: Insert a role-scoped tenancy check matching `profile.StoreId` for Store Managers and checking `ProfileStoreAssignments` for Area Managers.

### Risk 2: Missing Capability Constant in AppCapabilities.cs
- **Severity**: 🟡 Warning
- **Details**: `AppCapabilities.cs` comments reserve `AnalyticsArea = "analytics:area"` for future implementation, but the static string field is missing.
- **System Impact**: Endpoint or frontend code requiring `"analytics:area"` cannot use a static constant, leading to risky magic string usage.
- **Remediation**: Add `public const string AnalyticsArea = "analytics:area";` to `AppCapabilities.cs`.

### Risk 3: Empty Store Section Scores and Divide-by-Zero Protection
- **Severity**: 🟢 Low
- **Details**: When calculating category averages, if a store has no completed audits, `categoryBreakdownRaw` can be empty.
- **System Impact**: Possible calculation anomalies or empty displays.
- **Remediation**: Ensure calculations have safe fallback logic to return empty collections instead of throwing exceptions.

---

## 3. Action Plan

1. **Implement IDOR Tenancy Guard**: Add role and assignment checks in `GetStoreBodSummary.cs` mimicking `GetStoreDashboard.cs`.
2. **Add Missing Constant**: Add `AnalyticsArea` constant to `AppCapabilities.cs`.
3. **Verify via Tests**: Run the full suite of integration tests to prove that the guard blocks unassigned access and allows authorized access.
