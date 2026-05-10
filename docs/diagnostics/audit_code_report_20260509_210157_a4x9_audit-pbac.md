<latent_space_scratchpad>
Thinking Process:
1. Load Phase 1 context: Audit UI for PBAC capability leaks.
2. Scan Admin modules (`UserManagementPage`, `AdminDashboardPage`, `SystemLogsPage`, `ScheduleAuditPage`).
3. Identify missing `PolicyManager` checks.
4. Evaluate trade-offs for each fix.
5. Create Assessment Payload.
</latent_space_scratchpad>

<forensic_evidence>
- `grep_search` for `users:manage` across `lib/` to confirm missing usage.
- `view_file` on `AdminDashboardPage` confirming missing capability wrapper on `_MenuItem`.
- `view_file` on `ScheduleAuditPage` confirming `submissions:create` bypass.
</forensic_evidence>

# PBAC UI Audit Report
Date: 2026-05-09
Focus: PBAC UI Implementation & Capability Guards

## Phase 2: Code Quality Scan
- **Dead Code (`🔴`)**: None found specific to PBAC UI logic. Some capabilities in `app_capabilities.dart` (`usersManage`, `programsCreate`) are currently "dead" because they are not wired to any UI components.
- **Arch. Drift (`🔴`)**: No major drift. UI routing logic is contained in `app_router.dart`, and UI widgets properly extract services via `GetIt.instance<PolicyManager>()`.
- **Exposed Secrets (`🔴`)**: None detected in the scanned UI files.
- **Docs & Formats (`🟡`)**: Documentation in `app_capabilities.dart` claims capabilities are enforced, but multiple leaks exist. Naming conventions match backend strings.

## Phase 3: Structural Health
- **File Sizing**: All audited pages (e.g., `UserManagementPage` at 343 lines, `AdminDashboardPage` at 279 lines) are safely below the 400-line critical threshold.
- **Class Density**: `AdminDashboardPage` contains 2 classes (`AdminDashboardPage`, `_MenuItem`). Well within the limit.
- **Private Isolation**: Components use standard Flutter public/private conventions.
- **Method Size**: `build` methods are reasonable and extracted where appropriate.
- **Decomposition**: No immediate decomposition required for the audited files, though `AdminDashboardPage`'s list of `_MenuItem`s could be generated from a structured list of guarded navigation targets.

## Phase 4: Coverage & Hygiene
- **Coverage Gaps**: Features lacking capability guards represent a severe functional test gap (integration tests likely do not cover negative auth paths for these specific components).
- **Dependencies**: N/A for this audit scope.
- **Stale Markers**: No stale `TODO` or `FIXME` comments relating to PBAC.
- **Duplication**: The pattern of manually guarding lists of elements (like in `AdminDashboardPage`) may lead to repetitive boilerplate. 

## Detailed Findings & Fix Trade-offs

### 1. `UserManagementPage` & `UserCard` Leak
- **Severity**: `🔴 Critical`
- **Issue**: The FAB for creating users and the 3-dot menu actions (Edit, Reset, Deactivate) are shown unconditionally.
- **Fix**: Wrap these actions in `PolicyManager().can(AppCapabilities.usersManage)` checks.
- **Complexity**: **Low**. Simple boolean check injection before rendering the FAB and passing callbacks.
- **Trade-offs / Pros & Cons**: 
  - *Pros*: Instantly secures the UI against unauthorized interactions.
  - *Cons*: Passing capability state down to `UserCard` adds minor boilerplate. Alternatively, evaluating it inside `UserCard` adds a dependency inside a dumb presentation widget.

### 2. `AdminDashboardPage` Leak
- **Severity**: `🟡 Warning` (Information / Navigation Leak)
- **Issue**: All administrative menu items are shown to anyone with implicit `admin:access`.
- **Fix**: Conditionally render each `_MenuItem` by checking its specific granular capability.
- **Complexity**: **Low**. 
  - *Pros*: Simplifies the dashboard for users who only have 1-2 admin capabilities.
  - *Cons*: Maintaining the mapping of which menu needs which capability adds overhead to adding new menus.

### 3. `ScheduleAuditPage` & `ScheduleAuditForm` Leak
- **Severity**: `🔴 Critical`
- **Issue**: Accessible via `/admin/schedule` with only `admin:access`. Users can freely delegate audits without `programs:create` or `submissions:create`.
- **Fix**: Add a router guard and wrap the UI form with `AppCapabilities.submissionsCreate`.
- **Complexity**: **Low**. 
  - *Pros*: Closes a major delegation loophole.
  - *Cons*: May lock out users who previously (incorrectly) had access, requiring backend roles to be updated.

### 4. `SystemLogsPage` Leak
- **Severity**: `🟡 Warning` (Telemetry Leak)
- **Issue**: Accessible to anyone with implicit `admin:access` via the router.
- **Fix**: Create `AppCapabilities.adminReadLogs` (or enforce `admin:access` explicitly inside the page).
- **Complexity**: **Medium**. Requires backend synchronization if a new capability token is created.
  - *Pros*: Granular protection of sensitive system telemetry.
  - *Cons*: Requires coordinating a backend PR and database seed for the new capability.

### 5. `ProgramListPage` Leak
- **Severity**: `🟡 Warning` (UX Frustration)
- **Issue**: The `onTap` handler on list cards routes to `/programs/review/$id` unconditionally, which is then blocked by the router, resulting in a silent fail or jarring redirect.
- **Fix**: Check `AppCapabilities.programsReview` before assigning the `onTap` callback.
- **Complexity**: **Low**.
  - *Pros*: Improves UX by visually indicating the item is not clickable.
  - *Cons*: None. Read-only presentation is a standard UX pattern.
