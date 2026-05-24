# Executed Tests — Action Plan Source Label (AP01)
Workflow: /tdd | Phase 3 — RED Gate Log | Track: B1

## Input Lineage
- **Source Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260515_211200_AP01_source.md`
- **Test File**: `C:\Users\HP\Documents\GitHub\Checkly\server\Tests\Checkly.Api.Tests\ActionPlan_SourceTitle_Tests.cs`

## Verdict: ✅ CORRECTLY RED — All 3 tests fail because the feature is missing.

```
Total tests: 3
     Failed: 3 (Good Failures)
 Total time: 9.6349 Seconds
```

## Failure Analysis

| Test | Failure Type | Root Cause | Good/Bad |
|------|-------------|------------|----------|
| `CreateActionPlan_WithCampaign_SetsCampaignSource` | `KeyNotFoundException` on `body.GetProperty("sourceTitle")` | `ActionPlanDto` has no `SourceTitle` field. API returned 201 OK but JSON has no `sourceTitle` key. | ✅ Good Failure |
| `CreateActionPlan_WithAudit_SetsAuditSource` | `KeyNotFoundException` on `body.GetProperty("sourceTitle")` | Same — `ActionPlanDto` missing `SourceTitle`. | ✅ Good Failure |
| `GetActionPlan_WithNullSourceTitle_ReturnsNullField` | Custom assert: `"ActionPlanDto must include a 'sourceTitle' property even for legacy records."` | `TryGetProperty("sourceTitle")` returned false — property absent from GET response DTO. | ✅ Good Failure |

## Raw Terminal Output

```
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Determining projects to restore...
  All projects are up-to-date for restore.
  Checkly.Api -> C:\Users\HP\Documents\GitHub\Checkly\server\bin\Debug\net10.0\Checkly.Api.dll
  Checkly.Api.Tests -> C:\Users\HP\Documents\GitHub\Checkly\server\Tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll
Test run for Checkly.Api.Tests.dll (.NETCoreApp,Version=v10.0)

Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

[xUnit.net 00:00:08.63]   [FAIL] CreateActionPlan_WithCampaign_SetsCampaignSource
  Error: System.Collections.Generic.KeyNotFoundException: The given key was not present in the dictionary.
  at System.Text.Json.JsonElement.GetProperty(String propertyName)
  at ActionPlan_SourceTitle_Tests.cs:line 201

[xUnit.net 00:00:08.76]   [FAIL] GetActionPlan_WithNullSourceTitle_ReturnsNullField
  Error: ActionPlanDto must include a 'sourceTitle' property even for legacy records.
  at ActionPlan_SourceTitle_Tests.cs:line 295

[xUnit.net 00:00:08.90]   [FAIL] CreateActionPlan_WithAudit_SetsAuditSource
  Error: System.Collections.Generic.KeyNotFoundException: The given key was not present in the dictionary.
  at System.Text.Json.JsonElement.GetProperty(String propertyName)
  at ActionPlan_SourceTitle_Tests.cs:line 233

Total tests: 3 | Failed: 3 | Passed: 0
fail dotnet test: 0 passed, 3 failed, 0 skipped, 0 warnings in 1 projects (9.6 s)
```

## Infrastructure Note

> [!NOTE]
> `verify_aaa_pattern.py` crashed with `UnicodeEncodeError` (Windows cp1252 cannot encode ✅ emoji).
> **Manual AAA verification performed instead — all 3 test methods confirmed to have exactly one `// Act` block.**

## What Forge Must Implement (Phase A Checklist)

```
[Backend - Phase A]
  Server: ActionPlan entity
    server/Common/Persistence/Entities/ActionPlan.cs
    -> Add: public string? SourceTitle { get; set; }

  Server: EF Migration
    -> dotnet ef migrations add AddActionPlanSourceTitle -s ../Checkly.Api/ -p ../Checkly.Api.Common/

  Server: CreateActionPlan handler
    server/Features/ActionPlans/CreateActionPlan.cs
    -> Fetch Program.Title via Submission.ProgramAssignmentId
    -> If ProgramAssignmentId != null: SourceTitle = "Campaign: {program.Title}"
    -> Else:                           SourceTitle = "Audit: {submission.TemplateTitle}"
    -> Set plan.SourceTitle = sourceTitle

  Server: ActionPlanDto record
    server/Features/ActionPlans/Dtos.cs
    -> Add: string? SourceTitle to ActionPlanDto record
    -> Update CreateActionPlan.ToDto() to include SourceTitle
    -> Update GetActionPlan.ToDto() to include SourceTitle
    -> Update ListActionPlans.ToDto() to include SourceTitle
```
