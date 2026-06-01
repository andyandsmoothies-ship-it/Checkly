---
conversation_id: "e806043a-d178-457b-b974-d1e2c68fce54"
type: "walkthrough"
topic: "smart-audit-safeguards-slice2-walkthrough"
timestamp: "2026-05-31T19:50:00"
---

# Walkthrough: Smart Audit Safeguards - Slice 2

```text
  [Client App] ──► [CreateSubmission / FinalizeSubmission] ──► [Submission Entity] ──► [PostgreSQL]
        ▲                             │                                 │                    │
        │                             ▼                                 ▼                    ▼
  [SubmissionDto] ◄────── [List / Get / Update] ◄────────────── [EF DbContext] ◄─────────────┘
```

This walkthrough outlines the exact changes made and verified in **Slice 2** of the **Smart Audit Source Safeguards** epic, which enables complete end-to-end flow of geofence telemetry (`IsGeofenceBypassed` and `DistanceMetersOff`) from API request payloads through handlers to direct PostgreSQL database persistence and обратно onto client responses.

---

## 1. Mapped Changes Walkthrough

### 1.1. DTO Record Classes
In `server/Features/Submissions/Dtos.cs`, we expanded:
- **`CreateSubmissionRequest`**: Added optional parameters `bool? IsGeofenceBypassed = null` and `int? DistanceMetersOff = null`.
- **`SubmissionDto`**: Added matching fields for returned lists, single entities, and updates.
- **`SubmissionDetailDto`**: Added matching fields for full single-audit details.

### 1.2. Mappings and Persistence
We updated the following API endpoints to properly map the incoming and outgoing fields:
1. **`CreateSubmission.cs`**:
   - Mapped request fields to `Submission` entity before saving.
   - Restored properties in the returned `SubmissionDto` representation.
2. **`FinalizeSubmission.cs`**:
   - Expanded the `FinalizeRequest` contract.
   - Assigned the geofence parameters to the DB entity on status completion.
   - Retained parameters in the returned `SubmissionDto`.
3. **`GetSubmission.cs`**:
   - Projected the database columns onto `SubmissionDetailDto` when querying a single record.
4. **`ListSubmissions.cs`**:
   - Projected columns through `.Select` to retrieve the database values without extra memory allocations or N+1 queries.
   - Projected values into mapped `SubmissionDto` instances.
5. **`UpdateSubmission.cs`**:
   - Projected fields onto `SubmissionDto` during post-save mapping.

---

## 2. Automated Quality Gates

All checks compile and execute with **zero warnings** and **zero errors**:

- **Compilation check**: `rtk dotnet build` ──► 🟢 **0 errors, 0 warnings**
- **Test execution**: `rtk dotnet test` ──► 🟢 **All tests pass**

---

## 3. Verification & Resiliency Proofs
Three new robust integration tests were implemented and run in `SmartAuditSafeguards_Slice2_Tests.cs`:
1. `CreateSubmission_WithGeofenceTelemetry_PersistsAndReturnsFields`
2. `GetSubmission_WithGeofenceTelemetry_ReturnsCorrectFields`
3. `CreateSubmission_OmitGeofenceTelemetry_SavesNullsSuccessfully`

These tests verify correct field mapping, PostgreSQL database storage, and null-safety resiliency for older client payloads. Refer to [green_test_log_smart-audit-safeguards-slice2_20260531_195000.md](file:///c:/Users/HP/Documents/GitHub/Checkly/docs/reports/qa/smart-audit-safeguards/green_test_log_smart-audit-safeguards-slice2_20260531_195000.md) for full execution results.
