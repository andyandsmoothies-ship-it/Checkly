---
ConversationID: 1f32f1ff-d902-44a0-9676-c11521358960
Type: walkthrough
Topic: Deepen Scoring and Audit (Slice 1 - Backend Scoring Engine)
Created: 2026-06-07 14:51:00
---

# Walkthrough: Deepen Scoring and Audit (Slice 1 - Backend Scoring Engine)

This walkthrough details the structural changes implemented to decouple and abstract the backend scoring engine in Checkly, replacing the monolithic scoring calculation in `ScoringVerifier.cs` with polymorphic strategy classes.

## Implemented Architecture

A Strategy pattern has been introduced to divide scoring calculations by template scoring type:

- `IScoringStrategy`: Defines the core contract for evaluating section/subsection and total scores for a submission.
- `ScoringStrategyFactory`: Dispatches and retrieves the correct strategy based on `TemplateScoringType` (e.g., standard, weighted, pass-fail, or fault-based).
- `StandardScoringStrategy`: Computes scores using the standard weighted sum of sections.
- `WeightedScoringStrategy`: Direct port of standard scoring.
- `PassFailScoringStrategy`: Logic for pass/fail metrics.
- `FaultBasedScoringStrategy`: Logic for fault deductions.
- `ScoringContext`: Executes the assigned strategy on submissions.

## File Changes

### 1. Strategy Interfaces & Types
- **[IScoringStrategy.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Scoring/IScoringStrategy.cs)**: Interface defining `CalculateScores`.
- **[ScoringStrategyFactory.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Scoring/ScoringStrategyFactory.cs)**: Dictionary-based registry matching `TemplateScoringType` to its respective implementation.
- **[ScoringContext.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Scoring/ScoringContext.cs)**: Context runner for strategy execution.

### 2. Strategy Implementations
- **[StandardScoringStrategy.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Scoring/Strategies/StandardScoringStrategy.cs)**
- **[WeightedScoringStrategy.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Scoring/Strategies/WeightedScoringStrategy.cs)**
- **[PassFailScoringStrategy.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Scoring/Strategies/PassFailScoringStrategy.cs)**
- **[FaultBasedScoringStrategy.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Scoring/Strategies/FaultBasedScoringStrategy.cs)**

### 3. Integration
- **[ScoringVerifier.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Scoring/ScoringVerifier.cs)**: Refactored to delegate core scoring calculation to the polymorphic engine via `ScoringContext`.
