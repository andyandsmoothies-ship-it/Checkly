---
ConversationID: 1f32f1ff-d902-44a0-9676-c11521358960
---
# Task Ledger: Deepen Scoring and Audit

**Target Files:**
- `server/Common/Scoring/ScoringCalculators.cs` (to be deleted)
- `server/Common/Scoring/ScoringVerifier.cs`
- `server/Common/Scoring/IScoringStrategy.cs` (new)
- `lib/features/audit/manager/audit_manager.dart`
- `lib/features/audit/manager/scoring_state_notifier.dart` (new)
- `lib/features/audit/manager/draft_persistence_manager.dart` (new)

**Test Files:**
- `server/Api.UnitTests/Common/Scoring/ScoringVerifierTests.cs`

## Slice 1: Backend Scoring Engine Abstraction
- [ ] Create `ScoringContext`, `IScoringStrategy`, and `ScoringEngineFactory` interfaces/classes.
- [ ] Implement `PenaltyScoringStrategy`, extracting `VerifyPenalty`.
- [ ] Implement `ChecklistScoringStrategy`, extracting `VerifyChecklist`.
- [ ] Implement `AccumulationScoringStrategy`, extracting `VerifyAccumulation`.
- [ ] Update `ScoringVerifier` to use `ScoringEngineFactory`.
- [ ] Delete `ScoringCalculators.cs`.
- [ ] Run backend tests: `dotnet test`.

## Slice 2: Frontend State Decomposition
- [ ] Extract `DraftPersistenceManager` from `AuditManager` to handle offline draft saving/restoring.
- [ ] Extract `ScoringStateNotifier` from `AuditManager` to handle live score computation and sections.
- [ ] Refactor `AuditManager` to act purely as an orchestrator/coordinator.
- [ ] Update `locator.dart` to register the new managers.
- [ ] Run frontend widget/unit tests: `flutter test`.

## Completion
- [ ] Verify both C# and Dart test suites are green.
