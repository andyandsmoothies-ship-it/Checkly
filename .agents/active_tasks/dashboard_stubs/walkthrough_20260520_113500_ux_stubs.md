# Walkthrough: Fix Admin Dashboard Page Dead UX Stubs

We have successfully removed the dead UX stubs (`onTap: () {}`) on the Templates and Open Plans stat tiles in the Admin Dashboard, wiring them directly to their respective existing shell routes.

## Input Lineage
- **Source**: User request to fix dead UX stubs.

## Decision Log

| Proposed | Implemented | Reason |
|---|---|---|
| Wire "TEMPLATES" tile | `context.push('/templates')` | Route mapped to `TemplateListPage` inside bottom shell route. |
| Wire "OPEN PLANS" tile | `context.push('/plans')` | Route mapped to `ActionPlansPage` inside bottom shell route. |

## Verification Handoff

### Automated Verification
1. **Flutter Analysis**: Running `flutter analyze` passes cleanly with **zero issues**.
2. **Widget Tests**: Running `flutter test test/features/admin/pages/admin_dashboard_page_test.dart` passes cleanly with **all 4 tests passing**.

### Manual Verification
1. Log in as an Administrator.
2. Open the Admin Dashboard.
3. Tap on the **TEMPLATES** tile. Verify it successfully navigates to the Templates List Page.
4. Tap on the **OPEN PLANS** tile. Verify it successfully navigates to the Action Plans Page.

<test_trace>
### Flutter Analyze Output
```
Analyzing lib...
No issues found! (ran in 98s)
```

### Flutter Test Output
```
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/admin_dashboard_page_test.dart
00:00 +0: AdminDashboard — Load Counts AdminDashboard_LoadCounts_ShowsSnackBarOnApiFailure — SnackBar visible when API throws
00:01 +1: AdminDashboard — Load Counts AdminDashboard_LoadCounts_SilentOnSuccess — No SnackBar on successful API call
00:01 +2: AdminDashboard — Layout AdminDashboard_Layout_RespectsMaxWidth — ConstrainedBox(maxWidth:600) in tree
00:01 +3: AdminDashboard — Terminology AdminDashboard_StatLabel_ShowsOpenPlans — OPEN PLANS visible, PENDING absent
00:01 +4: All tests passed!
```
</test_trace>

<forensic_evidence>
#### File Changes
- **Modified**: `lib/features/admin/pages/admin_dashboard_page.dart` (lines 105 & 114)
</forensic_evidence>

## Gotcha Protocol
None. The routes `/templates` and `/plans` exist under `MainShell` inside `app_router.dart` and are fully authenticated, making navigation straightforward and safe.
