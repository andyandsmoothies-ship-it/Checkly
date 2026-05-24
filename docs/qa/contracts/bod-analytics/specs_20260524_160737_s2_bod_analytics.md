# Technical Specification & Mapping: BOD Analytics Slice 2 API Gateway

This document bridges the Gherkin contracts with our .NET xUnit integration test suite located at `Checkly.Api.Tests`.

## Test Infrastructure Map

### Helper Methods
All test cases utilize `TestWebApplicationFactory` to instantiate authenticating clients:

| Role / Capability | Auth Type | Intended Client Utility / Method |
|---|---|---|
| Admin | Bearer JWT | `CreateAuthenticatedClientAsync(roles: ["admin"])` |
| Auditor | Bearer JWT | `CreateAuthenticatedClientAsync(roles: ["auditor"])` |

### Database Seeding & Mocking
- Test database: PostgreSQL logical separation (`checkly_test`).
- Mocking: We use `mocktail` equivalent/standard xUnit mocking for background services if needed, but since we are running full-system integration tests, we will instantiate a real `TestWebApplicationFactory` database state.
- Dynamic DB querying: Using `db.Set<BodReportSnapshot>()` to avoid entity property name drift.

## Endpoint Mappings under Test

- **GET `/api/analytics/bod`** -> Exposes `GetBodReport.HandleAsync`
- **POST `/api/analytics/bod/refresh`** -> Exposes `RefreshBodReport.HandleAsync`

---

## Smoke Gate Report (Initial State)

| Test Name | Status | Type | Error Summary |
|-----------|--------|------|---------------|
| `GetBodReport_AsAdmin_ReturnsSuccessAndPayload` | RED | ✅ Business | Endpoint not registered |
| `GetBodReport_AsAuditor_ReturnsForbidden` | RED | ✅ Business | Route not registered |
| `GetBodReport_EmptyDatabase_ReturnsNotFound` | RED | ✅ Business | Route not registered |
| `RefreshBodReport_AsAdmin_TriggersRefresh` | RED | ✅ Business | Route not registered |
| `RefreshBodReport_AsAuditor_ReturnsForbidden` | RED | ✅ Business | Route not registered |
| `RefreshBodReport_RateLimitsConsecutiveRequests` | RED | ✅ Business | Route not registered |
| `RefreshBodReport_ConcurrentTriggers_RespectsLock` | RED | ✅ Business | Route not registered |

### Verdict
- ❌ All tests are currently RED because the endpoint, mapping, rate-limiting worker methods, and DI registrations do not exist yet. This is the **correct and expected RED state** for our TDD/ATDD workflow.
