# Walkthrough — Action Plan Source Label TDD (AP01)
Workflow: /tdd | Track: B1 | Role: Sentinel (QA)

## Input Lineage
- **Source Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260515_211200_AP01_source.md`
- **Test File**: `C:\Users\HP\Documents\GitHub\Checkly\server\Tests\Checkly.Api.Tests\ActionPlan_SourceTitle_Tests.cs`
- **Gate Log**: `C:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\executed_tests_20260515_234442_AP01_source.md`

## What Was Done

Sentinel (QA) wrote 3 failing integration tests for Phase A of the AP01 Action Plan Source Label feature.

```
[API] --> [CreateActionPlan.HandleAsync]
              |
              +--> submission.ProgramAssignmentId != null?
                   YES: SourceTitle = "Campaign: {Program.Title}"
                   NO:  SourceTitle = "Audit: {Submission.TemplateTitle}"
              |
         [ActionPlanDto.SourceTitle] --> [JSON response field "sourceTitle"]
```

## Tests Written

| Test ID | Method Name | State | Failure Reason |
|---------|------------|-------|----------------|
| TC_AP_SRC_01 | `CreateActionPlan_WithCampaign_SetsCampaignSource` | Happy Path (Campaign) | `ActionPlanDto` has no `SourceTitle` → `KeyNotFoundException` at line 201 |
| TC_AP_SRC_02 | `CreateActionPlan_WithAudit_SetsAuditSource` | Happy Path (Audit) | `ActionPlanDto` has no `SourceTitle` → `KeyNotFoundException` at line 233 |
| TC_AP_SRC_03 | `GetActionPlan_WithNullSourceTitle_ReturnsNullField` | Null/Legacy state | GET response missing `sourceTitle` key → custom assert at line 295 |

## RED Gate Result

- **3 / 3 tests FAILED** ✅ (correct RED — all for feature-missing reasons)
- **0 bad-setup failures** — all 3 passed the Arrange phase, API returned HTTP 201/200

## What Forge (Builder) Must Do — Phase A

### 1. Add property to entity
**File**: `server/Common/Persistence/Entities/ActionPlan.cs`
```csharp
// Add under // Snapshot fields
public string? SourceTitle { get; set; }
```

### 2. Generate EF Migration
```cmd
cmd /c "rtk dotnet ef migrations add AddActionPlanSourceTitle -s Checkly.Api -p Checkly.Api.Common --output-dir Migrations"
```
(Run from `server/` directory)

### 3. Update CreateActionPlan handler
**File**: `server/Features/ActionPlans/CreateActionPlan.cs`

Logic to add before `var plan = new ActionPlan {`:
```csharp
string? sourceTitle = null;
if (submission.ProgramAssignmentId.HasValue)
{
    var programAssignment = await db.ProgramAssignments
        .AsNoTracking()
        .Include(pa => pa.Program)
        .FirstOrDefaultAsync(pa => pa.Id == submission.ProgramAssignmentId.Value, ct);
    if (programAssignment?.Program is not null)
        sourceTitle = $"Campaign: {programAssignment.Program.Title}";
}
else if (submission.TemplateTitle is not null)
{
    sourceTitle = $"Audit: {submission.TemplateTitle}";
}
```

Then add to the plan constructor: `SourceTitle = sourceTitle,`

### 4. Update ActionPlanDto
**File**: `server/Features/ActionPlans/Dtos.cs`
```csharp
// Add to ActionPlanDto record:
string? SourceTitle,
```
And update `ToDto()` in `CreateActionPlan.cs`, `GetActionPlan.cs`, and `ListActionPlans.cs` to pass `p.SourceTitle`.

## Verification Command for Forge

Run ONLY the new AP01 tests (fast check):
```cmd
cmd /c "rtk dotnet test server\Tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter FullyQualifiedName~ActionPlan_SourceTitle_Tests"
```

Expected after implementation: **3 Passed, 0 Failed**.
