<latent_space_scratchpad>
Primary code mismatch verified:
- Action Plans do not expose `allowedActions` on either server or Flutter DTOs.
- `ActionPlanDetailPage` still computes contextual buttons from local `PolicyManager`.
- Shared `ActionGuard` currently falls back to JWT capabilities when `actions == null`, which conflicts with the decision record's strict fail-closed wording.

Main blast-radius warning:
- Changing shared `ActionGuard` to fail closed immediately would affect existing Submission offline UI, because submissions still rely on fallback semantics instead of cached action arrays.
- `action_plan_detail_page.dart` (305 lines) and `action_plan_manager.dart` (269 lines) both exceed the workflow threshold, so the implementation must split before feature growth.

Safe path:
- Keep route/module access unchanged for now.
- Add backend-computed Action Plan `allowedActions`.
- Persist Action Plan `allowedActions` into Drift so offline detail screens do not depend on shared fallback logic.
- Do not change the global `ActionGuard`; use an Action Plan scoped wrapper for strict fail-closed rendering.
- Recompute minimal local `allowedActions` during optimistic Action Plan transitions.
</latent_space_scratchpad>
[Plans Tab] -> [/plans/:id] -> [GET /api/action-plans/{id}] -> [ActionPlanDto.allowedActions] -> [Drift cache] -> [Detail UI renders or hides actions]

## Input Lineage
- `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260516_120520_SYN_pbac_ui.md`

## Executive Summary & Out of Scope
> [!WARNING]
> Risk Warning: The ROI is positive for Action Plans, but the architectural cost is medium-high because this slice crosses backend DTOs, role-scoped endpoint projections, local Drift schema, offline optimistic state, and a shared UI guard that is already used by other modules.

This feature is worth doing because the current Action Plan detail page still decides contextual actions locally (`PolicyManager`), while the rest of the PBAC direction in the repo is moving toward server-projected action lists. The recommended implementation is to migrate Action Plans to the same hybrid contract used by submissions: backend computes item actions, Flutter persists them, and the detail page renders actions from that payload instead of recomputing business rules locally.

Out of scope for this plan:
- Adding a new route-level `action_plans:list` capability. The `/plans` tab and `/api/action-plans` route are currently auth-only and remain so.
- Reworking Submission PBAC or Program PBAC beyond what is required to avoid regressions.
- Changing notification routes, dashboard cards, or list-page navigation behavior.
- Generalizing a repo-wide fail-closed `ActionGuard` migration. This plan keeps the shared guard unchanged and scopes strict rendering to Action Plans.

## System Context
- Runtime mode: Hybrid offline-first Flutter app with live ASP.NET Core API and local Drift cache.
- Backend endpoints involved: `GET /api/action-plans`, `GET /api/action-plans/{id}`, `PUT /api/action-plans/{id}`.
- Current RBAC/PBAC gates:
  - Module/tab access: `/plans` is visible without a dedicated capability in [main_shell.dart](C:\Users\HP\Documents\GitHub\Checkly\lib\_shared\router\main_shell.dart:35).
  - Contextual submit action: `action_plans:write`.
  - Contextual verify/reject actions: `action_plans:verify`.
- Current source-of-truth mismatch:
  - Server already enforces transition PBAC inside [UpdateActionPlan.cs](C:\Users\HP\Documents\GitHub\Checkly\server\Features\ActionPlans\UpdateActionPlan.cs:73).
  - Flutter still renders buttons from local capability checks in [action_plan_detail_page.dart](C:\Users\HP\Documents\GitHub\Checkly\lib\features\action_plans\pages\action_plan_detail_page.dart:185).
- Logging/audit side effects: status transitions already write audit logs and enqueue notifications in [UpdateActionPlan.cs](C:\Users\HP\Documents\GitHub\Checkly\server\Features\ActionPlans\UpdateActionPlan.cs:117).
- Exact backend rule evidence:
  - `open` -> `pending_verify` requires `action_plans:write`.
  - `pending_verify` -> `closed` or `open` requires `action_plans:verify`.
- Exact offline constraint:
  - `CachedActionPlans` currently has no `allowedActions` column in [tables.dart](C:\Users\HP\Documents\GitHub\Checkly\lib\_shared\database\tables.dart:110).
  - Shared `ActionGuard` currently falls back to capabilities when `actions == null` in [action_guard.dart](C:\Users\HP\Documents\GitHub\Checkly\lib\_shared\widgets\action_guard.dart:13).

## Lifecycle Context
| State | Detail Page UI | Data Source | Required Behavior |
|---|---|---|---|
| Loading | `CircularProgressIndicator` while `loadSinglePlan()` runs | API or in-memory cache | Do not render action buttons until the DTO is resolved. |
| Empty | "Action plan not found" with go-back action | Missing or inaccessible plan | Preserve current 404-style UX; no speculative buttons. |
| Error | `ErrorDisplayService` for mutation failures; stale-conflict banner remains separate | API 403/409/unknown | Hide protected actions if payload is missing or explicit deny. Do not infer from role alone. |
| Success | `ActionPlanDetailList` plus action area | Server DTO or cached DTO | Render only actions present in `allowedActions`; optimistic offline transitions must also update cached `allowedActions`. |

## Risk Assessment
| Risk | Severity | Why it matters | Mitigation |
|---|---|---|---|
| Shared `ActionGuard` fallback regression | High | A global fail-closed change could hide existing Submission actions offline. | Do not modify the global `ActionGuard`; create an Action Plan scoped wrapper instead. |
| Drift schema migration error | Medium | Missing or malformed cached JSON would break offline Action Plan detail screens after upgrade. | Add a dedicated migration test and use nullable parsing with safe fallback. |
| Optimistic action drift | Medium | After offline submit/verify/reject, buttons may remain stale until sync if local actions are not recomputed. | Define explicit local transition mappings in the domain/manager layer and inject default actions for locally created pending entities. |
| File size / maintainability regression | Medium | `action_plan_detail_page.dart` and `action_plan_manager.dart` already exceed the workflow threshold. | Split both before adding new logic. |
| Backend contract inconsistency across endpoints | Medium | List/detail/update returning different action sets would produce non-deterministic UI. | Centralize action-key rules and test all three endpoint shapes together. |

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| AP-PBAC-01 | `GET /api/action-plans returns allowedActions for open plans visible to a store manager with action_plans:write.` | Success | `ActionPlanDto` does not expose `allowedActions` today. |
| AP-PBAC-02 | `GET /api/action-plans/{id} returns allowedActions for pending_verify plans visible to an auditor with action_plans:verify.` | Success | Single-item endpoint maps `CreateActionPlan.ToDto(plan)` with no action list. |
| AP-PBAC-03 | `GET /api/action-plans returns explicit deny ([] or view-only) for users who can see a plan but cannot mutate that status.` | Success | Frontend currently decides from `PolicyManager`, not backend payload. |
| AP-PBAC-04 | `PUT /api/action-plans/{id} returns the updated ActionPlanDto with recomputed allowedActions after submit evidence.` | Success | Update endpoint returns DTO without action recomputation. |
| AP-PBAC-05 | `PUT /api/action-plans/{id} returns the updated ActionPlanDto with recomputed allowedActions after verify close.` | Success | Same as above; client cannot trust response to repaint buttons. |
| AP-PBAC-06 | `ActionPlanDto.fromJson parses allowedActions and preserves it through optimistic state copies.` | Success | Flutter DTO lacks the field entirely. |
| AP-PBAC-07 | `CachedActionPlans persists allowedActions as JSON so offline detail screens survive app restart.` | Success | Drift table and migration do not store the field. |
| AP-PBAC-08 | `Offline cached action plans loaded from Drift rehydrate allowedActions back into ActionPlanDto.` | Success | Manager cache-read path rebuilds DTOs without any action list. |
| AP-PBAC-09 | `ActionPlan submitEvidence optimistic state rewrites allowedActions so the same user no longer sees submit after moving to pending_verify.` | Success | Domain transitions rebuild DTOs manually and have no action payload handling. |
| AP-PBAC-10 | `ActionPlanDetailPage hides Submit Evidence when allowedActions omits submit_evidence even if PolicyManager says action_plans:write.` | Success | Page currently checks `PolicyManager` directly. |
| AP-PBAC-11 | `ActionPlanDetailPage shows Verify and Reject only when allowedActions contains those exact actions.` | Success | Page/action bar currently branches on local booleans. |
| AP-PBAC-12 | `If the Action Plan DTO has no allowedActions payload, ActionPlanActionGuard fails closed without changing the shared ActionGuard fallback behavior used by other modules.` | Error / Success | Current shared guard falls back to capabilities, so Action Plans need their own scoped wrapper. |
| AP-PBAC-13 | `Drift migration from schema v27 keeps existing cached action plan rows readable after adding cached_allowed_actions.` | Loading / Success | Schema bump is required and currently untested for this new column. |
| AP-PBAC-14 | `The /plans route and deep links keep using existing navigation paths; no new route is introduced.` | Success | Prevents accidental route drift while refactoring the detail UI. |

## Test Fixture & Payloads
Required test fixture state:
- Seeded `store_manager` with store assignment and `action_plans:write`.
- Seeded `auditor` with ownership of the linked submission and `action_plans:verify`.
- Seeded `area_manager` assigned through `ProfileStoreAssignment` when verify behavior needs store-scoped access.
- Seeded `admin` only if the "override submit while also able to verify" branch is preserved.
- Drift DB at schema v27 upgraded to v28 with at least one pre-existing `cached_action_plans` row.

Example API response for open plan:
```json
{
  "id": "4a1a2b5a-0eb8-4d4b-b9bf-5c7858f4d6a4",
  "submissionId": "ecff6855-d0ef-4ee2-9104-c2a8df991111",
  "storeId": "e4c4445a-17f1-43fd-b5b2-52912ee92222",
  "storeName": "Store 7",
  "criteriaLabel": "Food Safety",
  "groupTitle": "Hygiene",
  "status": "open",
  "allowedActions": ["view", "submit_evidence"],
  "createdAt": "2026-05-16T05:30:00Z",
  "updatedAt": "2026-05-16T05:30:00Z"
}
```

Example API response for pending verification:
```json
{
  "id": "4a1a2b5a-0eb8-4d4b-b9bf-5c7858f4d6a4",
  "status": "pending_verify",
  "allowedActions": ["view", "verify_close", "reject_evidence"],
  "evidenceSubmittedAt": "2026-05-16T05:45:00Z",
  "evidenceSubmittedByName": "store.manager"
}
```

Example mutation request:
```json
{
  "status": "pending_verify",
  "correctionPlan": "Replace damaged seal",
  "evidenceNote": "New seal installed"
}
```

Example cached Drift payload:
```json
["view", "submit_evidence"]
```

## Tools & Commands
Skills required:
- `enterprise-authorization`
- `use-case-slicing`
- `tdd`
- `testing-strategy`

Primary commands:
- `rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~ListActionPlansTests|FullyQualifiedName~PbacEnforcementTests|FullyQualifiedName~ActionPlan"`
- `rtk flutter test test/features/action_plans`
- `rtk flutter test test/unit/widgets/action_guard_test.dart`
- `rtk flutter test test/_shared/database`
- `rtk dart run build_runner build --delete-conflicting-outputs`

## Verification Plan
- Verify server contract first with focused integration tests for list/detail/update payloads and permission combinations.
- Verify Flutter DTO parsing and Drift migration separately before touching the page UI.
- Regenerate Drift output and run targeted Action Plan widget tests after the file split.
- Run one final focused server test pass plus targeted Flutter suites, then a broader `flutter test test/features/action_plans` sweep.

## Proposed Changes
| Status | File Path | Purpose |
|---|---|---|
| [NEW] | `server/Features/ActionPlans/ActionPlanActions.cs` | Canonical action keys mirroring Flutter constants. |
| [MOD] | `server/Features/ActionPlans/Dtos.cs` | Add `AllowedActions` to `ActionPlanDto`. |
| [MOD] | `server/Features/ActionPlans/CreateActionPlan.cs` | Replace plain `ToDto` usage with caller-aware action mapping entry point. |
| [MOD] | `server/Features/ActionPlans/ListActionPlans.cs` | Compute allowedActions during list projection without N+1 queries. |
| [MOD] | `server/Features/ActionPlans/GetActionPlan.cs` | Compute allowedActions for detail payloads. |
| [MOD] | `server/Features/ActionPlans/UpdateActionPlan.cs` | Return recomputed allowedActions after mutations. |
| [NEW] | `server/tests/Checkly.Api.Tests/Features/ActionPlans/ActionPlanAllowedActionsTests.cs` | Integration coverage for list/detail/update action mapping. |
| [MOD] | `server/tests/Checkly.Api.Tests/ListActionPlansTests.cs` | Assert new payload field does not break current list contracts. |
| [NEW] | `lib/_shared/constants/action_plan_actions.dart` | Strongly typed action keys for Flutter. |
| [MOD] | `lib/features/action_plans/model/action_plan_dto.dart` | Parse and hold nullable `allowedActions`. |
| [MOD] | `lib/features/action_plans/domain/action_plan.dart` | Preserve or recompute allowedActions during optimistic transitions. |
| [MOD] | `lib/features/action_plans/manager/action_plan_manager.dart` | Persist/load allowedActions and split cache mapping into a helper because file exceeds 250 lines. |
| [NEW] | `lib/features/action_plans/manager/action_plan_cache_mapper.dart` | Keeps the manager below the size ceiling. |
| [MOD] | `lib/_shared/database/tables.dart` | Add `cachedAllowedActions` JSON column to `CachedActionPlans`. |
| [MOD] | `lib/_shared/database/app_database.dart` | Bump schema version and add v28 migration for the new column. |
| [MOD] | `lib/features/action_plans/pages/action_plan_detail_page.dart` | Remove local PBAC branching after splitting actions/dialog orchestration out. |
| [NEW] | `lib/features/action_plans/widgets/action_plan_detail_actions.dart` | New file required because the current page is 305 lines. |
| [MOD] | `lib/features/action_plans/widgets/action_plan_action_bar.dart` | Consume action keys instead of booleans. |
| [NEW] | `lib/features/action_plans/widgets/action_plan_action_guard.dart` | Action Plan scoped fail-closed wrapper; do not change the global `ActionGuard`. |
| [NEW] | `test/unit/models/action_plan_dto_test.dart` | DTO parsing and optimistic propagation tests. |
| [NEW] | `test/features/action_plans/pages/action_plan_detail_page_pbac_test.dart` | UI contract for render/hide behavior. |
| [NEW] | `test/_shared/database/drift_migration_action_plan_allowed_actions_test.dart` | Schema migration coverage for cached action lists. |
| [NEW] | `test/features/action_plans/widgets/action_plan_action_guard_test.dart` | Verify Action Plan scoped fail-closed behavior without changing shared guard tests. |

UI component mapping:

| Component | Truncation Limit | Overflow Action | Required New Route |
|---|---|---|---|
| `ActionPlanDetailPage` | 250 lines | Move action-area orchestration and dialogs into `action_plan_detail_actions.dart` before adding PBAC logic. | None. Keep `/plans/:id`. |
| `ActionPlanActionBar` | 200 lines | Keep it render-only; no business rule recomputation. | None. |
| `ActionPlanActionGuard` | 150 lines | Create an Action Plan scoped fail-closed wrapper and leave shared `ActionGuard` untouched. | None. |

## Concept Diagram
```text
[Shell Tab /plans] -> [ActionPlansPage] -> tap card -> [/plans/:id]
[/plans/:id] -> [GET /api/action-plans/{id}] -> [ActionPlanDto + allowedActions]
[ActionPlanDto + allowedActions] -> [Drift cached_action_plans.cached_allowed_actions]

[open + submit_evidence] -> [SubmitEvidenceSheet] -> [PUT /api/action-plans/{id}] -> [pending_verify + updated allowedActions]
[pending_verify + verify_close] -> [Verify dialog] -> [PUT /api/action-plans/{id}] -> [closed + view only]
[pending_verify + reject_evidence] -> [Reject dialog] -> [PUT /api/action-plans/{id}] -> [open + recomputed allowedActions]

[notification deep link /action-plans/:id] -> redirect -> [/plans/:id] -> same detail contract
```

## Execution Slices
### Phase A: Backend Action Contract
Complexity: Medium
Reason: Small file count on the server, but touches auth-aware DTO mapping and integration tests.

Pros:
- Moves contextual truth to the backend immediately.
- Reuses the existing submission/program `allowedActions` pattern.

Cons:
- Requires replacing the current `CreateActionPlan.ToDto(plan)` shortcut with a caller-aware mapping path.
- All list/detail/update responses must stay consistent.

**Micro-Spec**
- Plain English Summary: Teach the API to tell Flutter exactly which Action Plan buttons are legal for this user on this specific plan.
- Why this step now?: Flutter cannot remove local PBAC guesses until the API carries the action list.
- Scenario Focus: Basic Scenario.
- Value Delivered: Every Action Plan response includes `allowedActions`, and mutation responses repaint the UI from server truth.
- Entry State Required: Existing Action Plan endpoints are passing and the repo keeps the current route/deep-link contract.
- Exit State Guaranteed: `GET` and `PUT` Action Plan payloads expose deterministic `allowedActions` with no extra per-row DB lookup beyond the existing scoped query.
- Architectural Scope: `server/Features/ActionPlans/*`, backend auth cache, integration tests.
- Acceptance Criteria:

| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| A1 | `ListActionPlans returns submit_evidence for open plans when caller has action_plans:write.` | Success | No server field exists. |
| A2 | `GetActionPlan returns verify_close and reject_evidence for pending_verify plans when caller has action_plans:verify.` | Success | Detail endpoint uses DTO shortcut without actions. |
| A3 | `UpdateActionPlan returns recomputed allowedActions after each status mutation.` | Success | Mutation response cannot currently repaint PBAC state. |
| A4 | `Action list computation does not query per row after materialization beyond existing scoped query inputs.` | Success | Guards against accidental N+1 regression. |

### Phase B: Flutter DTO, Drift Cache, and Offline Transition State
Complexity: High
Reason: Crosses DTO parsing, local schema migration, offline cache hydration, and optimistic transition semantics.

Pros:
- Removes reliance on ephemeral in-memory permissions for detail actions.
- Makes offline detail screens deterministic after restart.

Cons:
- Requires schema bump plus generated Drift output.
- Requires explicit local rules for optimistic transitions and locally created pending entities.

**Micro-Spec**
- Plain English Summary: Store the server's action list locally and carry it through offline state changes so the app does not have to guess which buttons to show.
- Why this step now?: If the cache does not persist `allowedActions`, the UI either regresses offline or is forced back to local PBAC branching.
- Scenario Focus: Basic Scenario plus offline extension.
- Value Delivered: Cached Action Plans keep their action list across app restarts, optimistic transitions still hide/show the correct buttons, and newly created offline pending entities remain locally usable until server sync.
- Entry State Required: Phase A backend contract is complete and action keys are stable.
- Exit State Guaranteed: `ActionPlanDto`, Drift cache, optimistic state transitions, and locally created pending entities all speak the same action vocabulary.
- Architectural Scope: `lib/features/action_plans/model`, `domain`, `manager`, Drift schema, Flutter tests.
- Offline creation rule: If an entity is created locally while offline (`syncStatus == 'pending'`), the local repository MUST inject a default `allowedActions` payload of `['view', 'edit', 'delete']` until the record successfully syncs with the server.
- Acceptance Criteria:

| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| B1 | `ActionPlanDto parses allowedActions from JSON.` | Success | No field exists. |
| B2 | `CachedActionPlans stores allowedActions as serialized JSON.` | Success | No DB column exists. |
| B3 | `Schema migration v28 preserves existing cached rows.` | Loading / Success | New column is absent and untested. |
| B4 | `Offline loadActionPlans rehydrates allowedActions from cache.` | Success | Manager rebuilds DTOs without actions. |
| B5 | `Optimistic submit/verify/reject updates do not lose allowedActions.` | Success | Domain transitions rebuild DTOs manually. |
| B6 | `If an entity is created locally while offline (syncStatus == 'pending'), the local repository injects default allowedActions ['view', 'edit', 'delete'] until the record successfully syncs with the server.` | Success / Loading | The current plan and code do not define default actions for newly created offline pending entities. |

### Phase C: Detail UI Enforcement and File Split
Complexity: High
Reason: Current page is over the line-limit and still contains local authorization branching.

Pros:
- Removes UI drift between frontend assumptions and backend state.
- Keeps protected actions close to the data that authorizes them.

Cons:
- Requires an Action Plan scoped fail-closed wrapper while preserving shared `ActionGuard` behavior for other modules.
- Touches a page already above the workflow size ceiling.

**Micro-Spec**
- Plain English Summary: Refactor the Action Plan detail screen so it renders action buttons from the DTO instead of recalculating permission rules in the page.
- Why this step now?: The UI layer is the last place still making contextual PBAC guesses for Action Plans.
- Scenario Focus: Basic Scenario plus error/empty/loading extensions.
- Value Delivered: Users only see action buttons the current plan payload allows, and the detail page stays readable after the split.
- Entry State Required: Phase B cache and DTO plumbing is complete; the locked guard strategy is an Action Plan scoped wrapper with no global `ActionGuard` change.
- Exit State Guaranteed: `ActionPlanDetailPage` no longer uses local `PolicyManager` for contextual button visibility.
- Architectural Scope: `action_plan_detail_page.dart`, new action helper/widget file, `action_plan_action_bar.dart`, Action Plan scoped guard wrapper, widget tests.
- Acceptance Criteria:

| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| C1 | `Open plan without submit_evidence hides the submit button even when the current user still has action_plans:write globally.` | Success | Page currently reads `PolicyManager`. |
| C2 | `Pending_verify plan with verify_close and reject_evidence shows both verify actions.` | Success | UI currently depends on booleans, not payload. |
| C3 | `Missing or null action payload follows the selected guard strategy consistently.` | Error / Success | Current shared guard falls back to capabilities. |
| C4 | `ActionPlanDetailPage is split below the size threshold before new logic lands.` | Loading / Success | File is 305 lines today. |

## Locked Architectural Choices
### Choice 1: Shared Guard Strategy
Decision: Keep shared `lib/_shared/widgets/action_guard.dart` unchanged for existing modules. Do not change global `ActionGuard` semantics because Submissions still depend on its offline fallback behavior.

Builder instruction: Create an Action Plan scoped wrapper, `ActionPlanActionGuard`, that fails closed for Action Plan contextual actions when `allowedActions` is null, missing, or does not contain the required action.

Rationale:
- Keeps the Action Plan migration aligned with the ADR without widening the blast radius into Submissions.
- Preserves existing offline Submission behavior while Action Plans adopt persisted `allowedActions`.
- Gives the builder one concrete UI enforcement path with no pending decision.

### Choice 2: Optimistic Offline Action Mapping
Decision: Recompute minimal local `allowedActions` during optimistic Action Plan transitions.

Builder instruction: When submit/verify/reject transitions run locally before the server response is available, write the smallest local action list that matches the new local state. Do not set `allowedActions` to null and do not fall back to local `PolicyManager` for contextual Action Plan buttons.

Offline creation instruction: If an entity is created locally while offline (`syncStatus == 'pending'`), the local repository MUST inject a default `allowedActions` payload of `['view', 'edit', 'delete']` until the record successfully syncs with the server.

Rationale:
- Keeps offline screens usable without reviving frontend PBAC guesses.
- Prevents stale buttons from surviving local status transitions.
- Gives the builder a deterministic local-state rule for pending offline records.

## <command_logs>
- `Get-Content -Raw .agents\workflows\analyze-feature.md`
- `Get-Content -Raw docs\architecture\decision_record_20260516_120520_SYN_pbac_ui.md`
- `Get-Content -Raw .agents\active_tasks\pbac_ui\task_20260516_120520_SYN_pbac_ui.md`
- `Get-Date -Format yyyyMMdd_HHmmss`
- `Get-Content -Raw .agents\rules\orchestration-standards.md`
- `Get-Content -Raw .agents\skills\enterprise-authorization\SKILL.md`
- `Get-Content -Raw .agents\skills\use-case-slicing\SKILL.md`
- `rg --files -g "pubspec.yaml" -g "*.csproj" -g "*.sln" -g "package.json"`
- `rg -n "ActionPlanDto|action_plan_detail_page|PolicyManager|ActionGuard|allowedActions|allowed_actions|ActionPlan" lib server test`
- `Get-Content -Raw GEMINI.md`
- `Get-Content -Raw lib\GEMINI.md`
- `Get-Content -Raw server\GEMINI.md`
- `Get-Content -Raw lib\features\action_plans\widgets\GEMINI.md`
- `rg -n "GoRoute|action-plans|ActionPlanDetailPage|ActionPlansPage|PolicyManager|ActionGuard|allowedActions|cachedActionPlans|CachedActionPlans" lib test`
- `cmd /c findstr /n ".*" ...` on the Action Plan, Submission, router, database, and test files cited in this plan.

## Handoff Block
This plan is ready for the builder. The guard strategy is locked: keep the shared `ActionGuard` unchanged and implement an Action Plan scoped wrapper.

Routing commands:
- `@[/atdd] Execute specs for Phase A - Backend Action Contract: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260516_135009_A1B2C3D4_pbac_ui.md`
- `@[/tdd] Execute tests for Phase B - Flutter DTO, Drift Cache, and Offline Transition State: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260516_135009_A1B2C3D4_pbac_ui.md`
- `@[/tdd] Execute tests for Phase C - Detail UI Enforcement and File Split: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260516_135009_A1B2C3D4_pbac_ui.md`

Concurrency:
- Phase B must wait for Phase A because Flutter needs stable backend action keys and payload shape.
- Phase C must wait for Phase B because the detail UI depends on cached and optimistic `allowedActions`.
- Do not schedule a global shared-guard change as part of this work; Submission offline behavior remains out of scope.
