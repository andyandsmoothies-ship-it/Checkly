# Architecture Decision Record (ADR)
## Deepen Arch: ActionPlanManager State Machine Decomposition

**Date**: 2026-05-09
**Status**: Accepted
**Target Modules**: `lib/features/action_plans/manager/action_plan_manager.dart`

### Context & Friction
Currently, the `ActionPlanManager` on the Flutter client is a 300+ line God Object `ChangeNotifier`. It entangles UI state management (list streams, loading flags), database I/O (optimistic SQLite writes, offline cache), and core domain logic (role-based access guards and state machine transitions). Because the business logic for state transitions is coupled directly to the `ChangeNotifier` and `Drift` database, it is impossible to unit test the role matrix without mocking the entire local database and API layer.

### Explored Options

#### Design 1: Minimalist (The Pure Reducer)
- Extract the transitions into a pure `ActionPlanStateMachine.transition(state, event, role)` function.
- **Pros**: Perfect testability with no dependencies.
- **Cons**: Requires caller boilerplate to construct event objects.

#### Design 2: Flexible (The Domain Service)
- Isolate the state machine and Drift I/O into an `ActionPlanDomainService`.
- **Pros**: Decouples UI from the database.
- **Cons**: Still mixes Domain Logic (role checks) with Infrastructure (Drift DB writes) inside the service, making testing difficult.

#### Design 3: Ergonomic (The Rich Domain Entity)
- Wrap the raw `ActionPlanDto` inside a smart `ActionPlan` entity. The entity contains mutation methods (`submitEvidence(role: role)`) that strictly enforce internal guards before returning a modified copy.
- **Pros**: Maximum ergonomics. Perfect separation of concerns. `ActionPlan` acts as a pure domain model, leaving `ActionPlanManager` to safely handle purely UI state and offline Drift writes.

### Pugh Matrix Evaluation

| Requirement | Baseline | D1: Minimalist | D2: Flexible | D3: Ergonomic |
|---|:---:|:---:|:---:|:---:|
| **Expected Locality** | 0 | +1 | 0 | +1 |
| **Expected Leverage** | 0 | 0 | +1 | +1 |
| **Blast Radius Safety** | 0 | +1 | -1 | +1 |
| **Execution Cost** | 0 | +1 | -1 | +1 |
| **Total** | 0 | +3 | -1 | **+4** |

### Locked-In Decision: Design 3 (Ergonomic Domain Entity)
We will proceed with **Design 3**. We will extract the domain logic out of `ActionPlanManager` by creating a rich `ActionPlan` wrapper entity. The role guards (e.g., `_assertRole`, `_assertStatus`) will be moved inside this pure Dart class. The UI manager will simply instantiate this entity, call the transition methods, and persist the safe, verified result to the Drift database. 

### Domain / Schema Gaps
- None. This is a pure structural refactoring of existing Flutter code. The backend API contracts and the Drift SQLite schema will remain untouched.
