# Walkthrough: PBAC UI Final Polish - Step 1 (UserManagementPage & UserCard)

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\pbac-ui-fix\implementation_plan_20260509.md`

## Decision Log
| Proposed | Implemented |
|---|---|
| Task 1.1: Gate FAB behind `usersManage` in UserManagementPage | ✅ `canManage = _di<PolicyManager>().can(AppCapabilities.usersManage)` evaluated in `build()`. FAB is `null` when false. |
| Task 1.2: Gate 3-dot menu in UserCard behind `usersManage` | ✅ `UserCard` reads `PolicyManager` directly via `GetIt.instance` — avoids prop-drilling through `UserManagementList`. PopupMenuButton entirely absent (not just disabled) when `canManage` is false. |

**Callback nullability:** All three UserCard callbacks (`onEdit`, `onResetPassword`, `onBanToggle`) made `Optional`. The `UserManagementList` continues to pass real callbacks — the visibility guard inside `UserCard.build()` ensures they are never reachable unless `canManage` is true. The `?.call()` pattern defends against future callers that might pass `null` regardless.

**Pattern chosen:** `UserCard` reads `PolicyManager` internally — same pattern as `TemplateCard` in Phase B. This avoids threading a `canManage` bool through `UserManagementList` which is a pure layout widget with no policy context.

## Verification Handoff
1. Log in as a user with `admin:access` but WITHOUT `users:manage`.
2. Navigate to `/admin/users` — confirm no FAB (+ person_add button).
3. Confirm each user row has no 3-dot (more_vert) icon.
4. Log in as a user WITH `users:manage` — confirm FAB and 3-dot menu appear.

<test_trace>
```text
Analyzing Checkly...
No issues found! (ran in ~9s)

00:55 +467: All tests passed!
Exit code: 0
```
</test_trace>

<forensic_evidence>
Executed: `rtk flutter analyze && rtk flutter test` from project root.
Modified files:
- `lib/features/admin/pages/user_management_page.dart`
- `lib/features/admin/widgets/user_card.dart`
</forensic_evidence>

## Gotcha Protocol
No new GEMINI.md edits required. The `PolicyManager.can()` inside widget `build()` pattern is established (see `TemplateCard`, `StoreCard`, `AreaCard`, `RiskCard`).
