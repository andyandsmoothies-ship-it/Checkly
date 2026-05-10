# PBAC UI Implementation - Walkthrough
Workflow: /implement | Track: B1

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260510_112229_pbac-ui-impl.md`

## Decision Log
**Proposed vs Implemented:**
- **Step 1: Hide START AUDIT button:** Implemented exactly as planned using ternary operator and `PolicyManager.can(AppCapabilities.submissionsCreate)` in `template_detail_page.dart`.
- **Step 2: Add Router Redirects:** Implemented exactly as planned. `redirect:` blocks were added to `app_router.dart` for `/stores/select`, `/audit`, and `/admin/user-groups`. The `/audit` resume bypass was included correctly.
- **Step 3: Remove `initState` Guard:** Implemented. Removed the `addPostFrameCallback` capability check and `go_router` dependency from `user_group_list_page.dart` since `app_router.dart` now handles the unauthorized redirection.

## Verification Handoff
The UI correctly gates users based on PBAC capabilities. No backend changes were made.
- **QA Action**: Verify visually that unauthorized users cannot see the "START AUDIT" button on Template Detail pages, and cannot access `/admin/user-groups` via deep link. Verify users CAN resume a draft audit even if they lose creation capabilities.

<test_trace>
```text
C:\Users\HP\Documents\GitHub\Checkly> rtk flutter test
...
00:50 +467: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: (tearDownAll)
00:50 +467: All tests passed!

Exit code: 0
```
</test_trace>

<forensic_evidence>
```text
C:\Users\HP\Documents\GitHub\Checkly> cmd /c "cd lib && rtk flutter analyze"
Analyzing lib...                                                
No issues found! (ran in 87.6s)

Exit code: 0
```
</forensic_evidence>

## Gotcha Protocol
No new gotchas identified during this implementation. The existing `PolicyManager.can` and Router `redirect` patterns were sufficient and robust.
