# Red Test Log: Deepen Scoring and Audit (Slice 1)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\deepen_scoring_and_audit\implementation_plan_deepen_scoring_and_audit_20260607_135500.md`

## Compilation / Test Output

The project failed to build with the following compilation errors because the new scoring strategies and factory are not yet implemented:

<test_trace>
```text
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringEngineAbstractionTests.cs(55,36): error CS0246: The type or namespace name 'AccumulationScoringStrategy' could not be found (are you missing a using directive or an assembly reference?) [C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj]
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringEngineAbstractionTests.cs(56,37): error CS0246: The type or namespace name 'AccumulationScoringStrategy' could not be found (are you missing a using directive or an assembly reference?) [C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj]
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringEngineAbstractionTests.cs(57,38): error CS0246: The type or namespace name 'PenaltyScoringStrategy' could not be found (are you missing a using directive or an assembly reference?) [C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj]
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringEngineAbstractionTests.cs(58,39): error CS0246: The type or namespace name 'ChecklistScoringStrategy' could not be found (are you missing a using directive or an assembly reference?) [C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj]
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringEngineAbstractionTests.cs(59,39): error CS0246: The type or namespace name 'ChecklistScoringStrategy' could not be found (are you missing a using directive or an assembly reference?) [C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj]
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringEngineAbstractionTests.cs(60,35): error CS0246: The type or namespace name 'ChecklistScoringStrategy' could not be found (are you missing a using directive or an assembly reference?) [C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj]
C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringEngineAbstractionTests.cs(61,37): error CS0246: The type or namespace name 'ChecklistScoringStrategy' could not be found (are you missing a using directive or an assembly reference?) [C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj]

Build FAILED.
    0 Warning(s)
    7 Error(s)
```
</test_trace>

## Forensic Evidence

<forensic_evidence>
```bash
cmd /c "dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~ScoringEngineAbstraction""
```

Output:
```text
Build FAILED.
    0 Warning(s)
    7 Error(s)
```
</forensic_evidence>

