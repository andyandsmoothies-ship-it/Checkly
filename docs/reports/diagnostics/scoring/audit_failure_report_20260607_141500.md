# Failure Report: Scoring & Audit Refactor Flop Audit
ConversationID: 1f32f1ff-d902-44a0-9676-c11521358960

## 1. First Principles Gate

### Physics & Limit
- **C# Scoring Strategy Context**: Allocating a `ScoringContext` record on every verification path. While EF Core and GC are highly optimized for short-lived records, at extremely high concurrency (e.g., 50k+ TPS on a single host), high allocation rates could cause GC thrashing. However, the current API throughput is limited by DB connection pools, making this a secondary limit.
- **Flutter Debouncing**: Draft persistence relies on a 3-second debounce. If the user typing speed exceeds the debounce logic or the app is closed immediately after an answer change (before the debounce flushes), the last changes might not be persisted. To mitigate, we must ensure `dispose` or App Lifecycle changes trigger a synchronous flush (already handled by `forceSave` on teardown).

### Simplicity
- **Design Options**:
  1. **Option A (Separate GetIt Registrations)**: Registering `DraftPersistenceManager` and `ScoringStateNotifier` as separate managers in `locator.dart`. *Drawback*: Requires extensive boilerplate for forwarding methods or forces the UI to watch three distinct managers, significantly increasing wiring complexity.
  2. **Option B (Part Files - Recommended)**: Use Dart `part` and `part of` files for `audit_manager_scoring.dart` and `audit_manager_draft_persistence.dart` within the `AuditManager` module. *Benefit*: Keeps the public interface of `AuditManager` intact, meaning zero changes to existing UI widgets or widget tests, while successfully separating the logic into distinct files.

### Blast Radius
- **Backend Scoring Failure**: If `ScoringEngineFactory` fails to resolve a strategy, submissions will fail verification.
- **Frontend Draft Corruptions**: If a SQLite draft is written in a corrupted format, the app could crash upon restart. The restore logic must catch exceptions and skip corrupted answers (already implemented in `_restoreDraftLogic`).

### Observability
- Existing warning telemetry in `CreateSubmission.cs` catches mismatching score calculations.
- Test coverage on `ScoringVerifierTests.cs` and `audit_manager_test.dart` acts as the primary observability safety net.

---

## 2. Discovered Failure Modes (Flops)

### 🔴 Critical
1. **Factory Resolution Mismatch (Checklist Fallback)**:
   - *Failure Mode*: If an unrecognized scoring direction is passed from the template config, the factory could throw a `SwitchExpressionException` or null reference, crashing the submission endpoint.
   - *Mitigation*: The factory switch expression must have a default fallback case that resolves to `ChecklistScoringStrategy` instead of crashing.

### 🟡 Warning
2. **Flutter Interface Drift**:
   - *Failure Mode*: Extracting `ScoringStateNotifier` and `DraftPersistenceManager` as separate managers in `locator.dart` will break existing widget tests and UI files that expect these fields to live directly on `AuditManager`.
   - *Mitigation*: Implement the modularization using `part` files. Keep the public API of `AuditManager` identical to preserve backwards compatibility.

---

## 3. Action Plan

- **AP-01 (C# Fallback)**: Ensure `ScoringEngineFactory` includes a default discard case (`_ => new ChecklistScoringStrategy()`) to prevent route crashes on invalid scoring configurations.
- **AP-02 (Dart Part Files)**: Rather than adding new classes to `locator.dart`, implement the sub-managers as part of the existing `part` file structure of `AuditManager` to prevent breaking existing UI bindings and tests.
