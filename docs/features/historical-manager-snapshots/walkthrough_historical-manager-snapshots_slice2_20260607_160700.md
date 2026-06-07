# Walkthrough: Historical Manager Snapshots - Slice 2

This walkthrough details the changes made for Slice 2 (API Contract - DTO & Sync Extension).

## Diagrams

```
[EF Core Entity] ---> [DTO Mapping (Endpoint Handlers)] ---> [API Response JSON]
```

## Changes

### 1. Submissions DTOs Extended
- **File**: `server/Features/Submissions/Dtos.cs`
- **Details**: Added `AreaManagerId`, `AreaManagerName`, `StoreManagerId`, and `StoreManagerName` to the `SubmissionDto` and `SubmissionDetailDto` record definitions. Set all four new properties as optional parameters defaulting to `null` to ensure backwards compatibility.

### 2. Endpoint Mapping Updates
- **File**: `server/Features/Submissions/GetSubmission.cs`
  - Mapped `AreaManagerId`, `AreaManagerName`, `StoreManagerId`, and `StoreManagerName` properties from the `submission` entity to the `SubmissionDetailDto`.
- **File**: `server/Features/Submissions/ListSubmissions.cs`
  - Updated the database select projection query to fetch the four snapshot properties.
  - Mapped the projected fields from the query rows onto the instantiations of `SubmissionDto`.
- **File**: `server/Features/Submissions/UpdateSubmission.cs`
  - Passed the snapshot properties from the `submission` entity to the returned `SubmissionDto`.
- **File**: `server/Features/Submissions/FinalizeSubmission.cs`
  - Passed the snapshot properties from the `submission` entity to the returned `SubmissionDto` constructed inside the transaction scope.
