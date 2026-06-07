---
conversation_id: "b94d1673-00ee-4f82-9a9f-6ec46444aa69"
---

# Design Plan: Double-Layered Historical Manager Snapshots

```text
[Dynamic Permission Layer]
   Current Assignments ──► Controls WHO can edit/view this store's data TODAY

[Static Historical Layer]
   Submission Completed ──► Copy current AM/SM Names + IDs directly to Audit Record (Immutable)
```

This report outlines the steps to transition our store management architecture to a **Double-Layered Design**, preserving historical accountability without breaking dynamic access controls.

---

## 1. Database Schema Changes (EF Core Migration)

We need to add snapshot fields to the `submissions` and `action_plans` tables.

### Submissions Table (`submissions`)
Add the following columns to store the manager context at the exact moment the audit is finalized:
- `AreaManagerId` (Guid, Nullable)
- `AreaManagerName` (string, Nullable)
- `StoreManagerId` (Guid, Nullable)
- `StoreManagerName` (string, Nullable)

### Action Plans Table (`action_plans`)
`ActionPlan` already has `StoreManagerId` and `StoreManagerName`. We need to add the Area Manager counterparts for alignment:
- `AreaManagerId` (Guid, Nullable)
- `AreaManagerName` (string, Nullable)

---

## 2. Backend Logic Changes (Snapshot Ingestion)

When a submission is completed or approved, the backend must resolve and freeze the current store leadership context.

### Lookup Flow (Upon Submission Completion)
1. Get the target `StoreId` of the submission.
2. **Find the current Store Manager**:
   - Query the `Profiles` table where `StoreId == submission.StoreId` and `Role == "store_manager"`.
   - Extract their `Id` and `FullName`.
3. **Find the current Area Manager**:
   - Query the `ProfileStoreAssignments` table for the `StoreId` to get the `ProfileId` of the assigned manager.
   - Look up their `FullName` in the `Profiles` table.
4. **Persist Snapshots**:
   - Write the resolved values to `Submission.StoreManagerId`, `StoreManagerName`, `AreaManagerId`, and `AreaManagerName`.
   - When generating `ActionPlan` entities from failed audit criteria, copy these resolved values over to the new `ActionPlan` records.

---

## 3. Server DTO & API Contract Changes

We must expose these frozen snapshots in the API responses so the client can render the correct historical manager details.

### Updates to `SubmissionDto`
```csharp
public record SubmissionDto
{
    // ... existing fields ...
    public Guid? StoreManagerId { get; init; }
    public string? StoreManagerName { get; init; }
    public Guid? AreaManagerId { get; init; }
    public string? AreaManagerName { get; init; }
}
```

---

## 4. Flutter Frontend UI Rendering

The frontend UI will distinguish between **Current Ownership** and **Historical Ownership**:

- **Audit Detail View & Reports**:
  - Instead of dynamically resolving who the current manager of the store is, display the snapshotted `areaManagerName` and `storeManagerName` from the `SubmissionDto`.
  - Label it clearly: *"Area Manager at completion: [Name]"*.
- **Store Boardroom Analytics / Admin Management**:
  - Keep using the dynamic permissions and assignments for current views and action items.

---

## 5. Verification Checklist

- [ ] Run Entity Framework migration to add columns.
- [ ] Implement manager lookup in `CompleteSubmission` endpoint.
- [ ] Add unit tests verifying that reassigning an Area Manager to a different store does **not** change the `AreaManagerName` snapshot on older completed submissions.
