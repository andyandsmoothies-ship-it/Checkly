# Implementation Plan: Deepen Scoring and Audit

<latent_space_scratchpad>
**Constraint Check**:
- C# Candidate 3 involves deep refactoring of scoring calculation. The logic is strictly pure and heavily unit tested. The new `IScoringStrategy` must use the `ScoringContext` object designed in the report.
- Dart Candidate 2 involves decoupling `AuditManager`. Refactoring `ChangeNotifier` requires ensuring that widgets currently listening to `AuditManager` for score updates now listen to `ScoringStateNotifier`, and draft restores listen to `DraftPersistenceManager`.
- Since Dart `provider` is used (based on `ChangeNotifier`), we might need to expose these as separate providers or use ProxyProvider, but Checkly uses `get_it` and `watch_it` based on the `.agents/skills/flutter-architecture/SKILL.md` (PFA). If PFA is used, `AuditManager` is likely a get_it singleton or factory.
- Yes, `AuditManager` is part of PFA. So splitting it into `DraftPersistenceManager` and `ScoringStateManager` means registering them in `locator.dart` and injecting them into `AuditManager` or watching them directly from the UI.
</latent_space_scratchpad>

## Input Lineage
`c:\Users\HP\Documents\GitHub\Checkly\docs\reports\deepen\whole_project\report_deepen_whole_project_final.md`

## Executive Summary & Out of Scope
**Goal:** Implement the "Procedural Scoring Engine" refactor (C#) and the "Audit God Class" decomposition (Dart) to eliminate architectural friction and increase component depth.
**Out of Scope:** We will NOT change any actual scoring mathematics or draft saving logic. This is a pure structural refactor. We will NOT implement the Unified Outbox Manager or Fat Submission Handler refactors.

## First Principles Gate
1. **Physics & Limit:** The limit is code readability and testing overhead. `AuditManager` does too many things (SQLite + UI + Math), and `ScoringCalculators.cs` relies on large branching logic that makes adding new scoring modes risky.
2. **Simplicity:** The simplest way is to leave it alone. We should NOT do that because adding new scoring features or offline logic in the future will compound technical debt and blast radius.
3. **Blast Radius:** If the C# Scoring Engine fails, the backend will reject valid scores or pass invalid ones. If the Dart Audit Manager refactor fails, the form UI will not rebuild correctly, or drafts will fail to save.
4. **Observability:** Backend unit tests for scoring must remain 100% green. Dart widget tests and unit tests for draft persistence must pass. 

## Six-Dimensional Impact Assessment
1. **Technical & Regression:** High regression risk. Existing tests must be preserved and run before/after.
2. **Functional:** No functional product change. 
3. **Operational & Cost:** Minimal impact. C# Context allocation might add a few bytes of GC pressure, but negligible.
4. **User Friction:** Zero changes to UX.
5. **Business Operations:** Zero impact.
6. **Regulatory & Security:** Scoring math remains identical, ensuring compliance constraints hold.

## System Context
- **C# Backend:** Pure functional layer.
- **Dart Frontend:** Offline-first form states.

## Lifecycle Context
- **Success:** Forms score correctly, drafts save.
- **Error:** N/A (Internal refactor).
- **Empty:** N/A.
- **Loading:** N/A.

## Constraint Traceability
| Constraint | Test Contract |
| :--- | :--- |
| Extract `IScoringStrategy` | TC-01 |
| Preserve existing scoring logic | TC-02 |
| Extract `ScoringStateNotifier` | TC-03 |
| Extract `DraftPersistenceManager` | TC-04 |

## Test Contracts
| ID | Description | State Matrix | Fail-First |
| :--- | :--- | :--- | :--- |
| TC-01 | `ScoringEngineFactory` resolves correct strategy. | Input: Penalty template. Output: `PenaltyScoringStrategy` instance. | Ensure factory throws on unknown mode. |
| TC-02 | Existing C# scoring tests pass. | All existing unit tests covering `ScoringCalculators`. | Run existing tests before changing code. |
| TC-03 | Flutter UI updates score on answer change. | UI triggers `ScoringStateNotifier.recalculate()`. | Score must update dynamically. |
| TC-04 | Audit form saves and restores draft. | `DraftPersistenceManager.save()` and `.restore()`. | Draft resumes correctly upon app restart. |

## Test Fixture & Payloads
- **C#**: Existing `ScoringVerifierTests.cs`.
- **Dart**: Existing `audit_manager_test.dart` and `audit_form_page_test.dart`.

## Tools & Commands
- `dotnet test`
- `flutter test`

## Proposed Changes
**Backend (C#):**
1. `[NEW] server/Common/Scoring/IScoringStrategy.cs` - Define interface and `ScoringContext` record.
2. `[NEW] server/Common/Scoring/Strategies/PenaltyScoringStrategy.cs` - Extracted from `VerifyPenalty`. If `isWeighted` is false, it delegates to `ChecklistScoringStrategy`.
3. `[NEW] server/Common/Scoring/Strategies/ChecklistScoringStrategy.cs` - Extracted from `VerifyChecklist`.
4. `[NEW] server/Common/Scoring/Strategies/AccumulationScoringStrategy.cs` - Extracted from `VerifyAccumulation`.
5. `[NEW] server/Common/Scoring/ScoringEngineFactory.cs` - Resolves strategies based on config. Must fallback to `ChecklistScoringStrategy` on unmapped/null/empty scoreDirection configs.
6. `[MOD] server/Common/Scoring/ScoringVerifier.cs` - Refactor to use Factory. Delete `ScoringCalculators.cs`.

**Frontend (Dart):**
7. `[NEW] lib/features/audit/manager/scoring_state_notifier.dart` - Extracts `liveScore`, `sectionScores`, and `_scoreDebounceTimer`.
8. `[NEW] lib/features/audit/manager/draft_persistence_manager.dart` - Extracts `DraftService`, `_draftKey`, and `_pendingDraft`.
9. `[MOD] lib/features/audit/manager/audit_manager.dart` - Decomposes internal logic to use `ScoringStateNotifier` and `DraftPersistenceManager`. To prevent UI breaking and widget test failures, `AuditManager` will delegate properties (`liveScore`, `sectionScores`) and functions (`saveDraft`, `restoreDraft`) to the new managers. Accepts optional sub-manager instances in constructor for test mocking.
10. `[MOD] lib/locator.dart` - No changes needed to global GetIt registrations since the sub-managers are encapsulated within `AuditManager` via optional DI constructor parameters.

## Concept Diagram
```text
[ScoringVerifier] --> [ScoringEngineFactory]
                             |
         -----------------------------------------
         |                   |                   |
  [PenaltyStrategy]  [ChecklistStrategy]  [AccumulationStrategy]
```

## Execution Slices

### Slice 1: Backend Scoring Engine Abstraction
- **Summary:** Create `ScoringContext`, `IScoringStrategy`, and `ScoringEngineFactory`. Move existing logic into `PenaltyScoringStrategy`, `ChecklistScoringStrategy`, and `AccumulationScoringStrategy`.
- **Entry State:** Procedural `ScoringCalculators.cs` exists.
- **Exit State Guaranteed:** Procedural class is deleted, `ScoringVerifier` uses the factory. Existing tests pass perfectly.
- **Complexity:** Medium (Refactoring)

### Slice 2: Frontend State Decomposition
- **Summary:** Extract `ScoringStateNotifier` and `DraftPersistenceManager` from `AuditManager` as dedicated helper classes instantiated internally by `AuditManager` (with optional constructor arguments to preserve mockability in testing). Expose getter/setter delegators on `AuditManager` so the public interface is fully preserved.
- **Entry State:** God class `AuditManager`.
- **Exit State Guaranteed:** Internal logic cleanly decomposed into sub-managers. Public API identical. All existing widget, unit, and integration tests pass green.
- **Complexity:** Medium-High

## Handoff Block
Path: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\deepen_scoring_and_audit\implementation_plan_deepen_scoring_and_audit_20260607_135500.md`

- **Slice 1**: Backend Scoring Engine -> **Write Unit Tests** (update existing) -> **Build**
- **Slice 2**: Frontend State Decomposition -> **Build** -> **Test**

**Agent Mission Brief:**
Refactor the C# Scoring Engine into an `IScoringStrategy` pattern with safe fallback handling, and decompose the Dart `AuditManager` into focused helper classes (`DraftPersistenceManager`, `ScoringStateNotifier`) instantiated internally with property/method delegation to keep the public interface unchanged.

**Next Workflow Command:**
Please run: `/implement c:\Users\HP\Documents\GitHub\Checkly\docs\features\deepen_scoring_and_audit\implementation_plan_deepen_scoring_and_audit_20260607_135500.md`
