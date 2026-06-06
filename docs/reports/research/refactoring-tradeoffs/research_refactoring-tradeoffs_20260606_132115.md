---
ConversationID: 98883c69-9a72-433e-88d5-9df601e48cd1
Date: 2026-06-06
Topic: Refactoring Tradeoffs Research
---

# Research: Refactoring Tradeoffs

[ORIGIN_IDEA]: The user wants to explore and identify the exact trade-offs for Candidate 1 (Boardroom analytics query consolidation), Candidate 2 (Campaign Dashboard page decomposition), and Candidate 3 (SyncEngine execution loop decoupling) before proceeding with implementation.

<latent_space_scratchpad>
Thinking through deep architectural tradeoffs for each candidate:
1. Candidate 1 (BoardroomReportService):
   - Option A (Strict native fit): Use helper methods or extension methods to reuse LINQ logic.
     * Pros: Low change footprint. No service registration or DI modifications needed.
     * Cons: Shallow abstraction. Calling code still manages DbContext query evaluation.
   - Option B (Pragmatic balance): Introduce IBoardroomReportService.
     * Pros: Deep abstraction, high leverage. Hides database query details completely. Easily mockable for testing.
     * Cons: Adds a service class and DI registrations.
     * Decision: Option B is superior because it creates a robust architectural seam and achieves clean separation of concerns.

2. Candidate 2 (Campaign Dashboard UI):
   - Option A (Strict native fit): Extract widgets into local files within the features widgets directory.
     * Pros: Keeps component logic localized within the 'programs' feature folder.
     * Cons: Misses opportunities to share widgets that could benefit other parts of the dashboard.
   - Option B (Pragmatic balance): Extract DropdownFilterPill as a generic primitive widget.
     * Pros: Builds reusable UI primitives.
     * Cons: Relocating to a shared directory increases coupling across features for visual details.
     * Decision: Option A is better for local widgets (since the filter sheet counts are highly specific to program statuses), but we must strictly keep the files small.

3. Candidate 3 (SyncEngine loop):
   - Option A (Strict native fit): simple try-catch block inside the loop, logging failures and throwing an aggregate exception at the end.
     * Pros: Simple, preserves current interface state (idle/error), doesn't touch other files.
     * Cons: UI only knows "an error occurred" but not which module failed.
   - Option B (Pragmatic balance): Emitting detailed module sync events.
     * Pros: Allows rich UX feedback (e.g. showing failure badge specifically on action plans).
     * Cons: Requires extending the SyncEngine interface and modifying all UI state consumers.
     * Decision: Option A is the most pragmatic way to solve the primary bug (Poison Pill) without creating a large footprint.
</latent_space_scratchpad>

## E2E Workflow Maps

### Candidate 1: Query Execution Flow
```
[GetBodReport] ──(Query Parameter Dto)──> [BoardroomReportService] ──> [Query db.Submissions] ──> [Database]
                                                                   ──> [Query db.ActionPlans]
                                                                   ──> [Query db.SectionScores]
```

### Candidate 3: Sync Engine Execution Flow
```
[SyncEngine.requestSync]
         │
         ▼
[Loop through modules]
         │
         ├──► [Execute Module A] ──(Throws Exception)──► [Log & Add to errors list] ──(Continue)
         │
         ├──► [Execute Module B] ──(Success)─────────────────────────────────────────(Continue)
         │
         ▼
[Check errors list] ──(Not Empty)──► [Throw Aggregate Exception] ──► [Set state to SyncState.error]
```

---

## Pugh Decision Matrices

### Candidate 1: Boardroom Report Consolidation
* **Option A**: Static LINQ Expression Helpers.
* **Option B**: Fully Encapsulated `BoardroomReportService` (Chosen).

| Criteria | Status Quo | Option A | Option B |
|---|---|---|---|
| Cognitive Complexity | 0 | +1 | +2 |
| Testability (Mocking) | 0 | 0 | +2 |
| Locality of Query Logic | 0 | +1 | +2 |
| Interface Depth (Leverage) | 0 | +1 | +2 |
| **Total Score** | **0** | **+3** | **+8** |

### Candidate 2: UI Decomposition
* **Option A**: Local Feature widgets (`/features/programs/pages/widgets/`) (Chosen).
* **Option B**: Global UI Primitives (`/_shared/widgets/primitives/`).

| Criteria | Status Quo | Option A | Option B |
|---|---|---|---|
| Page Code Size | 0 | +2 | +2 |
| Feature Encapsulation | 0 | +2 | -1 |
| Reusability | 0 | 0 | +2 |
| Locality of Logic | 0 | +2 | +1 |
| **Total Score** | **0** | **+6** | **+4** |

### Candidate 3: Sync Loop Decoupling
* **Option A**: Loop Continue + End Aggregate Throw (Chosen).
* **Option B**: Sync Event Emitter + Detailed UX states.

| Criteria | Status Quo | Option A | Option B |
|---|---|---|---|
| Single Point of Failure Fix | 0 | +2 | +2 |
| Implementation Footprint | 0 | +2 | -1 |
| Test Maintenance Effort | 0 | +1 | -1 |
| Interface Simplicity | 0 | +2 | -1 |
| **Total Score** | **0** | **+7** | **-1** |

---

## Impact Spectrum
- **High Impact**: Candidate 3 (SyncEngine sequential loop decoupling) modifies core sync logic. Failure here blocks all offline synchronization.
- **Medium Impact**: Candidate 1 (BoardroomReportService query consolidation) modifies boardroom analytics query resolution. Let's make sure it doesn't affect other analytics.
- **Low/Safe Impact**: Candidate 2 (Campaign Dashboard UI decomposition) is purely visual.

---

## Risk Assessment

### Candidate 1 (BoardroomReportService)
* **Scale Limit**: Executing multiple complex queries sequentially inside a single service call could cause latency to stack up, especially under high concurrency.
* **Catastrophic Failure**: Parallelizing queries using `Task.WhenAll` on a single scoped DbContext instance will trigger an `InvalidOperationException` due to thread safety limits. Queries must run sequentially or resolve distinct DbContext instances.
* **Rules Conflict**: Namespace collisions with other generic `Program` or `Task` models must be handled by using fully qualified namespaces.

### Candidate 2 (UI Decomposition)
* **Scale Limit**: Rebuilding decoupled stateless widgets in deep lists can lead to layout updates if context is not cached.
* **Catastrophic Failure**: Laying out `DropdownFilterPill` in an unconstrained horizontal row can throw layout overflow exceptions in widget testing.
* **Rules Conflict**: Tests asserting precise types (like `find.byType(ElevatedButton)`) will fail if custom wrappers change widget structures.

### Candidate 3 (Sync Loop Decoupling)
* **Scale Limit**: Appending error stack traces continuously in memory can lead to high resource consumption under repeated offline synchronization loops.
* **Catastrophic Failure**: If Module A fails due to local database corruption, succeeding modules that depend on Module A's database state may operate on corrupted or stale data.
* **Rules Conflict**: Overriding test assertions that enforce loop termination will require updating `TC-PLUGIN-3`.

## Blind Spots
1. **Gotcha: Token-Driven UI Primitives**: For Candidate 2, any extracted widgets must load visual design tokens from theme extensions using default fallbacks to prevent widget test crashes when theme extensions are null.
2. **Gotcha: PostgreSQL Null Inequality translation bug**: For Candidate 1, LINQ queries that compare statuses must be written with null safeguards (e.g. `s.ReviewStatus == null || s.ReviewStatus != "rejected"`) to prevent PostgreSQL from dropping records where the review status is null.
3. **Gotcha: Outbox Delegation**: For Candidate 3, bypassing or mutating the synchronization sequence might lead to outbox sync failures if the dependencies between sync modules are not strictly respected.

## Conflicts with Rules
- Candidate 1 conflicts with the rule "Do not extract shared helpers unless used in 3+ places". However, this is query consolidation, not a generic helper, so we justify this.
- Candidate 2 must be careful to keep files under 400 lines and functions under 30 lines.
- Candidate 3 conflicts with the rule "Never write tests and main code in the exact same prompt cycle". We must adhere to ATDD/TDD flow.

## Handoff Block

* **Final Verdict**: **Viable**. Proceed with implementing Candidate 2 and Candidate 3 first to clean up line limits and runtime failures, followed by Candidate 1.
* **Effort Sizing**: Track C (Architectural refactoring).
* **AI Agent Mission Brief**: Implement the proposed refactorings. Decouple page layout widgets in Dart, convert the sequential synchronization loop to continue on failures, and unify boardroom queries in C#.

<forensic_evidence>
I executed a `grep_search` and `view_file` on C# files:
- `server/Features/Analytics/GetBodReport.cs`
- `server/Features/Analytics/GetAreaBodReport.cs`
- `server/Features/Analytics/BodReportCalculator.cs`
I executed a `view_file` on Dart files:
- `lib/features/programs/pages/program_dashboard_page.dart`
- `lib/_shared/services/sync_engine.dart`
</forensic_evidence>
