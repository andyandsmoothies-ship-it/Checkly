# Walkthrough: PBAC UI Final Polish — Step 2 (AdminDashboardPage)

## Input Lineage
- **Source Plan**: `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\pbac-ui-fix\implementation_plan_20260509.md`
- **Step**: Step 2 — Secure AdminDashboardPage Navigation (Audit Item 2)

---

## Decision Log

| Proposed | Implemented | Reason |
|---|---|---|
| Simple `if/else` block per item | `_buildMenuItems()` helper returning `List<Widget>` | Keeps `build()` clean; removes 100+ lines of inline duplication |
| Conditional `Divider` via `visible ? SizedBox.shrink() : Divider()` | Dividers built only between adjacent visible items via a for-loop interleave | Prevents orphaned horizontal lines when leading/trailing items are hidden |
| Read `PolicyManager` once in `initState()` | Read once in `build()` per local variable `pm` | Matches the established pattern used in Step 1 (UserCard, UserManagementPage) |
| Modify prod code to use `isRegistered` guard | Register `PolicyManager` mock in the test's `_registerDi()` | Proper fix: test harness must match the production contract; harness update is infrastructure, not an assertion change |

### Gated Items (capability → menu title)
| Capability | Menu Item |
|---|---|
| `usersManage` | User Management |
| `storesWrite` | Store Management |
| `areasWrite` | Area Management |
| `adminManageRoles` | Role Management |
| `globalRisksManage` | Global Risk Management |

### Ungated Items (reason)
| Menu Item | Reason |
|---|---|
| Audit Approvals | `admin:access` implicit — not in audit scope |
| System Logs | Item 4 deferred per plan |
| Analytics | `admin:access` implicit |
| Schedule Audit | Gating handled in Item 3 (Step 3) at page level |
| User Groups | `admin:access` implicit |

---

## Files Modified

| File | Change |
|---|---|
| `lib/features/admin/pages/admin_dashboard_page.dart` | Added `PolicyManager` + `AppCapabilities` imports; `build()` reads `pm`; static menu children replaced with `_buildMenuItems()` |
| `test/features/admin/pages/admin_dashboard_page_test.dart` | Added `_MockPolicyManager` class; registered in `_registerDi()` to match new production contract |

---

## Verification Handoff

**Manual check**:
1. Log in as an admin user with all capabilities → verify all 10 menu items show.
2. Log in as an auditor with only `admin:access` but no gated capabilities → verify User Management, Store Management, Area Management, Role Management, Global Risk Management are hidden.
3. Verify no orphaned `Divider` lines appear at the top or bottom of the Card.

---

<test_trace>
Command: rtk flutter test --concurrency=1
Result: +467: All tests passed!
Exit code: 0
Duration: ~2m19s
</test_trace>

<forensic_evidence>
flutter analyze: No issues found (0 warnings, 0 errors)
flutter test --concurrency=1: 467 passed, 0 failed, 0 skipped
admin_dashboard_page_test.dart isolated: 4/4 passed
slice5_admin_ui_test.dart isolated: 5/5 passed
</forensic_evidence>

---

## Gotcha Protocol

> **New Gotcha**: When a new `GetIt`-resolved service is injected into a widget's `build()` method, all existing widget tests for that widget must register a corresponding mock in their `setUp`/`_registerDi()` helper. Failure to do so causes `Bad state: GetIt: Object/factory with type X is not registered` in test runs and is caught immediately.
>
> **Fix**: Always check `test/features/.../[page]_test.dart` for a `_registerDi()` or `setUp()` helper and add the new service mock there. This is test harness wiring (infrastructure), not an assertion change — so it is allowed under the Immutable Mock Guard rule.
