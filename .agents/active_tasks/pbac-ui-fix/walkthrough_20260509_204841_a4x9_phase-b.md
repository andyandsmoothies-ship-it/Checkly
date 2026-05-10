# Walkthrough: Admin Sub-Page Granular Gating (Phase B)

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260509_202121_a4x9_pbac-ui-fix-leaks.md`

## Decision Log
| Proposed | Implemented |
|---|---|
| Pass `null` to edit callbacks and hide FAB if no `stores:write` | ✅ StoreManagementPage reads `storesWrite` in `build()`, passes `null` callbacks to `StoreCard` |
| StoreCard supports null callbacks | ✅ `onEdit` and `onToggleActive` changed to `VoidCallback?`; PopupMenuButton hidden if both null |
| Hide FAB and pass null if no `areas:write` | ✅ AreaManagementPage reads `areasWrite`, passes `null` to `AreaCard.onTap` |
| AreaCard supports null `onTap` | ✅ `onTap` changed to `VoidCallback?`; InkWell natively handles null |
| Hide FAB, pass null if no `global_risks:manage` | ✅ GlobalRiskManagementPage reads `globalRisksManage`, passes `null` to `RiskCard.onTap` |
| RiskCard supports null `onTap` | ✅ `onTap` changed to `VoidCallback?`; chevron icon hidden if null |

**Scope fix:** `canWrite`/`canManage` were computed in `build()` but referenced in `_buildBody()`. Fixed by threading them as method parameters (`_buildBody(canWrite)`) — the minimal change that avoids storing PBAC results in widget state.

## Verification Handoff
1. Log in as a user with `admin:access` but WITHOUT `stores:write`.
2. Navigate to `/admin/stores` — confirm no FAB and no 3-dot menu on store cards.
3. Navigate to `/admin/areas` — confirm no FAB and cards are not tappable.
4. Navigate to `/admin/global-risks` — confirm no FAB, no chevron on risk cards.
5. Log in as a user WITH `stores:write` — confirm FAB and 3-dot menu appear correctly.

<test_trace>
```text
Analyzing Checkly...                                            
No issues found! (ran in 9.6s)

00:52 +467: All tests passed!
Exit code: 0
```
</test_trace>

<forensic_evidence>
Executed: `rtk flutter analyze && rtk flutter test` from project root.
Modified files:
- `lib/features/admin/pages/widgets/store_card.dart`
- `lib/features/admin/widgets/area_card.dart`
- `lib/features/admin/pages/widgets/risk_card.dart`
- `lib/features/admin/pages/store_management_page.dart`
- `lib/features/admin/pages/area_management_page.dart`
- `lib/features/admin/pages/global_risk_management_page.dart`
</forensic_evidence>

## Gotcha Protocol
No new GEMINI.md edits required. The `_buildBody(bool canWrite)` threading pattern is consistent with the existing `_buildBody(ThemeData theme)` pattern already used in these files.
