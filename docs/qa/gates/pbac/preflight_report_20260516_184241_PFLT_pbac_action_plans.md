# Preflight Report: PBAC Action Plans Migration

## Summary Counts
- **Total Rules Checked**: 9
- **Automated PASS**: 8
- **Manual Pending**: 1
- **FAIL**: 0

## Automated Results Table
| Rule Category | Check Details | Status | Notes |
|---|---|---|---|
| Dead UX Stubs | Scanned `lib/` for `onPressed: () {}` | PASS | No dead stubs found. |
| Secrets | Scanned for API keys / passwords | PASS | Clean. |
| Formatting | `dart format` & `dotnet format` | PASS | All 445 Dart files and C# files formatted. |
| Tests (Backend) | `dotnet test` | PASS | 505 tests passed. |
| Tests (Frontend)| `flutter test` | PASS | 526 tests passed. |
| The 7 Sync Steps| Entity, DbContext, Server DTO, Endpoints, Sync, Flutter DTO, Capabilities seeded | PASS | End-to-end sync validated. PBAC capabilities seeded in `Program.cs`. |
| Silent Test Fails| Scanned `server/tests/` for `Assert.True(response.IsSuccessStatusCode)` | PASS | 2 existing found but none in modified PBAC files. |
| Orphaned ATDD | Scanned for `fail('Implement...')` | PASS | Clean. |
| Database Wipes | Checked `EnsureDeleted()` guards in tests | PASS | Guard exists in `TestWebApplicationFactory.cs`. |

## Vertical-Slice Completeness Table
| Layer | Component | Status | Notes |
|---|---|---|---|
| Database / Sync | Drift schema `v28` `cached_allowed_actions` | PASS | Migrated and seeded correctly. |
| Server Backend | `CreateActionPlan.cs`, `UpdateActionPlan.cs`, `ActionPlanDto.cs` | PASS | Returns `allowedActions` based on capabilities. |
| Frontend DTO | `action_plan_dto.dart` | PASS | Rehydrates `allowedActions` optimally. |
| Frontend UI | `action_plan_action_guard.dart` | PASS | Action visibility is driven purely by `allowedActions`. |

## Manual Checkboxes
- [ ] **Terminology Map (Audit vs Submission)**: Ensure no inadvertent UI renaming from Audit to Submission.
- [ ] **Interface Drift in Mocks**: Verify `mocktail` interfaces haven't drifted.
- [ ] **.NET Namespace Collisions**: Verify `Entities.Program` isn't colliding.
