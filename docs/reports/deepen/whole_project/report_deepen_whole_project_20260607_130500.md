---
ConversationID: 24dc20ff-b1f4-4b75-a3d8-5d13f35020f5
Type: report
Topic: whole_project
Date: 2026-06-07
---

# Checkly Architectural Deepening Review

This report analyzes three candidates to turn shallow interfaces into deep modules.

## Calculation Alignment (Status Quo)

```
[Flutter UI] ---> [ScoringEngine (Dart)] ---> Client Score
                                                   |
                                                   v (JSON payload)
[C# .NET API] <------------------------------------+
       |
       v
[ScoringVerifier (C#)] ---> compares with ---> [ScoringCalculators (C#)] (Server Score)
```

- The client computes scores locally using a Dart engine.
- The server recalculates scores using a C# engine.
- The C# API compares both scores to prevent tampered payloads.
- **Problem**: The two engines are independent. A change to scoring logic requires updating both Dart and C# code. This creates a risk of drift.

---

## Proposed Deepening Candidates

### Candidate 1: Scoring Parity Spec
- **Description**: Introduce a shared, language-agnostic JSON-based test spec to ensure the C# backend and Dart frontend scoring engines never drift.
- **Effort**: Low
- **Leverage**: High
- **Locality**: High. Any change to the scoring formulas is verified by running tests on both sides against the same test suite.

### Candidate 2: Deep Outbox Manager
- **Description**: Encapsulate network status, backoff timers, retries, and persistence in a single queue manager, exposing a simple adapter interface.
- **Effort**: High
- **Leverage**: High
- **Locality**: High. Outbox queue mechanics are separated from the rest of the frontend code.

### Candidate 3: Address Formatter
- **Description**: Unify address displaying rules into a simple, reusable Address value object and formatting class on the client.
- **Effort**: Low
- **Leverage**: Low
- **Locality**: Low. This covers formatting, which has low impact on business rules.

---

## Candidate Pugh Decision Matrix

| Metric | Status Quo | Candidate 1: Scoring Parity Spec | Candidate 2: Unified Outbox | Candidate 3: Address Formatter |
| :--- | :---: | :---: | :---: | :---: |
| Expected Locality | 0 | +1 | +1 | +1 |
| Expected Leverage | 0 | +1 | +1 | 0 |
| Blast Radius Safety | 0 | +1 | -1 | +1 |
| Execution Cost (Effort) | 0 | 0 | -1 | 0 |
| **Total Score** | **0** | **+3** | **0** | **+2** |

*Note: Blast Radius Safety: +1 means safer (lower risk). Execution Cost: +1 means cheaper/faster to execute.*
