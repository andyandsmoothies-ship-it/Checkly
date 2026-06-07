# Test Spec: Deepen Scoring and Audit (Slice 1)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\deepen_scoring_and_audit\implementation_plan_deepen_scoring_and_audit_20260607_135500.md`

## Tests Written

A new unit test file has been created at `server/tests/Checkly.Api.Tests/ScoringEngineAbstractionTests.cs`. It tests the core abstractions introduced in Slice 1 of the implementation plan:

1. **`ScoringContext_Initialization_PropertiesAreAssigned`**
   - **Goal:** Verifies that a `ScoringContext` object holds all essential fields correctly (e.g. `ClientScore`, `Answers`, `Criteria`, `Groups`, `ProgressiveRepeatPenalty`, `IsWeighted`, `Tolerance`).
   
2. **`ScoringEngineFactory_GetStrategy_ResolvesCorrectStrategy`**
   - **Goal:** Verifies that the `ScoringEngineFactory` resolves the correct `IScoringStrategy` type depending on the `scoreDirection` configuration and weight flags.
   - **Covered Scenarios:**
     - "up" -> `AccumulationScoringStrategy`
     - "down" (weighted) -> `PenaltyScoringStrategy`
     - "down" (unweighted) -> `ChecklistScoringStrategy`
     - Fallbacks for unmapped/null/empty directions -> `ChecklistScoringStrategy`

3. **`ChecklistScoringStrategy_Verify_CalculatesCorrectScore`**
   - **Goal:** Verifies the standalone checklist strategy correctly recalculates scores based on flat deductions.

4. **`PenaltyScoringStrategy_Verify_CalculatesCorrectScore`**
   - **Goal:** Verifies the group-weighted penalty strategy correctly recalculates scores.

5. **`AccumulationScoringStrategy_Verify_CalculatesCorrectScore`**
   - **Goal:** Verifies the accumulation strategy correctly recalculates scores.

## Test Command

The Builder can run only these abstraction tests with the following command:

```bash
dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~ScoringEngineAbstraction"
```

## Decision Log

- **Decision:** Write unit tests (`ScoringEngineAbstractionTests.cs`) covering all strategies (`Checklist`, `Penalty`, `Accumulation`) and the resolver factory before writing any implementation code.
- **Rationale:** Ensures complete architectural isolation and prevents drift in C# scoring engine logic.

## Verification Handoff

The Builder must:
1. Implement the classes `ScoringContext`, `IScoringStrategy`, `ChecklistScoringStrategy`, `PenaltyScoringStrategy`, `AccumulationScoringStrategy`, and `ScoringEngineFactory` in the backend project (`server/src/`).
2. Run the test command below to verify that all abstraction tests pass successfully.

<test_trace>
```text
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringEngineAbstractionTests.cs(55,36): error CS0246: The type or namespace name 'AccumulationScoringStrategy' could not be found (are you missing a using directive or an assembly reference?) [C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj]
```
</test_trace>

<forensic_evidence>
```bash
cmd /c "dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~ScoringEngineAbstraction""
```
Returned: Build FAILED with CS0246 compilation errors.
</forensic_evidence>

