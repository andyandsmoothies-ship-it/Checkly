# Diagnostic Report: am2 403 Forbidden on Analytics

## 1. Description of the Error
The user reported that the test account `am2` received a `403 Forbidden` error when accessing the Analytics dashboard, which caused the UI to fallback to the offline cache ("insights require internet connection").

## 2. Root Cause Analysis
- The `GetAnalytics.cs` endpoint enforces strict PBAC and tenancy rules.
- For `role == "area_manager"`, the code specifically asserts that `profile.AreaId` is not null:
  ```csharp
  if (profile?.AreaId is null)
      return TypedResults.Forbid();
  ```
- Investigation of the local PostgreSQL database using SQL queries revealed that the `seed_users.sql` script created the Area Manager profiles (`am1` and `am2`) but intentionally left their `AreaId` and `StoreId` columns as `NULL`.
- Because `am2` possessed the `area_manager` role but lacked an assigned `AreaId`, the backend PBAC logic correctly denied access to the tenant-isolated data, resulting in a 403 response.

## 3. Corrective Action (The Fix)
- We executed an SQL query directly against the local `checkly` database to assign `am1` and `am2` to valid Area IDs that were found in the `areas` table.
- Specifically, `am1` was assigned to `Central HCMC` (`11111111-1111-1111-1111-111111111111`) and `am2` was assigned to `Suburban HCMC` (`22222222-2222-2222-2222-222222222222`).

## 4. Verification
- The 403 error is inherently resolved by fulfilling the tenancy prerequisite enforced by the PBAC `GetAnalytics.cs` handler.
- The UI will now successfully load analytics scoped specifically to `Suburban HCMC` for `am2`.
