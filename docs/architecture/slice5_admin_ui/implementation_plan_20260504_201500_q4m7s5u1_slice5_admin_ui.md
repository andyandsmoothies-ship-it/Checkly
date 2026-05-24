<latent_space_scratchpad>
Slice 5 says "UI only", but current UI contract still posts legacy `areaId` only from `UserEditSheet`/`UserCreateSheet`, while backend Slice 3 supports `virtualAreaId` and `assignedStoreIds`. Admin list endpoint now returns `assignedStoreIds` for AM in `UserDto`, so UI can use this immediately with minimal backend coupling.

Risk hotspot is `schedule_audit_form.dart` where AM/auditor cross-filter still keys by `areaId`; this is now semantically wrong after direct assignment. For AMs, eligibility should be based on whether AM's `assignedStoreIds` contains selected store id. For non-AM, retain current behavior.

Workflow rule requires file >250 lines must be split before feature edits. `schedule_audit_form.dart` is ~385 lines, so plan must include extraction step before logic change.
</latent_space_scratchpad>

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\store_area_consolidation\analysis_epic_20260503_215500_2b21e338_area_override.md` (Slice 5)
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260504_190800_q4m7s4p1_slice4_profile_sync.md` (preceding sync contract)

## Executive Summary & Out of Scope
Implement Slice 5 UI updates so admin flows reflect virtual area/direct store assignment:
- Update admin user edit/create sheets to send `virtualAreaId` and (optionally) explicit `assignedStoreIds`.
- Update schedule-audit filtering logic to use AM `assignedStoreIds` membership instead of area matching.
- Preserve existing UX for store_manager/auditor/admin paths.

Out of scope:
- Backend API logic changes (already in Slice 3).
- Drift schema/sync changes (already in Slice 4).
- Non-admin scheduling UX redesign beyond assignment correctness.

## System Context
- **Platform:** Flutter app, online admin workflows with API-backed forms.
- **API Contract:** `AdminApiService.updateUser/createUser` already accept `virtualAreaId` and `assignedStoreIds`.
- **RBAC:** Admin-only user-management screens; schedule-audit form uses authenticated admin/area_manager context through manager data.
- **Offline/Online:** UI here is online-first for admin actions; no local-first write path introduced.

## Lifecycle Context
| State | UI behavior |
|---|---|
| Success | AM edit/create sends virtual area assignment payload; schedule form shows only eligible AMs for selected store by assigned-store membership. |
| Error | Existing snackbar/dialog error handling remains; payload validation failures from server surfaced through current API error routing. |
| Empty | No eligible AMs for selected store → auditor dropdown becomes empty and selection resets safely. |
| Loading | Existing loading spinner states in schedule form/user sheets unchanged. |

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-5.1 | `UserEditSheet` area-manager save sends `virtualAreaId` instead of legacy-only `areaId` | Success/Boundary | Current callback signature only forwards `areaId` |
| TC-5.2 | `UserCreateSheet` area-manager create sends virtual area field consistently | Success | Current create callback only forwards `areaId` |
| TC-5.3 | `ScheduleAuditForm` selected store filters AM list by `assignedStoreIds` contains selected store id | Success/Boundary | Current filter uses `areaId` equality |
| TC-5.4 | If selected AM no longer eligible after store change, auditor selection clears | Empty/Invariant | Needs explicit post-filter guard |
| TC-5.5 | Non-AM auditors/admin keep prior fallback behavior (no assignment list required) | Boundary/Regression | New filter may over-restrict non-AM users if not gated |

## Test Fixture & Payloads
- **UI fixture:** `AdminAuditManager.scheduleData` must include users with:
  - AM user: `role='area_manager'`, `assignedStoreIds=['store-1','store-2']`
  - auditor/admin users without assignment array.
- **Save payload expectation (edit/create):**
```json
{
  "role": "area_manager",
  "virtualAreaId": "11111111-1111-1111-1111-111111111111"
}
```
- Optional explicit store overrides:
```json
{
  "role": "area_manager",
  "virtualAreaId": "11111111-1111-1111-1111-111111111111",
  "assignedStoreIds": ["store-guid-a", "store-guid-b"]
}
```

## Tools & Commands
- **Skills:**  
  - `c:\Users\HP\Documents\GitHub\Checkly\.agents\skills\tdd\SKILL.md`  
  - `c:\Users\HP\Documents\GitHub\Checkly\.agents\skills\flutter-architecture\SKILL.md`  
  - `c:\Users\HP\Documents\GitHub\Checkly\.agents\skills\ux-copywriting\SKILL.md`
- **Validation commands:**
  - `rtk flutter analyze`
  - `rtk flutter test "..\test\features\admin"`
  - `rtk flutter test "..\test\features\stores\manager\store_manager_test.dart"`

## Proposed Changes
| Status | File Path | Type |
|---|---|---|
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\widgets\user_edit_sheet.dart` | add virtual area field wiring in `onSave` path |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\widgets\user_create_sheet.dart` | send virtual area field for AM create |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\pages\user_management_page.dart` | pass new virtual-area arg to manager save/create |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\manager\admin_user_manager.dart` | accept/forward virtual area + optional assigned stores |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\widgets\schedule_audit_form.dart` | replace area-based AM filter with assigned-store membership |
| [NEW/MOD] | split helper file(s) under `lib/features/admin/widgets/` | **required** due file-size gate (>250 lines) for schedule form |

## Concept Diagram
`[Admin selects AM + Area shortcut] --> [User sheet emits virtualAreaId] --> [AdminUserManager -> AdminApiService] --> [server UpdateUser]`

`[Schedule form selects Store] --> [filter AM users where assignedStoreIds contains storeId] --> [eligible auditor list]`

## Execution Slices
### Phase A: User sheet payload migration (Complexity: Low)
- Update callbacks/signatures for `virtualAreaId` in edit/create paths.
- **Pros:** minimal behavior change, aligns UI contract with backend.
- **Cons:** requires careful null compatibility for non-AM roles.

### Phase B: Schedule form split (Complexity: Medium)
- Extract filtering logic/view-model helpers from `schedule_audit_form.dart` before functional edits.
- **Pros:** satisfies file-size rule, reduces bug risk.
- **Cons:** temporary structural churn.

### Phase C: Assignment-based AM filtering (Complexity: Medium)
- Implement `assignedStoreIds`-based eligibility and selection reset logic.
- **Pros:** matches direct assignment model.
- **Cons:** requires robust fallback for users lacking assignment arrays.

## Risk Assessment
> **Risk Warning:** Slice 5 appears UI-only, but wrong filtering semantics can cause admins to assign audits to ineligible AMs or hide valid AMs entirely.

| Risk | Severity | Mitigation |
|---|---|---|
| Legacy `areaId` filtering still active in schedule form | High | Replace with assignment-based check and add regression tests |
| File-size constraint ignored for schedule form | Medium | Mandatory split step before logic edits |
| Payload mismatch (`areaId` only) blocks virtual-area UX intent | Medium | Align callback signatures and API manager wiring for `virtualAreaId` |
| Missing `assignedStoreIds` on some user records | Low | Treat null/empty as no AM eligibility, preserve non-AM behavior |

## Verification Plan
1. Add/execute widget/manager tests for user sheet payload forwarding (`virtualAreaId`).
2. Add/execute schedule-form filtering tests using fixture users with `assignedStoreIds`.
3. Run `rtk flutter analyze` on touched files.
4. Run relevant admin/store test suites + optional broader flutter suite.

## Handoff Block
Slice 5 analysis complete. This slice modifies UI and filtering logic and should run with test-first (logic route).

Run one command at a time:
`@[/tdd] Execute tests for Slice 5 (Admin UI — Virtual Area Picker): c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260504_201500_q4m7s5u1_slice5_admin_ui.md`

Concurrency:
- Slice 5 can proceed after Slice 4 contract is available (already in place), but should not overlap with unrelated admin form refactors.

<command_logs>
- ReadFile `.agents/workflows/analyze-feature.md`
- ReadFile slice epic analysis doc
- ReadFile `GEMINI.md` + `lib/GEMINI.md`
- ReadFile `lib/features/admin/widgets/user_edit_sheet.dart`
- ReadFile `lib/features/admin/widgets/user_create_sheet.dart`
- ReadFile `lib/features/admin/widgets/schedule_audit_form.dart`
- ReadFile `lib/features/admin/manager/admin_audit_manager.dart`
- ReadFile `lib/features/admin/manager/admin_user_manager.dart`
- ReadFile `lib/features/admin/pages/user_management_page.dart`
- ReadFile `lib/features/admin/services/admin_api_service.dart`
- ReadFile `server/Features/Admin/ListUsers.cs` + `server/Features/Admin/Dtos.cs`
- rg search for `assignedStoreIds|virtualAreaId` usage across server/lib
</command_logs>

<forensic_evidence>
- `user_edit_sheet.dart` and `user_create_sheet.dart` currently expose/save only `areaId` for area_manager UI paths.
- `admin_user_manager.dart` and `admin_api_service.dart` already support `virtualAreaId` and `assignedStoreIds`, indicating UI wiring gap.
- `schedule_audit_form.dart` currently filters auditors by `areaId` equality (`store.areaId == user.areaId` pattern), which contradicts direct assignment model.
- `ListUsers.cs` now includes `AssignedStoreIds` in `UserDto`, making assigned-store filtering feasible in UI without additional backend endpoints.
- `schedule_audit_form.dart` is ~385 lines (>250), triggering mandatory split step per analyze workflow file-size rule.
</forensic_evidence>
