# Implementation Plan: Profile Campaign Integration

We will relocate the **Campaigns** navigation entry point from the PLANS page (`ActionPlansPage`) to the Profile page (`profile_page.dart` -> `ProfileWorkspaceSection`) as a Tier-1 elevated card, alongside the existing "Admin Dashboard" card.

## Proposed Design (Text Visual representation)
```
[Profile Page]
 └── [MY WORKSPACE Section]
      └── [Card Container]
           ├── [Admin Dashboard Card (Primary Container bg, Shield Icon)]
           ├── (Space)
           ├── [Global Campaigns Card (Tertiary Container bg, Megaphone Icon)]
           ├── (Divider, if hasTemplates is true)
           └── [Templates secondary list tile, if hasTemplates is true]
```

## Step-by-Step Changes

### 1. Update `ActionPlansPage`
- **File**: `c:\Users\HP\Documents\GitHub\Checkly\lib\features\action_plans\pages\action_plans_page.dart`
- **Task**: 
  - Remove `_CampaignsNavCard` widget call from the `Column` children list (line 176).
  - Delete `_CampaignsNavCard` class completely (lines 289-327) to avoid dead code.

### 2. Enhancing `AdminCommandCard`
- **File**: `c:\Users\HP\Documents\GitHub\Checkly\lib\features\profile\widgets\admin_command_card.dart`
- **Task**:
  - Add optional parameters `overrideIconColor` and `overrideTextColor` to easily customize the color scheme for alternate themes (e.g. tertiary container).
  - Update `build` method to respect these overrides.

### 3. Updating `ProfileWorkspaceSection`
- **File**: `c:\Users\HP\Documents\GitHub\Checkly\lib\features\profile\widgets\profile_workspace_section.dart`
- **Task**:
  - Remove "Campaigns" entry from `_buildAdminSecondaryTools` so it is not duplicated.
  - Add the second `AdminCommandCard` under the `Admin Dashboard` card inside `_buildAdminWorkspace`.
  - Pass the megaphone icon (`Icons.campaign_rounded`) or similar and use `Theme.of(context).colorScheme.tertiaryContainer` as the background, with tertiary text and icon colors.
  - Clean up the divider and secondary tool rendering logic to only display if `hasTemplates` is true.

## Verification Checklist
- Run compilation tests to verify zero compiler warnings or errors.
- Verify through code walk-through that the routing (`context.push('/programs')`) matches existing GoRouter paths.
