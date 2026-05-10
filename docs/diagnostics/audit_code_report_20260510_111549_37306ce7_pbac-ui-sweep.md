# Systematic PBAC UI Sweep — Code Audit Report
**Audit ID**: `audit_code_report_20260510_111549_37306ce7_pbac-ui-sweep`
**Date**: 2026-05-10
**Scope**: Flutter UI (`lib/`) — All PBAC Capability Guards
**Role**: Sentinel (Read-Only Analysis)

```
[User Action] --> [UI Component] --> [Router] --> [Backend PBAC]
                     ↑ AUDIT SCOPE ↑
```

---

## Summary

The audit found **2 Critical Leaks** and **2 Architectural Warnings**. The rest of the UI is correctly guarded. The backend (C# API) is fully secure in all paths.

| Severity | Count | Description |
|----------|-------|-------------|
| 🔴 Critical | 2 | Unprotected action buttons / naked routes |
| 🟡 Warning | 2 | Inconsistent guard pattern / file size |
| 🟢 Pass | 12 | Correctly guarded components |

---

## 🟢 PASSING — Correctly Guarded (For Reference)

| Component | Capability Checked | Pattern Used |
|---|---|---|
| `ChecklyFab` (Dashboard + History) | `submissionsCreate`, `programsCreate` | `PolicyManager.can()` prop gate |
| `TemplateCard` popup menu | `submissionsCreate`, `templatesUpdate`, `templatesDelete` | `if (canStart)` item filter |
| `TemplateListPage` FAB | `templatesCreate` | `PermissionGuard` widget |
| `ProgramListPage` FAB | `programsCreate` | Ternary `canCreate ? FAB : null` |
| `ProgramListPage` review section | `programsReview` | Ternary render |
| `SubmissionRow` Void popup item | `submissionsReview` | `if (canVoid)` item filter |
| `HistoryListView` Void button | `submissionsReview` | `if (canVoid)` guard |
| `UserManagementPage` FAB | `usersManage` | Ternary `canManage ? FAB : null` |
| `StoreManagementPage` FAB | `storesWrite` | Ternary `canWrite ? FAB : null` |
| `AreaManagementPage` FAB | `areasWrite` | Ternary `canWrite ? FAB : null` |
| `GlobalRiskManagementPage` FAB | `globalRisksManage` | Ternary `canManage ? FAB : null` |
| `AdminDashboardPage` | `adminAccess` | Router `/admin/*` prefix guard |
| `ScheduleAuditPage` | `submissionsCreate` | In-page `_AccessDeniedView` widget |
| `ActionPlanDetailPage` | `actionPlansWrite`, `actionPlansVerify` | Ternary render per button |
| Router `/programs/new` | `programsCreate` | `redirect:` guard |
| Router `/analytics` | `analyticsView` | `authRedirect` function guard |
| Router `/activity` | `submissionsList` | `authRedirect` function guard |
| Router `/programs/:id` | `programsExecute` | `authRedirect` function guard |
| Router `/admin/*` prefix | `adminAccess` | `authRedirect` function guard |

---

## 🔴 CRITICAL — Finding #1: Naked "START AUDIT" Button

**File**: `lib/features/templates/pages/template_detail_page.dart`
**Lines**: 43–57

**Problem**: The `bottomNavigationBar` renders an `ElevatedButton.icon` with label "START AUDIT" for ALL authenticated users regardless of capability. There is no `PolicyManager.can()` check.

**Attack Path**:
```
User (no submissions:create) 
  --> Taps "Templates" tab (allowed)
  --> Taps any Template card (allowed, read-only)
  --> Sees "START AUDIT" button  <-- LEAK
  --> Taps it --> /stores/select --> /audit --> creates local draft
  --> Sync fails with 403 --> "Submission Unsynced" error
```

**Fix** (Complexity: **Low**):
```dart
// In _TemplateDetailPageState.build():
// Step 1: Import the required files
import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';

// Step 2: Check capability
final canStart = _di<PolicyManager>().can(AppCapabilities.submissionsCreate);

// Step 3: Conditionally render the bottomNavigationBar
bottomNavigationBar: canStart
    ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(
                '/stores/select?templateId=${widget.templateId}',
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('START AUDIT'),
            ),
          ),
        ),
      )
    : null,
```

**Trade-offs**:
- **Pro**: Zero regression risk. Only hides the button. Backend already blocks unauthorized submissions.
- **Con**: None. The `PermissionGuard` widget could be used instead, but this ternary pattern is the existing convention in the project (matches `ProgramListPage`, `StoreManagementPage`, etc.).

---

## 🔴 CRITICAL — Finding #2: Naked Router Routes for Audit Flow

**File**: `lib/_shared/router/app_router.dart`
**Lines**: 113–127

**Problem**: The routes `/stores/select` and `/audit` have no `redirect:` guard checking `submissions:create`. A user who bypasses the UI (e.g. via a notification deep link or bookmarked URL) can reach the audit form directly.

**Attack Path**:
```
User (no submissions:create)
  --> Opens deep link: /stores/select?templateId=abc  <-- NO GUARD
  --> Proceeds to /audit?templateId=abc&storeId=xyz   <-- NO GUARD
  --> Creates local draft --> Sync fails
```

**Fix** (Complexity: **Low**):
Add a `redirect:` to both route definitions using the same pattern as `/programs/new`:
```dart
GoRoute(
  path: '/stores/select',
  redirect: (context, state) {
    if (!_di<PolicyManager>().can(AppCapabilities.submissionsCreate)) {
      return '/home';
    }
    return null;
  },
  builder: (context, state) => StoreSelectorPage(
    templateId: state.uri.queryParameters['templateId'] ?? '',
  ),
),
GoRoute(
  path: '/audit',
  redirect: (context, state) {
    // Allow resume-from-draft: drafts already exist locally.
    // Only block fresh audit starts (autoResume=false and no submissionId).
    final isResume = state.uri.queryParameters['autoResume'] == 'true'
        || state.uri.queryParameters['submissionId'] != null;
    if (!isResume && !_di<PolicyManager>().can(AppCapabilities.submissionsCreate)) {
      return '/home';
    }
    return null;
  },
  builder: (context, state) => AuditFormPage(
    templateId: state.uri.queryParameters['templateId'] ?? '',
    storeId: state.uri.queryParameters['storeId'] ?? '',
    autoResume: state.uri.queryParameters['autoResume'] == 'true',
    targetSubmissionId: state.uri.queryParameters['submissionId'],
  ),
),
```

**Trade-offs**:
- **Pro**: Closes the deep-link bypass. Consistent with `/programs/new` guard pattern.
- **Con**: The `/audit` resume path needed special treatment (allow users without `submissions:create` to resume a draft they already started before the capability was revoked). The fix above handles this correctly by allowing resume when `autoResume=true` or `submissionId` is present.

---

## 🟡 WARNING — Finding #3: Inconsistent Guard Pattern in `UserGroupListPage`

**File**: `lib/features/user_groups/pages/user_group_list_page.dart`
**Lines**: 41–48

**Problem**: The `usersManage` capability check is done inside `initState()` via `postFrameCallback`. This is the only page in the app that uses this anti-pattern. Every other page either uses a router `redirect:` guard or an in-page ternary render. The `postFrameCallback` approach causes a brief screen flash before redirecting.

**Also**: The FAB on line 54 renders unconditionally — the page relies entirely on the `initState` redirect to never reach the build state without permission. If that redirect fires a frame late, the FAB is visible and usable for one frame.

**Fix** (Complexity: **Low** — align to existing router guard pattern):
```dart
// In app_router.dart, add a redirect to the /admin/user-groups route:
GoRoute(
  path: '/admin/user-groups',
  redirect: (context, state) {
    if (!_di<PolicyManager>().can(AppCapabilities.usersManage)) return '/home';
    return null;
  },
  builder: (context, state) => const UserGroupListPage(),
),
// Then REMOVE the initState guard from UserGroupListPage — the router owns this.
```

**Trade-offs**:
- **Pro**: Eliminates the flash-of-forbidden-content. Consistent with all other admin pages.
- **Con**: Deleting the `initState` guard requires also removing the `context.go('/home')` logic. Minor refactor.

---

## 🟡 WARNING — Finding #4: `submission_row.dart` File Size Threshold

**File**: `lib/features/dashboard/pages/widgets/submission_row.dart`
**Lines**: 373 lines

**Problem**: The file exceeds the 250-line warning threshold (373 lines). The `_voidAudit()` method alone is 70 lines of dialog code. The `_SubmissionRowState` class is doing too much (void logic, discard logic, resume logic, and UI rendering). This makes the PBAC guard logic harder to spot and test.

**Fix** (Complexity: **Medium** — extract the void/discard dialog logic):
- Extract `_voidAudit()` and `_discardDraft()` into a separate `SubmissionActions` helper class.
- Reduces the widget to ~200 lines, purely responsible for rendering.

**Trade-offs**:
- **Pro**: Smaller, more focused widget. PBAC checks become easier to locate and test.
- **Con**: Creates a new file. Requires updating the widget's constructor.
- **Note**: The PBAC check itself (`canVoid`) is correctly placed. This is a structural debt warning, not a security issue.

---

## Execution Queue

Priority order for the Builder (`/implement`):

| # | Priority | File | Change |
|---|----------|------|--------|
| 1 | 🔴 Critical | `template_detail_page.dart` | Hide START AUDIT button with `canStart` ternary |
| 2 | 🔴 Critical | `app_router.dart` | Add `redirect:` guards to `/stores/select` + `/audit` |
| 3 | 🟡 Warning | `app_router.dart` + `user_group_list_page.dart` | Move guard from `initState` to router |
| 4 | 🟡 Warning | `submission_row.dart` | Extract action methods to reduce file size |

> [!NOTE]
> Items 1 and 2 must be implemented together as they close the same attack path. Items 3 and 4 are independent and lower-risk.

<forensic_evidence>
Searched `template_detail_page.dart` lines 43-57: ElevatedButton.icon with no PolicyManager check found.
Searched `app_router.dart` lines 113-127: /stores/select and /audit routes confirmed to have no redirect guard.
Searched `app_router.dart` lines 250-340: authRedirect function confirmed — /stores/select and /audit are not in the guarded prefix blocks.
Searched `lib/` for `submissionsCreate` — found only 5 usages. Not present in app_router.dart for /stores/select or /audit routes.
Searched `lib/` for `stores/select` — found exactly 3 call sites: app_router.dart (route def), template_card.dart (guarded via canStart), template_detail_page.dart (UNGUARDED).
Searched `user_group_list_page.dart` lines 41-48: postFrameCallback-based redirect found (inconsistent pattern).
Searched `submission_row.dart`: 373 lines total, exceeds 250-line threshold.
</forensic_evidence>
