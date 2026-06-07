---
id: deepen_whole_project_20260607_123300
conversation_id: deafef40-90ce-4b4c-aaeb-7555faf2bb43
type: report
topic: whole_project
date: 2026-06-07
---

# Architectural Deepening Review: Checkly Platform

```
[UI] ────(Calculates Score)────> [Dart ScoringEngine]
                                         ▲
                                   (Must Match)
                                         ▼
[API] ───(Verifies Score)──────> [C# ScoringVerifier]
```

---

## 1. Candidate List

Below is the exhaustive candidate list of viable deepening opportunities found within the Checkly codebase.

### Candidate 1: Shared Scoring Parity Specification Test Suite
- **Affected Files**:
  - `server/Common/Scoring/ScoringVerifier.cs`
  - `server/Common/Scoring/ScoringCalculators.cs`
  - `lib/_shared/services/scoring_engine.dart`
  - `lib/_shared/services/penalty_calculator.dart`
  - `lib/_shared/services/accumulation_calculator.dart`
  - `lib/_shared/services/checklist_calculator.dart`
  - `lib/_shared/services/weighted_accumulation_calculator.dart`
- **Problem**: 
  Scoring calculations are implemented twice: in Dart/Flutter for immediate UI feedback, and in C# on the server to prevent tamper and verify data. Any update to scoring rules (e.g. progressive repeat math, CCP overrides, division by zero, scale input bounds) requires manual, duplicate updates. This creates a high risk of drift.
- **Solution**: 
  Establish a shared, language-agnostic JSON specification containing dozens of scoring scenarios (inputs, templates, and expected scores). Integrate a harness in both Dart (`flutter test`) and C# (`dotnet test`) that parses this JSON and asserts exact parity on both engines.
- **Benefits**:
  - **Leverage**: A single JSON specification drives test validation across both backend and frontend layers.
  - **Locality**: Any new scoring feature or edge-case fix only requires adding a case to the shared JSON file.
- **Trade-offs / Cost**: 
  Requires writing JSON parser wrappers in the respective test suites. Production code remains unchanged, minimizing blast radius.

### Candidate 2: Deep Unified Outbox Draining Manager
- **Affected Files**:
  - `lib/_shared/services/sync_module.dart`
  - `lib/features/audit/services/core_audit_sync_module.dart`
  - `lib/features/action_plans/services/action_plan_sync_module.dart`
- **Problem**: 
  Offline outbox synchronization uses `BaseSyncModule.processQueue`, which requires passing a complex set of 8 callbacks. The calling subclasses must manage database updates, network state checks, retry counts, error mapping, and error-type classification. This leaks control flow details into the subclasses, making them fragile and hard to test.
- **Solution**: 
  Create a unified `OutboxQueue<T>` class that encapsulates connection monitoring, progressive backoff retry scheduling, and state persistence. Concrete modules only implement a simple `PushAdapter<T>` with a single `push(T item)` method and a type identifier.
- **Benefits**:
  - **Leverage**: Reduces subclass implementation lines and removes duplicate state handling.
  - **Locality**: Connectivity handling, retry scheduling, and error handling are localized in a single engine.
- **Trade-offs / Cost**: 
  High refactoring cost and regression risk for existing sync flows.

### Candidate 3: Deep Address Formatting Module
- **Affected Files**:
  - `lib/_shared/database/tables.dart`
  - Various UI widgets displaying store addresses.
- **Problem**: 
  Address formatting (province, district, ward, street) is handled dynamically or ad-hoc in multiple widgets or domain wrappers. If local formatting rules change, multiple views have to be modified.
- **Solution**: 
  Create a unified `Address` value object and a deep formatting module that takes raw database fields and returns localized, styled text representations.
- **Benefits**:
  - **Leverage**: Small interface `AddressFormatter.format(store)` hiding formatting rules.
  - **Locality**: All formatting logic is in one place.
- **Trade-offs / Cost**: 
  Very low impact since store address is mostly read-only display.

---

## 2. Candidate Pugh Matrix

| Metric | Status Quo | Candidate 1: Shared Scoring Spec | Candidate 2: Unified Outbox Manager | Candidate 3: Address Formatter |
|---|:---:|:---:|:---:|:---:|
| **Expected Locality** | 0 | +1 | +1 | +1 |
| **Expected Leverage** | 0 | +1 | +1 | 0 |
| **Blast Radius Safety** | 0 | +1 | -1 | +1 |
| **Execution Cost (Effort)** | 0 | 0 | -1 | 0 |
| **Total Score** | **0** | **+3** | **0** | **+2** |
