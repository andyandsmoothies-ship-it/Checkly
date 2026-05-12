# Walkthrough: Program Submission Bridge (Slice 3 - Flutter Sync Rewire)

## Overview
This walkthrough summarizes the implementation of Slice 3, which focused on finalizing the transition from the legacy evidence outbox to the new standard audit workflow. The changes align the Flutter client with the backend's migration.

## Architectural Changes

### 1. Schema Migration (v25 → v26)
*   **Table Removal**: Dropped the legacy `PendingProgramSubmissions` and `PendingProgramPhotos` tables.
*   **Schema Extension**: Added `templateId` (nullable) to the `CachedProgramAssignments` table. This field is critical for wiring the assignment to the standard `AuditFormPage` in Slice 4.
*   **Migration Scripts**: Wrote the `from == 25` to `26` migration step with explicit `customStatement('DROP TABLE ...')` commands. Cleaned up the legacy `v23` creation block in `app_database.dart` so it no longer builds dropped tables.
*   **Code Generation**: Ran `flutter pub run build_runner build` to regenerate `app_database.g.dart`.

### 2. Dead Code Elimination
*   **Sync Layer**: Purged `_drainProgramEvidence()` and `_drainProgramPhotos()` logic from `ProgramSyncModule`.
*   **Data Access Layer**: Removed the corresponding methods from `ProgramOutboxDao` to prevent ghost reads/writes to non-existent tables.
*   **API Client**: Stripped `pushProgramEvidence()` and `pushProgramPhoto()` from `SyncApi` and `SyncApiAdapter`.
*   **Manager State**: Deleted the `submitEvidence` mutation method from `ProgramManager` to enforce an intentional breakage of the legacy pipeline.

### 3. DTO Mapping & UI Preparation
*   **DTO Update**: Exposed `templateId` on `ProgramAssignmentDto`.
*   **Sync Logic**: Updated `ProgramSyncModule._pullProgramAssignments()` to map the `templateId` from the backend JSON response into the local Drift cache.
*   **UI Stubbing**: In `ProgramExecutionPage`, the `_handleSubmit` logic was updated to display a temporary "disabled for updates" `SnackBar` to prevent errors while waiting for the upcoming Slice 4 UI rewiring.

## Verification
*   Executed the full `flutter test` suite.
*   Resolved an invocation signature error in `test/features/programs/program_execution_needs_revision_test.dart` by initializing the DTO with the newly required `templateId`.
*   Final output: **All 495 tests passed.**
*   Code was verified and normalized via `dart format` and `flutter analyze`.
