# Walkthrough: Profile Capabilities UI

## Input Lineage
`c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260510_131334_pbac-ui-fix.md`

## Decision Log
- **Proposed:** Extract a new `ProfileCapabilitiesSection` widget containing an `ExpansionTile` with a `Wrap` of `Chip` widgets, driven by a `ValueListenableBuilder` tied to `AuthManager.capabilities`. Include protective measures like alphabetical sorting, display capping (50 max), Title Case string conversion, and empty state handling.
- **Implemented:** Implemented exactly as proposed. The widget was created in `lib/features/profile/widgets/profile_capabilities_section.dart` and injected into `ProfilePage` right above the Sign Out section. Safe string transformations and sorting were applied. Visual aesthetic tokens `surfaceContainerHighest` and `onSurfaceVariant` were utilized for the Chips.

## Verification Handoff
1. **Empty State:** Log in with an account that has no PBAC capabilities, or intercept the network call and mock an empty list. Open the "My Capabilities" section and ensure it displays "No capabilities assigned." without crashing.
2. **Standard State:** Log in with a standard role (e.g. Area Manager). Ensure capabilities are displayed, properly formatted in Title Case without colons, and alphabetically sorted.
3. **Overflow State:** Temporarily modify `displayCaps` limit to `3` in the code, or mock a user with 55 capabilities. Verify the first N capabilities display correctly, and the trailing chip correctly calculates the remainder (e.g., "+X more") without wrapping or memory leaks.

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart
...
00:25 +411 -8: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
...
01:01 +459 -8: Some tests failed.
Exit code: 1

(Note: The 8 failing tests are pre-existing integration tests in `photo_queue_backoff_test.dart` and `photo_queue_service_test.dart` which are unrelated to `ProfilePage` UI changes.)
</test_trace>

<forensic_evidence>
Analyzing Checkly...
No issues found! (ran in 38.4s)
Exit code: 0
</forensic_evidence>

## Gotcha Protocol
No new architectural or framework quirks were discovered during this implementation. Standard Flutter UI and `ValueListenableBuilder` rules applied cleanly.
