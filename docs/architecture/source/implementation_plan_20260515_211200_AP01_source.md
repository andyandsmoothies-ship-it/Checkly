# Action Plan Source Label
Workflow: /analyze-feature | Track: B1

<latent_space_scratchpad>
- Edge Case: Old action plans created before this column was added will have a null `SourceTitle`. The UI needs to handle null gracefully (e.g., hiding the row or showing "Audit: Unknown").
- Performance: Adding a column requires a fast EF Migration, but we can also just compute it if we don't want a migration. Wait, the rule is "Do not change database unless necessary". But denormalizing `SourceTitle` is exactly what the entity currently does for `StoreName` and `StoreManagerName` because historic references should not break if the parent submission is deleted. So a DB column migration is the correct Checkly architectural pattern.
</latent_space_scratchpad>

## Input Lineage
- User request regarding Action Plan UI details.

## Executive Summary & Out of Scope
**Goal:** Expose the "Source" (e.g., "Campaign - Summer Safety" or "Audit - Daily Cleanliness") on the Action Plan UI so managers know exactly where the failure originated.
**Out of Scope:** We are not changing how action plans are resolved, nor are we changing the underlying submission data structure.

## System Context
- **Offline/Online:** The `ActionPlanDto` is used online. Flutter UI consumes it.
- **RBAC:** No changes to existing action plan RBAC (Store Manager / Area Manager).

## Lifecycle Context
- **Success State:** Action Plan Card/Detail shows an extra row with an icon and the `SourceTitle`.
- **Empty State (Legacy Data):** If an old action plan has a `null` SourceTitle, the row will gracefully not render.

## Risk Assessment
- **Risk Level:** Low.
- **ROI:** High (significant UX context improvement for a minor backend/frontend modification).
- **Blast Radius:** Safe. Adding a nullable column does not break existing data or offline queries.

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC_AP_SRC_01 | CreateActionPlan_WithCampaign_SetsCampaignSource | Status: Draft submission with ProgramAssignmentId -> creates plan | Backend entity currently lacks SourceTitle logic. |
| TC_AP_SRC_02 | CreateActionPlan_WithAudit_SetsAuditSource | Status: Draft submission without ProgramAssignment -> creates plan | Backend entity currently lacks SourceTitle logic. |
| TC_AP_SRC_03 | ActionPlanCard_DisplaysSource_WhenPresent | Success UI | Flutter widget doesn't have the SourceTitle property mapped yet. |

## Test Fixture & Payloads
- **Setup:** A `Submission` seeded with a linked `ProgramAssignment` (for Campaign) and a standalone `Submission` (for normal Audit).

## Verification Plan
1. **Automated Backend Tests:** Verify `CreateActionPlan` correctly assigns the right `SourceTitle`.
2. **Automated Frontend Tests:** Verify the widget gracefully hides the row if `sourceTitle` is null, and displays it if present.
3. **Manual Validation:** Run `dotnet run` and `flutter run`, create an action plan from an audit and a campaign, and check the dashboard UI.

## Tools & Commands
- **Testing:** `dotnet test`, `flutter test`
- **Migration:** `dotnet ef migrations add AddActionPlanSourceTitle -s ../Checkly.Api/ -p ../Checkly.Api.Common/`

## Proposed Changes
| File | Action | Details |
|---|---|---|
| `server/Common/Persistence/Entities/ActionPlan.cs` | [MOD] | Add `public string? SourceTitle { get; set; }` property. |
| `server/Features/ActionPlans/CreateActionPlan.cs` | [MOD] | Fetch the Program Title if `ProgramAssignmentId` exists, or use `TemplateTitle`. Set `SourceTitle` accordingly. |
| `server/Features/ActionPlans/Dtos.cs` | [MOD] | Add `string? SourceTitle` to `ActionPlanDto`. Update `ToDto` mappers in `CreateActionPlan.cs`, `GetActionPlan.cs`, `ListActionPlans.cs`. |
| `lib/features/action_plans/models/action_plan_dto.dart` | [MOD] | Add `final String? sourceTitle;` to JSON parsing. |
| `lib/features/action_plans/widgets/action_plan_card.dart` | [MOD] | Add UI row for `sourceTitle` using Checkly styling. |

## Concept Diagram
```text
[Submission Created] --> [Criteria Fails] --> [Action Plan Created]
   ↳ Backend checks Submission.ProgramAssignmentId
      ↳ If YES: SourceTitle = "Campaign: [Program Name]"
      ↳ If NO: SourceTitle = "Audit: [Template Name]"
```

## Execution Slices

### Phase A: Backend API & Database
- **Summary:** Add the `SourceTitle` snapshot column, generate the EF Core migration, and update the API creation logic and DTOs to return the string.
- **Value:** The API natively supports serving the context to any client.
- **Entry State:** DB lacks the column.
- **Exit State:** DB migrated, POST and GET endpoints return `SourceTitle`.
- **Complexity:** Low. Standard EF Core property addition.

### Phase B: Frontend UI
- **Summary:** Update the Dart DTO mapping and insert the new row into the Flutter UI widget.
- **Value:** Store Managers instantly see the origin of the task.
- **Entry State:** App ignores the JSON property.
- **Exit State:** App renders the source cleanly.
- **Complexity:** Low. Simple widget update.

## Handoff Block
Run these commands one at a time:

**Phase A: Backend API & Database**
@[/tdd] Execute tests for Phase A: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260515_211200_AP01_source.md

**Phase B: Frontend UI**
@[/implement] Execute build for Phase B: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260515_211200_AP01_source.md
