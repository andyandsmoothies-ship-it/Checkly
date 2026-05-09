# Architecture Decision Record (ADR)
## Deepen Arch: ActionPlanEvaluator JSON Parsing

**Date**: 2026-05-09
**Status**: Accepted
**Target Modules**: `server/Common/Services/ActionPlanEvaluator.cs`

### Context & Friction
The `ActionPlanEvaluator` determines if a submitted answer should trigger an Action Plan by parsing JSON rules stored in `Criterion.Metadata`. Currently, `JsonDocument.Parse(metadata)` is called inside the primary evaluation loop for *every single answer*. If an audit contains 200 answers mapped to 10 unique criteria, the system allocates memory and parses the exact same JSON 200 times. This creates unnecessary CPU/GC overhead on a hot path and couples raw string parsing directly with business logic.

### Explored Options

#### Design 1: Minimalist (The Local Cache)
- The method signature remains completely unchanged.
- Internally, a `Dictionary<string, TriggerRule>` is used to pre-parse and cache the criteria metadata exactly once before the answer loop begins.
- **Pros**: Zero blast radius. Callers require absolutely no changes.
- **Cons**: Raw string manipulation still lives in the same file as domain logic.

#### Design 2: Flexible (Strategy Pattern + Typed Handlers)
- Rips parsing out entirely. Callers pass in `Dictionary<string, IActionPlanRule>`.
- **Pros**: Extensible.
- **Cons**: Damages ergonomics. All callers must inject a Factory to parse rules before calling the evaluator.

#### Design 3: Ergonomic (The Mapped Domain Model)
- Callers project the raw DB `Criterion` into a strongly-typed `EvaluatableCriterion` domain model, which handles the parsing once at the boundary.
- **Pros**: Perfect separation of infrastructure parsing and pure domain logic.
- **Cons**: Requires callers to write boilerplate mapping code.

### Pugh Matrix Evaluation

| Requirement | Baseline | D1: Minimalist | D2: Flexible | D3: Ergonomic |
|---|:---:|:---:|:---:|:---:|
| **Expected Locality** | 0 | 0 | +1 | +1 |
| **Expected Leverage** | 0 | +1 | -1 | +1 |
| **Blast Radius Safety** | 0 | +1 | -1 | +1 |
| **Execution Cost** | 0 | +1 | -1 | 0 |
| **Total** | 0 | **+3** | -2 | +3 |

### Locked-In Decision: Design 1 (Minimalist Local Cache)
We will proceed with **Design 1**. While Design 3 offers a slightly purer domain separation, Design 1 tied for the highest score while maintaining a **zero blast radius** for callers. 

By building a local `Dictionary<string, TriggerRule?>` cache inside `GetTriggeredAnswers`, we eliminate the performance bottleneck (parsing is reduced from $O(N_{answers})$ to $O(N_{criteria})$) without breaking any upstream contracts.

### Domain / Schema Gaps
- None. No database schema changes are required. This is a pure internal performance optimization of an existing static service.
