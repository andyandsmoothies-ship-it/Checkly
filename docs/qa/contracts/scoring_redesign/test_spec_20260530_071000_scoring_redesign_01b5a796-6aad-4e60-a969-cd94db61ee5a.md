# Test Specification: Slice 2 Backend Parser & Dispatch

## 1. System Structure

```
[Template JSON] 
       │
       ▼ (ScoringConfigParser) parses into:
(ScoreDirection, IsWeighted, ProgressiveRepeatConfig)
       │
       ▼ (ScoringVerifierDispatch) routes to:
  ┌────┴─────────────────────────────┐
  ▼ (isWeighted=true)                ▼ (isWeighted=false)
[WeightedScoringVerifier]          [UnweightedScoringVerifier]
  │                                  │
  ▼                                  ▼
[Subtract DTO.PointsWeight]       [No weight multipliers]
```

## 2. Test Matrix Mapping

This matrix maps each requirement to its concrete unit test in the test suite:

| Case ID | Feature Component | Target Scenario | Test File | Test Method |
|---|---|---|---|---|
| **TC-01** | `ScoringConfigParser` | Parse empty/null logic config | `ScoringConfigParserTests.cs` | `Parse_EmptyOrNullConfig_ReturnsDefaultTuple` |
| **TC-02** | `ScoringConfigParser` | Parse legacy `"scoringMode":"penalty"` | `ScoringConfigParserTests.cs` | `Parse_Maps_Legacy_ScoringMode_Correctly` |
| **TC-03** | `ScoringConfigParser` | Parse new `"isWeighted"` & `"scoreDirection"` | `ScoringConfigParserTests.cs` | `Parse_NewConfig_MapsValuesCorrectly` |
| **TC-04** | `ScoringConfigParser` | Parse progressive repeat config | `ScoringConfigParserTests.cs` | `Parse_ProgressiveRepeat_MapsValuesCorrectly` |
| **TC-05** | `ScoringVerifierDispatch` | Route `isWeighted=true` | `ScoringVerifierDispatchTests.cs` | `Verify_WeightedConfig_UsesWeightedVerifier` |
| **TC-06** | `ScoringVerifierDispatch` | Route `isWeighted=false` | `ScoringVerifierDispatchTests.cs` | `Verify_UnweightedConfig_UsesUnweightedVerifier` |
| **TC-07** | `ScoringVerifierDispatch` | Handle progressive repeat execution | `ScoringVerifierDispatchTests.cs` | `Verify_ProgressiveConfig_ExecutesProgressiveLogic` |
| **TC-08** | `Template` & `Submission` | Entities backward compatibility properties | `ScoringDesignSlice2Tests.cs` | `Template_Maintains_Compatibility_Properties` & `Submission_Maintains_Compatibility_Properties` |
| **TC-09** | `TemplateLinter` | Lint error for `isWeighted=true` + sum != 100 | `TemplateLinter_Slice1_Tests.cs` | `SaveTemplateTree_WithNewWeightedJsonSummingTo95_Returns422` |
| **TC-09b**| `TemplateLinter` | Success for `isWeighted=false` + sum != 100 | `TemplateLinter_Slice1_Tests.cs` | `SaveTemplateTree_WithNewUnweightedJsonSummingTo95_SavesSuccessfully` |

## 3. Hostile Interrogation & Verification Triggers

1. **Tuples and JSON Deserialization Faults**: If invalid/corrupted JSON is passed, the parser should fail-safe to `(ScoreDirection.Down, true, null)` rather than throwing a `JsonException`.
2. **Deconstruction Mismatches**: C# compiler will raise CS8132 if callers attempt to deconstruct the returned tuple into the old 2-variable structure rather than the new 3-variable structure.
3. **Dispatch Factory Mocking**: The tests use standard mocking of the underlying scoring verifiers to ensure dispatch routing is decoupled from specific database integration state.
