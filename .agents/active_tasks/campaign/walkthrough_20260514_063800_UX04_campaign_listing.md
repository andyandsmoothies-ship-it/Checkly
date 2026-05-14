# Walkthrough: Campaign Dashboard UX & Action Bar Elevate

## 1. Overview
This walkthrough summarizes the structural changes and user-experience refinements made to elevate Campaigns as a first-class citizen in both the Admin and Store Manager dashboards. 

This work fulfills the heuristic UX evaluation requirements and centralizes template execution logic.

## 2. Terminology Standardization
- **Change**: Replaced all user-facing references to "Programs" with "Campaigns".
- **Impacted Areas**:
  - `ProgramDashboardPage` title is now "Campaign Dashboard".
  - `ProgramListPage` UI strings updated to "Campaigns".
  - `ProgramCreateWizardPage` and `ProgramWizardSteps` terminology completely updated to match.
  - `CapabilityDictionary.dart` display strings updated for RBAC consistency.

## 3. Store Manager Dashboard & Truncation
- **Problem**: The `ActionRequiredWidget` previously listed an uncapped stream of pending campaigns.
- **Solution**: 
  - Implemented truncation, limiting the preview to the top 3 pending campaigns.
  - Appended a "View All" text button below the truncated list.
  - Created and routed `ProgramAssignmentListPage` (`/programs/assignments`) to handle the full, untruncated display when the user clicks "View All".

## 4. Admin Dashboard Visibility
- **Problem**: Active Campaigns were previously hidden inside a condensed `CompactStatusPanel` row.
- **Solution**: 
  - Extracted the campaign preview into a standalone `AdminActiveCampaignsWidget`.
  - The new widget leverages a prominent horizontal-scrolling card layout (limited to 3 items) and a "View All" link to better broadcast active campaign health.

## 5. Template Execution Consolidation (CMP01)
- **Problem**: The Context Menu (`TemplateCard`) was overcrowded, and the primary execution CTA (`"Start Audit"`) on `TemplateDetailsPage` did not accommodate assigning or creating campaign logic gracefully.
- **Solution**: 
  - **Details Page**: Replaced the isolated "Start Audit" button with a cohesive bottom action bar. The new row seamlessly fits `"Start Now"`, `"Assign"`, and `"Create Campaign"` buttons.
  - **Access Control (PBAC)**: Each button strictly evaluates the user's capabilities (`AppCapabilities.programsCreate`, etc.) via `PermissionGuard` before rendering.
  - **Context Menu Cleanup**: Deleted `"Quick Start"` from the template card popup menu to remove redundancy and reduce cognitive load. 
  - **RBAC Refinement**: If a user (e.g., Auditor) lacks `templatesUpdate` or `templatesDelete` capabilities, the context menu `PopupMenuButton` icon is hidden completely (as verified by TC-08).

## 6. Verification
- **Code Analyzers**: Fixed remaining analyzer warnings (unused imports, multi-underscore parameters, and `CoreAuditSyncModule` constructor mismatches).
- **Test Integrity**: Executed the global `.NET` and `Flutter` test suites. 
  - Adjusted `template_list_page_rbac_test.dart` to assert correctly against the removed `"Quick Start"` option.
  - All 495 tests currently pass with `exit code 0`.
