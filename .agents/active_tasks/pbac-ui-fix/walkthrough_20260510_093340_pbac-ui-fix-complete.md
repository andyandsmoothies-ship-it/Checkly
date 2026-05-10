# Master Walkthrough: PBAC UI Final Polish (Complete)

## Input Lineage
- **Source Plan**: `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\pbac-ui-fix\implementation_plan_20260509.md`
- **Scope**: All 4 items completed to secure UI leaks regarding granular Policy-Based Access Control (PBAC).

---

## Executive Summary & Decision Log

### Step 1: Secure `UserManagementPage` & `UserCard` (Audit Item 1)
- **Goal**: Prevent users with `admin:access` but without `users:manage` from creating users or opening the 3-dot management menu.
- **Decision**: Injected `PolicyManager.can(AppCapabilities.usersManage)` directly inside the `build()` methods of `UserManagementPage` and `UserCard`. The floating action button and the trailing `PopupMenuButton` are entirely removed (rendered as `null` or absent) when unauthorized.

### Step 2: Secure `AdminDashboardPage` Navigation (Audit Item 2)
- **Goal**: Hide navigation grid/list items for management modules if the user lacks the specific capability.
- **Decision**: Refactored the static list of `_MenuItem` widgets into a dynamic `_buildMenuItems()` method. Each item is now conditionally pushed to the list based on specific capabilities:
  - User Management ➔ `usersManage`
  - Store Management ➔ `storesWrite`
  - Area Management ➔ `areasWrite`
  - Role Management ➔ `adminManageRoles`
  - Global Risks ➔ `globalRisksManage`
- **Gotcha Fix**: Updated `admin_dashboard_page_test.dart` to inject `_MockPolicyManager` so the existing widget tests passed the new constructor/build requirements.

### Step 3: Secure `ScheduleAuditPage` (Audit Item 3)
- **Goal**: Prevent unauthorized access to the audit scheduling form.
- **Decision**: Used `PolicyManager.can(AppCapabilities.submissionsCreate)` at the root of `ScheduleAuditPage.build()`. 
- **UX Enhancement**: Rather than a blank screen or basic text, implemented a private `_AccessDeniedView` widget displaying a lock icon and "Access Restricted" message. 
- **Correction**: The original plan suggested `programsCreate`, but `submissionsCreate` was used as it aligns with the backend and existing delegation logic for audit submissions.

### Step 4: Graceful Degradation in `ProgramListPage` (Audit Item 5)
- **Goal**: Prevent unauthorized users from clicking into a program's details, while still allowing them to view the list.
- **Decision**: Checked `PolicyManager.can(AppCapabilities.programsReview)` during item generation. Gracefully degraded the `ListTile` by nullifying `onTap` and removing the trailing chevron (`>`) icon, turning the row into a read-only visual element.

---

## Files Modified

| File | Sub-system | Change |
|---|---|---|
| `lib/features/admin/pages/user_management_page.dart` | Users | Conditional rendering of FAB based on `usersManage`. |
| `lib/features/admin/widgets/user_card.dart` | Users | Conditional rendering of 3-dot menu based on `usersManage`. |
| `lib/features/admin/pages/admin_dashboard_page.dart` | Admin Nav | Dynamic generation of menu items gated by granular capabilities. |
| `test/features/admin/pages/admin_dashboard_page_test.dart` | Tests | Added `_MockPolicyManager` to support DI injection in `AdminDashboardPage`. |
| `lib/features/admin/pages/schedule_audit_page.dart` | Audits | Gated form rendering based on `submissionsCreate`; added `_AccessDeniedView`. |
| `lib/features/programs/pages/program_list_page.dart` | Programs | Graceful degradation (read-only mode) based on `programsReview`. |

---

## Verification Handoff (Master Checklist for QA)

**Test Scenario A: Fully Privileged Admin**
1. Log in as an admin with ALL capabilities.
2. Navigate to Admin Dashboard: Verify 10 items show up.
3. Navigate to User Management: Verify the FAB (+) is visible, and the 3-dot menu appears on users.
4. Navigate to Schedule Audit: Verify the form renders normally.
5. Navigate to Programs: Verify the list items have a `>` icon and tapping them opens the program details.

**Test Scenario B: Implicit Admin Only (e.g. Auditor/Basic User)**
1. Log in as a user with basic `admin:access` but WITHOUT management capabilities (`users:manage`, `stores:write`, `areas:write`, `admin:manage_roles`, `global_risks:manage`, `submissions:create`, `programs:review`).
2. Navigate to Admin Dashboard: Verify User, Store, Area, Role, and Global Risk management tiles are HIDDEN.
3. Direct Navigate to `/admin/users`: Verify no FAB (+ person_add button). Confirm each user row has no 3-dot menu.
4. Direct Navigate to `/admin/schedule`: Verify lock icon + "Access Restricted" + "You do not have permission to schedule audits." renders.
5. Navigate to Programs: Verify the list items lack the `>` icon and tapping them does nothing. The items should visually appear read-only.

---

<test_trace>
Command: rtk flutter test --concurrency=1
Exit code: 0
Summary: +467: All tests passed! (Zero regressions across all steps)
</test_trace>

<forensic_evidence>
- flutter analyze: 0 issues found across all modified files.
- flutter test (global --concurrency=1): 467/467 passed, 0 failed.
- Immutable Mock Guard: Respected. Mocks were added to `admin_dashboard_page_test.dart` strictly to support new DI dependencies, not to alter assertions.
</forensic_evidence>

---

## Gotcha Protocol

**New Gotcha Logged**: 
When a new `GetIt`-resolved service (like `PolicyManager`) is injected into a widget's `build()` method, existing widget tests will fail with `Bad state: GetIt: Object/factory with type X is not registered`. Always check `test/features/.../[page]_test.dart` for a `_registerDi()` or `setUp()` helper and add the new service mock there. This is test harness wiring (infrastructure), not an assertion change.
