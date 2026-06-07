---
type: report
topic: whole_project
date: 2026-06-07
---

# Architectural Deepening Review: Checkly Final Master Report

This report consolidates the highest-leverage architectural deepening opportunities across the Checkly platform, focusing on turning shallow, coupled modules into deep, testable seams.

```text
[UI] ────(Calculates Score)────> [Dart ScoringEngine]
                                         ▲
                                   (Must Match)
                                         ▼
[API] ───(Verifies Score)──────> [C# ScoringVerifier]
```

---

## 1. Candidate List

### Candidate 1: The Fat Submission Handler
- **Files**: `server/Features/Submissions/CreateSubmission.cs` (and `FinalizeSubmission.cs`)
- **Problem**: The handler is a 380+ line procedural script. It acts as a shallow module mixing HTTP parameter parsing, PBAC IDOR checks, `ScoringVerifier` orchestration, EF Core transaction management, and multiple side effects (ActionPlans, AuditLog, SectionExplosion, Analytics). It lacks strong seams for testing business rules without a full DB/HTTP context.
- **Solution**: Extract an `AuditSubmissionService` to act as a deep domain module. Move HTTP/Auth validation out, and push side-effects to an event-driven `IntegrationDispatcher` or MediatR notifications.
- **Benefits**: 
  - **Locality:** Side effects are decoupled from the core submission saving logic.
  - **Leverage:** You can unit test the submission orchestration without EF Core dependencies.
- **Trade-offs / Cost**: High execution cost and blast radius. Submissions are the core of the app; refactoring this requires extensive regression testing.

### Candidate 2: The Audit God Class
- **Files**: `lib/features/audit/manager/audit_manager.dart`
- **Problem**: This 400+ line manager orchestrates the entire offline auditing experience. It acts as a God Class, holding form state, parsing scoring logic, scheduling SQLite drafts, and tracking sync outbox IDs. The interface is wide, exposing raw internal maps and timers.
- **Solution**: Decompose into deep, focused managers. Extract `DraftPersistenceManager` to handle SQLite saving/restoring, and a `ScoringStateNotifier` for isolated live score recalculations. `AuditManager` becomes a simple coordinator.
- **Benefits**: 
  - **Locality:** Draft-saving bugs are isolated to one file.
  - **Leverage:** Testing scoring logic on the frontend no longer requires mocking the SQLite outbox.
- **Trade-offs / Cost**: Medium effort. Flutter `ChangeNotifier` refactors require careful checking of `Consumer` and `Selector` widgets to prevent broken reactive rebuilds.

### Candidate 3: Procedural Scoring Engine
- **Files**: `server/Common/Scoring/ScoringCalculators.cs`
- **Problem**: Contains 3 giant procedural methods (`VerifyPenalty`, `VerifyChecklist`, `VerifyAccumulation`). They duplicate core loops (fetching sub-criteria, resolving CCPs). The caller must branch to select the right mode, making it shallow.
- **Solution**: Deepen the scoring engine by introducing an `IScoringStrategy` seam. Implement concrete strategies (`PenaltyScoringStrategy`, etc.) behind a `ScoringEngineFactory`.
- **Benefits**: 
  - **Leverage:** Adding a new scoring mode just requires implementing one interface, without touching the core caller. 
  - **Locality:** Penalty logic is entirely separated from accumulation logic.
- **Trade-offs / Cost**: Low execution cost. The logic is already mostly pure, making it easy to wrap in an interface seam with minimal blast radius.

### Candidate 4: Deep Unified Outbox Draining Manager
- **Files**: `lib/_shared/services/sync_module.dart`, `lib/features/audit/services/core_audit_sync_module.dart`
- **Problem**: Offline outbox synchronization requires passing a complex set of 8 callbacks. The calling subclasses must manage database updates, network state checks, retry counts, error mapping, and error-type classification. This leaks control flow details into the subclasses, making them fragile and hard to test.
- **Solution**: Create a unified `OutboxQueue<T>` class that encapsulates connection monitoring, progressive backoff retry scheduling, and state persistence. Concrete modules only implement a simple `PushAdapter<T>` with a single `push(T item)` method and a type identifier.
- **Benefits**:
  - **Leverage:** Reduces subclass implementation lines and removes duplicate state handling.
  - **Locality:** Connectivity handling, retry scheduling, and error handling are localized in a single engine.
- **Trade-offs / Cost**: High refactoring cost and regression risk for existing sync flows.

---

## 2. Candidate Pugh Matrix

| Candidate | Description | Expected Locality | Expected Leverage | Blast Radius Safety | Execution Cost |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Status Quo** | Do nothing. | 0 | 0 | 0 | 0 |
| **1. Fat Submission Handler** | Domain Service & Events | +1 | +1 | -1 | -1 |
| **2. Audit God Class** | Focused State Notifiers | +1 | +1 | 0 | 0 |
| **3. Procedural Scoring Engine**| `IScoringStrategy` Pattern | +1 | +1 | +1 | +1 |
| **4. Unified Outbox Manager** | Deep `OutboxQueue<T>` | +1 | +1 | -1 | -1 |

*Note: Blast Radius Safety: +1 means safer (lower risk). Execution Cost: +1 means cheaper/faster to execute.*

---

## 3. Top Recommendation

I strongly recommend prioritizing **Candidate 3: Procedural Scoring Engine**. It provides immediate structural leverage with very low execution cost and low blast radius. Because the scoring calculation logic is mostly pure, extracting it into an `IScoringStrategy` pattern is incredibly safe and sets a strong architectural precedent for the backend's core business logic without risking data corruption or HTTP request failures. 
