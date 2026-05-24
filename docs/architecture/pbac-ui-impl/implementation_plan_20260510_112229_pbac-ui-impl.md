<latent_space_scratchpad>
- `template_detail_page.dart`: Needs to conditionally render the `bottomNavigationBar` based on `submissionsCreate` capability.
- `app_router.dart`: 
  - `/stores/select`: Needs redirect checking `submissionsCreate`.
  - `/audit`: Needs redirect checking `submissionsCreate`. Wait, the audit report says: allow resume when `autoResume=true` or `submissionId` is present.
  - `/admin/user-groups`: Needs redirect checking `usersManage`.
- `user_group_list_page.dart`: Remove the `addPostFrameCallback` capability gate in `initState` since it will be handled by the router.
</latent_space_scratchpad>

# Task: PBAC UI Implementation Fixes
Workflow: /analyze-feature | Track: A

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit_code_report_20260510_111549_37306ce7_pbac-ui-sweep.md`

## Executive Summary & Out of Scope
**Goal:** Fix the 2 Critical and 1 Warning PBAC UI leaks identified in the recent audit. This involves hiding the "START AUDIT" button for unauthorized users and adding router-level redirection guards for sensitive paths (`/stores/select`, `/audit`, `/admin/user-groups`).
**Out of Scope:** Refactoring `submission_row.dart` (the other warning in the audit). Modifying backend PBAC rules.

**Risk Warning:** Risk is extremely low. The backend API is already secured via PBAC, meaning these "leaks" only result in client-side 403 errors and "unsynced" drafts. These changes simply improve UX by hiding inaccessible features.

## System Context
- **Framework:** Flutter with GoRouter.
- **PBAC System:** `PolicyManager.can(capability)` checks against synced capabilities from the backend.
- **Routing:** Router `redirect` functions are used to bounce unauthorized users to `/home`.

## Lifecycle Context
- **Success:** Authorized users see the "START AUDIT" button and can access `/audit`, `/stores/select`, and `/admin/user-groups`.
- **Error/Denied:** Unauthorized users don't see the button. If they try to deep-link to the routes, the router's `redirect` kicks them to `/home` before the page even loads (Loading state).

## Test Contracts

| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-01 | Unauthorized user cannot see START AUDIT | User without `submissions:create` views Template Detail | Button is currently rendered unconditionally. |
| TC-02 | Unauthorized user cannot deep-link to `/stores/select` | Navigate to `/stores/select`, user lacks `submissions:create` | Route currently lacks a `redirect` guard. |
| TC-03 | Unauthorized user cannot deep-link to new `/audit` | Navigate to `/audit`, user lacks `submissions:create` | Route currently lacks a `redirect` guard. |
| TC-04 | Unauthorized user CAN resume an existing `/audit` draft | Navigate to `/audit?autoResume=true`, user lacks `submissions:create` | Router guard must explicitly allow resumes. |
| TC-05 | `user_group_list_page.dart` delegates auth to router | Inspect `initState` in UserGroupListPage | `context.go('/home')` is currently hardcoded there. |

## Test Fixture & Payloads
- **Setup:** A Flutter mock environment with `PolicyManager` configured to return `false` for `submissions:create` and `usersManage`.

## Tools & Commands
- **Testing:** `flutter test`
- **Skills required:** `flutter-architecture`

## Proposed Changes
- `[MOD]` `lib/features/templates/pages/template_detail_page.dart`
- `[MOD]` `lib/_shared/router/app_router.dart`
- `[MOD]` `lib/features/user_groups/pages/user_group_list_page.dart`

## Concept Diagram
```text
[User] -> [View Template] -> has submissions:create? 
                              -> YES -> Show "START AUDIT"
                              -> NO -> Hide button

[Deep Link] -> [/audit] -> is resume? 
                            -> YES -> Allow
                            -> NO -> has submissions:create?
                                      -> YES -> Allow
                                      -> NO -> Redirect to /home
```

## Execution Slices (Micro-Specs)

### Execution Phase
**Plain English Summary**: We will update the UI to use the `PolicyManager` to hide the "START AUDIT" button. We will also add `redirect` blocks to the `GoRouter` configuration to protect `/stores/select`, `/audit`, and `/admin/user-groups`. Finally, we will clean up the old `initState` redirection in `user_group_list_page.dart`.
**Value Delivered**: Secures the UI against unauthorized interactions and deep-link exploits, preventing "unsynced" errors from 403 backend rejections.
**Entry State Required**: The application runs with the current unsecured routes and buttons.
**Exit State Guaranteed**: The application correctly hides the button and redirects unauthorized routes to `/home`.
**Scope**: `lib/features/templates/pages/template_detail_page.dart`, `lib/_shared/router/app_router.dart`, `lib/features/user_groups/pages/user_group_list_page.dart`
**Acceptance Criteria**: 
1. `template_detail_page.dart` checks `PolicyManager.can(AppCapabilities.submissionsCreate)` before rendering the bottom navigation bar.
2. `app_router.dart` has `redirect` blocks for `/stores/select`, `/audit`, and `/admin/user-groups`.
3. The `/audit` redirect explicitly allows navigation if `autoResume` is true or `submissionId` is provided.
4. `user_group_list_page.dart` no longer has a capability check in `initState`.

**Complexity:** Low. We are applying existing, well-understood patterns (`PolicyManager.can` and GoRouter `redirect`) to three files.

**Pros & Cons:**
- *Pros*: Follows standard project conventions. Fixes critical UI leaks without backend changes.
- *Cons*: None.

<command_logs>
- `view_file` `c:\Users\HP\Documents\GitHub\Checkly\lib\_shared\router\app_router.dart`
- `view_file` `c:\Users\HP\Documents\GitHub\Checkly\lib\features\templates\pages\template_detail_page.dart`
- `view_file` `c:\Users\HP\Documents\GitHub\Checkly\lib\features\user_groups\pages\user_group_list_page.dart`
- `grep_search` `user-groups` in `app_router.dart`
</command_logs>

## Handoff Block
The plan is ready. Pass this to the Builder agent to implement the visual/simple UI changes.

> @[/implement] Execute build for The Feature: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260510_112229_pbac-ui-impl.md
