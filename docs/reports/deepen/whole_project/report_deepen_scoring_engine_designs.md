---
type: report
topic: scoring_engine_designs
date: 2026-06-07
---

# Architectural Deepening: Procedural Scoring Engine Designs

## Candidate Overview
**Target:** `server/Common/Scoring/ScoringCalculators.cs`
**Goal:** Deepen the procedural scoring engine into a polymorphic `IScoringStrategy` seam.

## Design 1: Minimalist (Direct Signature Unification)

### Interface
```csharp
public interface IScoringStrategy
{
    ScoringVerifier.VerificationResult Verify(
        decimal clientScore,
        IReadOnlyList<Answer> answers,
        IReadOnlyList<Group> groups,
        IReadOnlyList<Criterion> criteria,
        bool progressiveRepeatPenaltyOrIsWeighted,
        decimal tolerance);
}
```
**Details**: Unifies the existing 3 methods by taking all possible parameters. The `bool` parameter acts as `progressiveRepeatPenalty` for Penalty/Checklist modes and `isWeighted` for Accumulation mode.
**Pros**: Very fast to implement.
**Cons**: Overloaded boolean parameter is a code smell. `groups` is unused in Checklist scoring.

## Design 2: Flexible (Context Object)

### Interface
```csharp
public record ScoringContext(
    decimal ClientScore,
    IReadOnlyList<Answer> Answers,
    IReadOnlyList<Criterion> Criteria,
    IReadOnlyList<Group> Groups,
    bool ProgressiveRepeatPenalty,
    bool IsWeighted,
    decimal Tolerance
);

public interface IScoringStrategy
{
    ScoringVerifier.VerificationResult Verify(ScoringContext context);
}
```
**Details**: Wraps all inputs into a single `ScoringContext` record.
**Pros**: Excellent Open-Closed Principle compliance. Future parameters can be added to the Context without breaking the `IScoringStrategy` contract.
**Cons**: Requires building a Context object before dispatch.

## Design 3: Ergonomic (Generic Config Parameters)

### Interface
```csharp
public interface IScoringStrategy<TConfig>
{
    ScoringVerifier.VerificationResult Verify(
        decimal clientScore,
        IReadOnlyList<Answer> answers,
        IReadOnlyList<Criterion> criteria,
        IReadOnlyList<Group> groups,
        TConfig config,
        decimal tolerance);
}
```
**Details**: Strategies accept a strongly-typed config object (`PenaltyConfig`, `AccumulationConfig`).
**Pros**: Highest type safety. Strategies only receive the exact configuration flags they need.
**Cons**: Complexity explodes at the caller/factory boundary. The `ScoringVerifier` must know how to construct specific config types based on the template mode, which leaks mode-specific logic back into the orchestrator.

## Pugh Matrix

| Design | Locality | Leverage | Open-Closed | Blast Radius | Total |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline** (Procedural) | 0 | 0 | 0 | 0 | 0 |
| **1. Minimalist** | +1 | 0 | -1 | +1 | +1 |
| **2. Flexible (Context)** | +1 | +1 | +1 | +1 | +4 |
| **3. Ergonomic (Typed)** | 0 | +1 | 0 | 0 | +1 |

*Note: Baseline is the current `ScoringCalculators` class.*

## Conclusion

**Winner: Design 2 (Flexible Context Object)**

**Why**: Design 2 offers the best balance of Leverage and Open-Closed Principle compliance. By wrapping parameters in a `ScoringContext`, the interface becomes extremely deep and stable. Adding a new scoring mode in the future will not require changing the `IScoringStrategy` interface or any existing implementations. Design 1 suffers from primitive obsession (overloaded boolean), and Design 3 leaks strategy-specific setup knowledge back into the factory/caller, reducing locality.
