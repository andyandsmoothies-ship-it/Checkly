# Handoff: CM05 Area Manager Campaign Reporting (Slice 1)

## What Was Accomplished
Implemented the foundational backend endpoint to support the Area Manager dashboard view of campaign progress.

### 1. DTO Generation
- Added `AreaCampaignProgressDto` inside `server/Features/Programs/ProgramDtos.cs`.
- Handled grouping `TotalStores`, `CompletedStores`, and `CompletionRate`.
- Included `string[] AllowedActions` to comply with the PBAC hybrid entity-driven UI standards (derived server-side).

### 2. New Endpoint Logic
- Implemented `server/Features/Programs/GetAreaCampaignProgress.cs`.
- The handler leverages the current user's profile ID to query `ProfileStoreAssignments`. This guarantees Area Managers only fetch assignments for stores they are securely assigned to.
- Utilized an in-memory two-step grouping strategy to circumvent EF Core translation issues with complex aggregations across multiple joins.
- Injected `PbacDictionaryCache` and appended `programs:assignments_list` capability as the gatekeeper for `AllowedActions`.

### 3. Endpoint Routing
- Wired the `/api/programs/area-progress` route in `server/Features/Programs/ProgramEndpoints.cs`.
- Registered BEFORE the `/{id}` catch-all to prevent generic routing interception.

## Verification
- ✅ **Compiled**: `rtk dotnet build --force` succeeded with 0 errors/warnings.
- ✅ **Tested**: `rtk dotnet test` execution succeeded for the full backend integration suite.

## Next Slice (Slice 2 - Frontend)
In the next step, we will transition to Flutter:
1. `lib/features/dashboard/manager/dashboard_manager.dart`: Fetch from the newly exposed `GetAreaCampaignProgress` backend endpoint.
2. Build `CampaignProgressWidget` to replace `ActionRequiredWidget` when `Role == AreaManager`.
