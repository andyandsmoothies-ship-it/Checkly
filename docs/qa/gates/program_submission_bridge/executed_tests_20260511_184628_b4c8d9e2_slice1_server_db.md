# Test Execution Log: Slice 1 — Server DB Migration

**Date:** 2026-05-11
**Slice:** Slice 1 (Program-Submission Bridge)

## Execution Summary
- **Command:** `rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj`
- **Total Tests:** 471
- **Passed:** 471
- **Failed:** 0
- **Skipped:** 0

## Findings & Changes
- Deleted tests associated with the deprecated `ProgramEvidence` and `SubmitEvidenceRequest` models, as the corresponding endpoints have been drain-guarded to return `410 Gone`.
- Modified `Program_Slice2A_Tests.cs` and `Program_Slice3_Tests.cs` to remove assertions on the deprecated `evidenceItems` list and deprecated endpoints.
- Integration tests successfully compiled and ran after schema migration (`ProgramEvidence` drop, `Submission` foreign key addition), indicating no unintended breakage of existing features.
