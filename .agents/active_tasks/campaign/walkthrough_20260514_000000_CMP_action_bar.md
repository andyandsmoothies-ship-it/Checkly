# Implementation Walkthrough: Campaign Action Bar

## Objective
Elevate Campaigns into a first-class feature by unifying the execution workflow around Audit Templates, transitioning from an "Action-First" to a "Template-First" mental model.

## Changes Made
- **Template Details Page (`lib/features/templates/pages/template_detail_page.dart`)**:
  - Replaced the single `ElevatedButton` for starting an audit with a comprehensive action bar (`Wrap` component for responsiveness).
  - Included 3 unified execution strategies with the exact matching PBAC constraints:
    - **Start Now**: Gated by `AppCapabilities.submissionsCreate`.
    - **Assign**: Triggers `showScheduleSheet` for task assignment, gated by `AppCapabilities.submissionsCreate`.
    - **Create Campaign**: Routes to the Campaign Creation flow `/programs/new`, gated by `AppCapabilities.programsCreate`.

- **Template Card (`lib/features/templates/widgets/template_card.dart`)**:
  - Removed the `Quick Start` redundant option from the context menu as execution is now concentrated in the Template Details page via the new unified Action Bar. 

## Testing & Verification
- **Test Integrity**: Ran `rtk flutter test`. Tests failing in unrelated background sync engines (`photo_queue_service_test.dart` and `sync_engine_test.dart`) were untouched and confirmed independent of this UI routing. 
- **Code Consistency**: `rtk flutter analyze` returned clean on modified files.
- **Security Check**: Used existing `PermissionGuard` implementations rather than inventing new authorization logic, fully enforcing the project's Policy-Based Access Control standards.

## Next Steps
In the next session, we will tackle Phase C, integrating "Active Campaigns" natively into the admin dashboard to satisfy the listing and previewing requirement originally requested.
