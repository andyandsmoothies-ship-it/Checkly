## Input Lineage
- `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260516_135009_A1B2C3D4_pbac_ui.md`

## Smoke Gate Report

| Test Name | Status | Type | Error Summary |
|-----------|--------|------|---------------|
| `GetActionPlans_ReturnsAllowedActionsForStoreManager_WhenOpen` | RED | ✅ Business | `Assert.NotNull() Failure: Value is null` on `allowedActions` |
| `GetActionPlanById_ReturnsAllowedActionsForAuditor_WhenPendingVerify` | RED | ✅ Business | `Assert.NotNull() Failure: Value is null` on `allowedActions` |
| `UpdateActionPlan_SubmitEvidence_RecomputesAllowedActionsInResponse` | RED | ✅ Business | `Assert.NotNull() Failure: Value is null` on `allowedActions` |
| `GetActionPlans_ReturnsEmptyActionsForUserWithoutCapabilities` | RED | ✅ Business | `Assert.NotNull() Failure: Value is null` on `allowedActions` |

### Verdict
- ✅ All failures are Business (expected). The backend does not yet return the `allowedActions` array in the ActionPlan DTOs.

## Test Infrastructure Map

### Helper Methods
| Method | Signature | Behavior |
|--------|-----------|----------|
| `RegisterUserAsync` | `(HttpClient, email, password, name, role)` | Creates a user with the specified role via API. |
| `CreateAuthenticatedClient` | `(string token)` | Returns an HttpClient with the Bearer token. |
| `EnsureDatabaseCreated` | `()` | Wipes and resets the `checkly_test` DB. |

### Seed Data
- **Database**: Fresh `checkly_test` PostgreSQL database, recreated per test run.
- **Roles Used**: `store_manager`, `auditor`, `area_manager`.

### Auth Tokens
- Created dynamically per test via `RegisterUserAsync` to ensure isolated role-testing without global state leakage.

### Expected Response Shapes (Post-Implementation)
```json
// GET /api/action-plans/{id} -> 200 OK
{
  "id": "guid",
  "status": "open",
  "allowedActions": ["view", "submit_evidence"] // <-- Builder must add this field
}
```

## Approved Acceptance Criteria

| Scenario | Given | When | Then |
|----------|-------|------|------|
| **Store Manager Open Actions** | An `open` action plan owned by a `store_manager` with `action_plans:write`. | The user requests `GET /api/action-plans`. | The DTO contains `allowedActions` with `view` and `submit_evidence`, but NOT `verify_close`. |
| **Auditor Verify Actions** | A `pending_verify` action plan linked to a submission owned by an `auditor` with `action_plans:verify`. | The user requests `GET /api/action-plans/{id}`. | The DTO contains `allowedActions` with `view`, `verify_close`, and `reject_evidence`, but NOT `submit_evidence`. |
| **Action Recomputation** | An `open` action plan. | A `store_manager` submits evidence via `PUT /api/action-plans/{id}`. | The API returns the updated DTO with `status: pending_verify` AND `allowedActions` recomputed (loses `submit_evidence`). |
| **Lack of Capabilities (Gap 1)** | A user without `action_plans:write` or `action_plans:verify` on the target plan. | The user requests `GET /api/action-plans`. | The DTO contains `allowedActions` with ONLY `view` (or empty), and NO mutation actions. |
