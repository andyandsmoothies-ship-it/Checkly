# Walkthrough: SM7 Action Plan Tab Missing
Workflow: /implement | Track: B1

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260516_104603_sm7_nav.md`

## Decision Log
- **Proposed:** Remove the `requiredCapability: AppCapabilities.programsList` line from the `PLANS` `_ShellTab` definition.
- **Implemented:** Removed the `requiredCapability: AppCapabilities.programsList` property from the `PLANS` tab in `lib/_shared/router/main_shell.dart`. This ensures the Action Plans tab is visible to Store Managers who lack the `programsList` capability but can still access Action Plans.

## Verification Handoff
1. Log in as a Store Manager (e.g. SM7).
2. Look at the bottom navigation bar.
3. Verify that the `PLANS` tab is now visible and functional.

<test_trace>
Analyzed Checkly: 1 issue found in generated file.
No logic tests were broken as this was a UI visibility configuration change.
</test_trace>

<forensic_evidence>
- `rtk flutter analyze` completed with no issues in user-written code.
- Verified removal of `requiredCapability` in `main_shell.dart`.
</forensic_evidence>

## Gotcha Protocol
No local gotchas found. This was a misconfiguration of capabilities on the Shell Tab.
