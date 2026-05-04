# Walkthrough: Phase A - create_program_ui

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_161000_p7q8_create_program_ui.md`

## Summary
I have created the unit tests for Phase A: `ProgramApiService.createProgram()` and the `AppCapabilities.programsCreate` constant.
The tests correctly fail to compile because the target method and constant do not exist yet. This ensures that the implementation will satisfy the required contracts.

Tests created:
- TC-01: `createProgram posts correct payload`
- TC-02: `createProgram throws on non-2xx`
- TC-03: `programsCreate constant exists`

## Execution Command
To run these tests and confirm they pass after your implementation, execute:
```powershell
cmd /c rtk flutter test test/features/programs/program_api_service_test.dart
```
