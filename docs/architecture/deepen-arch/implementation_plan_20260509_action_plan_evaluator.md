# Implementation Plan: ActionPlanEvaluator Local Cache

## Target Module
`server/Common/Services/ActionPlanEvaluator.cs`

## Context
The `ActionPlanEvaluator` currently parses JSON rules from `Criterion.Metadata` for every answer in an audit. This causes unnecessary CPU/GC overhead on the hot path. Based on `adr_20260509_action_plan_evaluator.md`, we will implement **Design 1 (Minimalist Local Cache)** to resolve this bottleneck with zero blast radius.

## Action Plan

### `[MOD]` `server/Common/Services/ActionPlanEvaluator.cs`

1. **Cache Initialization:**
   - Inside `GetTriggeredAnswers`, initialize a local cache: 
     ```csharp
     var ruleCache = new Dictionary<string, TriggerRule?>();
     ```
2. **Method Signature Update:**
   - Update the private helper method `ShouldTrigger` to accept the cache:
     ```csharp
     private static bool ShouldTrigger(Answer answer, Criterion criterion, Dictionary<string, TriggerRule?> cache)
     ```
3. **Lazy Parsing:**
   - Inside `ShouldTrigger`, intercept the existing call to `ParseTrigger`.
   - Use `criterion.Metadata ?? string.Empty` as the dictionary key to safely handle nulls and deduplicate identical metadata payloads across different criteria.
   - If the key is not in `cache`, invoke `ParseTrigger(criterion.Metadata)` and store the result in `cache`.
   - Use the cached `TriggerRule` for the remainder of the evaluation.
4. **Validation:**
   - No changes to the public `GetTriggeredAnswers` method signature.
   - Callers remain entirely unaffected (Zero Blast Radius).
   - No database schema or upstream domain changes are required.
