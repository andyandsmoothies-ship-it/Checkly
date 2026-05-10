# Implementation Plan: PBAC UI Final Polish

**Context**: The application is migrating to a granular Policy-Based Access Control (PBAC) system. A recent audit found several UI components that lack explicit capability guards, exposing them to users who possess implicit/coarse `admin:access` via the router but lack the granular backend capability.

**Goal**: Apply "Deny-by-Default" UI principles using `PolicyManager` for the approved fixes (Items 1, 2, 3, and 5 from the audit report). Item 4 (System Logs) is deliberately skipped as it requires full-stack capability mapping.

---

## 🛠️ Execution Steps for the Builder Agent (@Forge)

### Step 1: Secure `UserManagementPage` & `UserCard` (Audit Item 1)
**File(s)**: `lib/features/admin/pages/user_management_page.dart` (and `UserCard` if extracted)
- **Task 1.1 (FAB)**: Inject `GetIt.instance<PolicyManager>()`. Conditionally render the Floating Action Button (`floatingActionButton`) that triggers `_showCreateUserSheet`. It should only render if `policyManager.can(AppCapabilities.usersManage)` is true.
- **Task 1.2 (UserCard Menu)**: Within the list rendering or `UserCard` definition, evaluate the `users:manage` capability. Conditionally render the trailing `PopupMenuButton` (which contains "Edit Role", "Reset Password", "Deactivate"). If the user lacks the capability, hide the 3-dot menu entirely.

### Step 2: Secure `AdminDashboardPage` Navigation (Audit Item 2)
**File(s)**: `lib/features/admin/pages/admin_dashboard_page.dart`
- **Task 2.1**: Inject `PolicyManager`.
- **Task 2.2**: Update the rendering logic for the grid/list of `_MenuItem` widgets. Currently, all items render for anyone with `admin:access`. You must conditionally include them based on granular capabilities:
  - User Management ➔ `AppCapabilities.usersManage`
  - Store Management ➔ `AppCapabilities.storesWrite`
  - Area Management ➔ `AppCapabilities.areasWrite`
  - Role Management ➔ `AppCapabilities.adminManageRoles`
  - Global Risks ➔ `AppCapabilities.globalRisksManage`
  - System Logs ➔ *Leave as `admin:access` for now (Item 4 Deferred)*

### Step 3: Secure `ScheduleAuditPage` (Audit Item 3)
**File(s)**: `lib/features/admin/pages/schedule_audit_page.dart` (and associated form)
- **Task 3.1**: Inject `PolicyManager` into the page.
- **Task 3.2**: At the top of the `build` method, evaluate `policyManager.can(AppCapabilities.programsCreate)`. (Alternatively use `submissionsCreate` depending on existing mapping in `app_capabilities.dart`).
- **Task 3.3**: If `false`, render an access denied view (e.g., `Center(child: Text('Unauthorized'))`) instead of the scheduling form to completely block the capability leak.

### Step 4: Graceful Degradation in `ProgramListPage` (Audit Item 5)
**File(s)**: `lib/features/programs/pages/program_list_page.dart`
- **Task 4.1**: Inject `PolicyManager`.
- **Task 4.2**: When building the list items (likely a `ListTile` or `Card`), check `policyManager.can(AppCapabilities.programsReview)`.
- **Task 4.3**: If `false`, set the `onTap` callback to `null` to disable interactivity.
- **Task 4.4**: If `false`, remove or hide the trailing `Icon(Icons.chevron_right)` to visually indicate the row is read-only.

---

### Definition of Done
- No magic strings are used (all capabilities referenced from `AppCapabilities`).
- The UI gracefully removes interactive elements rather than showing errors when unauthorized.
- The project compiles successfully without warnings.
- `flutter test` passes (update any widget tests if they expected the UI elements to be unconditionally present).
