# Walkthrough: Campaign Dashboard Phase C Implementation

## 1. Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260513_234747_SYN01_campaigns.md`
- `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\campaign\task_20260514_091500_CMP_phase_c_button.md`

## 2. Decision Log
- **Proposed**: The ADR required adding a massive, primary `[ + New Campaign ]` button directly to the `AdminActiveCampaignsWidget` on the dashboard, opening the Campaign Creation flow.
- **Implemented**: 
  - Added the `[ + New Campaign ]` button to the bottom of the `AdminActiveCampaignsWidget`.
  - Wrapped it in `PermissionGuard` requiring the `AppCapabilities.programsCreate` capability, adhering to the project's PBAC standards.
  - Adjusted the layout to stretch across the dashboard column and ensure it is still visible even if the active campaigns list is currently empty, rendering an inviting empty state instead of silently collapsing.

## 3. Verification Handoff
- **QA Verification**: 
  1. Log in as an Admin.
  2. Scroll down on the Dashboard to the Active Campaigns section.
  3. Verify the `[ + New Campaign ]` button is clearly visible.
  4. Tap the button and verify it routes correctly to the Campaign Creation wizard (`/programs/new`).
  5. Log in as a role *without* `programsCreate` capability (e.g., standard Auditor). Verify the button is hidden securely via `PermissionGuard`.

## <test_trace>
```
00:59 +495: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: (tearDownAll)
00:59 +495: All tests passed!

Exit code: 0
```

## <forensic_evidence>
```
cmd /c rtk flutter analyze (lib/)
Analyzing lib...                                                

warning - The field doesn't override an inherited getter or setter - _shared\database\app_database.g.dart:10823:38 - override_on_non_overriding_member

1 issue found. (ran in 2.5s)
Exit code: 1
```
*(Only 1 pre-existing warning from generated Drift file. Our code is clean.)*

## Gotcha Protocol
No new gotchas to add. PBAC gates were strictly maintained.
