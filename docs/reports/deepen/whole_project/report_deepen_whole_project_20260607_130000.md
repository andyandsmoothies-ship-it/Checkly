# Architecture Review: Deepening the Whole Project

## Exploration Findings

After exploring the codebase (`lib/features/audit`, `server/Features/Submissions`, `server/Common/Scoring`), I found several architectural friction points where modules are shallow or excessively coupled.

### Candidate 1: The Fat Submission Handler
- **Files**: `server/Features/Submissions/CreateSubmission.cs` (and `FinalizeSubmission.cs`)
- **Problem**: The handler is a 380+ line procedural script. It acts as a shallow module mixing HTTP parameter parsing, PBAC IDOR checks, `ScoringVerifier` orchestration, EF Core transaction management, and 4 different side effects (ActionPlans, AuditLog, SectionExplosion, Analytics). It lacks strong seams for testing business rules without a full DB/HTTP context.
- **Solution**: Extract an `AuditSubmissionService` to act as a deep domain module. Move HTTP/Auth validation out, and push side-effects to an event-driven `IntegrationDispatcher` or MediatR notifications.
- **Benefits**: **Locality** increases because side effects (like Analytics) are decoupled from the core submission saving logic. **Leverage** increases as you can unit test the submission orchestration without EF Core dependencies.
- **Trade-offs / Cost**: High cost and blast radius. Submissions are the core of the app; refactoring this requires extensive regression testing.

### Candidate 2: The Audit God Class
- **Files**: `lib/features/audit/manager/audit_manager.dart`
- **Problem**: This 400+ line manager orchestrates the entire offline auditing experience. It acts as a God Class, holding form state, parsing scoring logic, scheduling SQLite drafts, and tracking sync outbox IDs. The interface is wide, exposing raw internal maps and timers.
- **Solution**: Decompose into deep, focused managers. Extract `DraftPersistenceManager` to handle SQLite saving/restoring, and a `ScoringStateNotifier` for isolated live score recalculations. `AuditManager` becomes a simple coordinator.
- **Benefits**: **Locality** increases as draft-saving bugs are isolated to one file. **Leverage** increases because testing scoring logic on the frontend no longer requires mocking the SQLite outbox.
- **Trade-offs / Cost**: Medium effort. Flutter `ChangeNotifier` refactors require careful checking of `Consumer` and `Selector` widgets to prevent broken reactive rebuilds.

### Candidate 3: Procedural Scoring Engine
- **Files**: `server/Common/Scoring/ScoringCalculators.cs`
- **Problem**: Contains 3 giant procedural methods (`VerifyPenalty`, `VerifyChecklist`, `VerifyAccumulation`). They duplicate core loops (fetching sub-criteria, resolving CCPs). The caller must branch to select the right mode, making it shallow.
- **Solution**: Deepen the scoring engine by introducing an `IScoringStrategy` seam. Implement concrete strategies (`PenaltyScoringStrategy`, etc.) behind a `ScoringEngineFactory`.
- **Benefits**: High **Leverage**—adding a new scoring mode (e.g., V6 mode) just requires implementing one interface, without touching the core caller. High **Locality**—penalty logic is entirely separated from accumulation logic.
- **Trade-offs / Cost**: Low cost. The logic is already mostly pure, making it easy to wrap in an interface seam with minimal blast radius.

---

## Candidate Pugh Matrix

| Candidate | Description | Expected Locality | Expected Leverage | Blast Radius Safety | Execution Cost |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Status Quo** | Do nothing. | 0 | 0 | 0 | 0 |
| **1. Fat Submission Handler** | `CreateSubmission.cs` -> Domain Service & Events | +1 | +1 | -1 | -1 |
| **2. Audit God Class** | `audit_manager.dart` -> Focused State Notifiers | +1 | +1 | 0 | 0 |
| **3. Procedural Scoring Engine** | `ScoringCalculators.cs` -> `IScoringStrategy` Pattern | +1 | +1 | +1 | +1 |

*Note: Blast Radius Safety: +1 means safer (lower risk). Execution Cost: +1 means cheaper/faster to execute.*
