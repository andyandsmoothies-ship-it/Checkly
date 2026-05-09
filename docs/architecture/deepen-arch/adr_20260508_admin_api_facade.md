# Architecture Decision Record (ADR)
## Deepen Arch: AdminApiService Decomposition

**Date**: 2026-05-08
**Status**: Accepted
**Target Modules**: `lib/features/admin/services/admin_api_service.dart`

### Context & Friction
The Flutter client's `AdminApiService` currently acts as a 300+ line God Object. It aggregates entirely unrelated backend domains (Users, Areas, PBAC Role Capabilities, Global Risks, and System Logs) into a single shallow module. This violates the Single Responsibility Principle, creates massive architectural friction, and causes unrelated UI managers to be tightly coupled to a bloated interface.

### Explored Options

#### Design 1: Minimalist (Strict Domain Segregation)
- Destroy the God Object and replace it with 5 standalone API classes (`UserAdminApi`, `AreaAdminApi`, etc.).
- **Pros**: Extreme Locality. Isolated blast radius.
- **Cons**: Poor Ergonomics. UI managers that need multiple domains must inject multiple dependencies.

#### Design 2: Flexible (CQRS / Command & Query Split)
- Split the class by Read (`AdminQueryService`) vs. Write (`AdminCommandService`) operations.
- **Pros**: Flexibility for scaling or queueing commands.
- **Cons**: Destroys domain cohesion. Related read/write methods for "Areas" are scattered.

#### Design 3: Ergonomic (The Domain Facade)
- Split the implementation into 5 strictly bounded domain classes, but wrap them in a single `AdminFacade` interface.
- **Pros**: Perfect balance. Perfect Locality for maintainers (small, domain-specific files) combined with maximum Ergonomics for callers (a single injected dependency with fluent `.users.`, `.areas.` access).

### Pugh Matrix Evaluation

| Requirement | Baseline | D1: Minimalist | D2: Flexible | D3: Ergonomic (Facade) |
|---|:---:|:---:|:---:|:---:|
| **Locality** | 0 | +1 | -1 | +1 |
| **Leverage** | 0 | -1 | -1 | +1 |
| **OCP** | 0 | +1 | 0 | +1 |
| **Blast Radius** | 0 | +1 | 0 | +1 |
| **Total** | 0 | +2 | -2 | **+4** |

### Locked-In Decision: Design 3 (Ergonomic Facade)
We will proceed with **Design 3**. We will extract the monolithic `AdminApiService` methods into pure, domain-specific API adapters:
1. `UserAdminApi`
2. `AreaAdminApi`
3. `RoleCapabilitiesApi`
4. `GlobalRisksApi`
5. `SystemLogApi`

These will be bundled inside a single `AdminFacade` class (or we will repurpose the existing `AdminApiService` as the facade shell) so that upstream UI Managers do not need their `locator` dependencies rewritten.

### Domain / Schema Gaps
- None. This is a pure structural decoupling of Dart networking code. The backend API contracts and the Flutter UI remain completely untouched.
