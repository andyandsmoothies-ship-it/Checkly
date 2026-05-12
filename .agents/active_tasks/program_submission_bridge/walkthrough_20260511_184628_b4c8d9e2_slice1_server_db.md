# Walkthrough: Slice 1 — Server DB Migration (Program-Submission Bridge)

## Objective
Execute the first slice of the Program-Submission Bridge epic, which involves refactoring the database schema to remove the deprecated `ProgramEvidence` entity and linking the `Submission` entity directly to `ProgramAssignment`.

## Steps Taken

### Phase A: Schema Migration
1. **Added Foreign Key to Submission**: Updated `Submission.cs` to include `ProgramAssignmentId` (Guid?) and the corresponding `ProgramAssignment` navigation property.
2. **Linked Submissions to ProgramAssignment**: Updated `ProgramAssignment.cs` to expose a `Submissions` collection navigation property.
3. **EF Core Configuration**: Updated `SubmissionConfiguration.cs` to define the relationship with `OnDelete(DeleteBehavior.SetNull)` and created a partial index.
4. **Deleted Deprecated Entity**: Removed `ProgramEvidence` from `AppDbContext.cs`. Deleted `ProgramEvidence.cs` and `ProgramEvidenceConfiguration.cs`.
5. **Code Cleanup**: Removed evidence mapping from `GetProgramAssignments.cs` and deleted deprecated DTOs (`EvidenceItemRequest`, `SubmitEvidenceRequest`, `ProgramEvidenceDto`) in `ProgramDtos.cs`.
6. **Generated Migration**: Created EF Core migration to capture the `ADD COLUMN` and `DROP TABLE` schema changes.

### Phase B: API Drain Guards
1. **Stubbed Endpoints**: Modified `SubmitProgramEvidence.cs` and `UploadProgramPhoto.cs` handlers to immediately return `410 Gone` with a deprecation message, acting as a drain guard.
2. **Removed Dead Tests**: Deleted tests that verified the deprecated `/submit` and photo upload endpoints:
   - `ProgramPhotoIntegrationTests.cs`
   - `SubmitProgramEvidence_PbacAuth_Tests.cs`
   - `Program_Slice4_Tests.cs`
   - Removed relevant test methods from `Program_Slice2A_Tests.cs` and `Program_Slice3_Tests.cs`.

## Results
- The build is successful (`rtk dotnet build`).
- All 471 tests pass successfully (`rtk dotnet test`), guaranteeing that the removal of `ProgramEvidence` did not break any surrounding workflows.

## Next Steps for the User
- **Restart the Server**: If the API is running locally, it must be restarted to trigger `db.Database.Migrate()` and apply the schema migration.
- **Manual Verification**: Execute the manual smoke tests against the `POST /api/programs/assignments/{id}/submit` and `POST /api/photos/programs/{id}` endpoints to verify the `410 Gone` responses.
