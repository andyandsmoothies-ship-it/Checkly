[Walkthrough] -> [Server PBAC DTO] -> [Flutter DTO/Drift Cache] -> [UI Guard] -> [Global CI Gate]

## Input Lineage
- Verified artifact: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\walkthrough_pbac_action_plans_epic.md`
- Implementation plan: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260516_135009_A1B2C3D4_pbac_ui.md`
- Task tracker: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\pbac\task_20260516_181209_A1B2C3D4_verify_pbac_action_plans.md`

## Verdict
**FAIL - mandatory /diagnose transition required.**

The Action Plan-focused PBAC tests pass, but the walkthrough cannot be verified as globally safe because:
- Global Flutter tests fail with 2 router regressions.
- Dart format verification fails on 7 files.
- .NET format verification fails on a migration file encoding error.
- The walkthrough overstates at least two live behaviors: create-response action projection and offline/optimistic close/reject handling.

## Acceptance Criteria Trace
| Area | Status | Evidence |
|---|---:|---|
| Phase A server `allowedActions` constants and DTO | PASS | `server\Features\ActionPlans\ActionPlanActions.cs`; `Dtos.cs` includes `IReadOnlyList<string> AllowedActions`. |
| Phase A list/detail/update projections | PASS | `ListActionPlans.cs:89`, `GetActionPlan.cs:59`, `UpdateActionPlan.cs:214` call `CreateActionPlan.ToDto(..., callerCapabilities)`. |
| Phase A create projection | FAIL | `CreateActionPlan.cs:71` returns `ToDto(plan, new HashSet<string>())`, so create responses cannot include caller-aware actions. |
| Phase B Flutter DTO/cache/migration | PASS | `ActionPlanDto.allowedActions`; `CachedActionPlans.cachedAllowedActions`; `schemaVersion => 28`; `ActionPlanCacheMapper` encodes/decodes JSON. |
| Phase B manager cache read OOM guard | PASS | `ActionPlanManager.loadActionPlans()` reads `cachedActionPlans` with `limit(500)`. |
| Phase B optimistic transitions | PARTIAL | Domain recomputes actions, but manager `closePlan`/`rejectEvidence` simply return `_api.updateActionPlan(...)` at `action_plan_manager_transitions.dart:90` and `:110`; no offline queue or in-memory patch there. |
| Phase C action guard | PASS | `ActionPlanActionGuard` checks only `plan.allowedActions` and fails closed when null/missing. |
| Phase C detail page split | PASS | `action_plan_detail_page.dart` is 155 lines; page delegates actions to `action_plan_detail_actions.dart`. |

## Quantitative Metrics Dashboard
| Metric | Result |
|---|---:|
| Flutter analyze | PASS, no issues |
| Server build | PASS, 0 warnings, 0 errors |
| Global Flutter tests | FAIL, 524 passed / 2 failed |
| Global .NET tests | PASS by exit code (`dotnet test --no-build`) |
| Focused Flutter Action Plan tests | PASS, 59 passed |
| Focused server Action Plan tests | PASS, 48 passed |
| Dart format check | FAIL, 7 files would change |
| .NET format check | FAIL, `20260515170957_AddActionPlanSourceTitle.cs` CHARSET |
| NuGet vulnerability scan | PASS, no vulnerable packages |
| Focused Flutter coverage | 1602 / 24000 lines = 6.68% |
| Focused .NET coverage | line-rate 0.0541, branch-rate 0.213 |

## CI Evidence
```text
flutter analyze ..
No issues found! (ran in 27.1s)

dotnet build --no-restore
Build succeeded.
0 Warning(s)
0 Error(s)

flutter test ..\test --reporter=expanded
Expected: <1> Actual: <2> at test\_shared\router\app_router_test.dart:107
Expected: <2> Actual: <3> at test\_shared\router\app_router_test.dart:111
Some tests failed. Final observed count: +524 -2.

dotnet test tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --no-build --filter "FullyQualifiedName~ActionPlan"
Test Run Successful. Total tests: 48 Passed: 48.

flutter test ..\test\features\action_plans ..\test\unit\models\action_plan_dto_test.dart ..\test\_shared\database\drift_migration_action_plan_allowed_actions_test.dart
All tests passed. Total observed: 59.
```

## Hostile Interrogation
| Persona | Score | Finding |
|---|---:|---|
| DB Architect | 8/10 | Active Action Plan Drift reads are bounded. List endpoint paginates. No N+1 found in action projection because capabilities are resolved once per request. |
| Security Auditor | 7/10 | Backend update/detail/list paths use access scoping and server-computed actions. Create response action projection is not caller-aware, and create endpoint remains auth-only at route level. |
| Junior Dev | 7/10 | The mapper split improves readability. Remaining risk: domain transition behavior and manager mutation behavior differ for close/reject, which makes offline semantics harder to reason about. |

## Boundary Sync Check
- Server PDP: `CreateActionPlan.ToDto` computes actions from plan status plus caller capabilities.
- Flutter PEP: `ActionPlanActionGuard` renders only when `allowedActions` contains the required action.
- Local store: Drift persists serialized actions in `cached_allowed_actions`, and `ActionPlanCacheMapper.fromRow` rehydrates them.
- Gap: background sync `ActionPlanSyncModule` pushes queued evidence but does not persist returned `allowedActions` back into `CachedActionPlans`; cache refresh depends on later pull/list reload.

## Required /diagnose Targets
1. Fix global Flutter router failures in `test\_shared\router\app_router_test.dart:107` and `:111`, or update the router/tests intentionally if the tab model changed.
2. Run Dart formatter on the 7 files reported by `dart format --output=none --set-exit-if-changed`.
3. Fix server migration encoding reported by `dotnet format --verify-no-changes`: `server\Common\Persistence\Migrations\20260515170957_AddActionPlanSourceTitle.cs`.
4. Decide whether `CreateActionPlan` must return caller-aware `allowedActions`; current code returns view-only because it passes an empty capability set.
5. Decide whether verify/reject require offline optimistic handling or whether the walkthrough should be corrected to describe online-only manager behavior.

## Next Command
`@[/diagnose] C:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\pbac\verification_20260516_181209_A1B2C3D4_verify_pbac_action_plans.md`
