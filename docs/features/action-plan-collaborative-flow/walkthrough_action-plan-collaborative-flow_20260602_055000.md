---
ConversationID: eff00973-14e1-4499-8eb8-460c7cb83703
---

# Walkthrough: Action Plan Collaborative Flow

[UI: Submit Evidence] --(Proposed Root Cause & Correction)--> [Local Database / Outbox] --(Sync)--> [ASP.NET Core Backend]
[UI: Verify & Close] --(Verified Root Cause & Correction)--> [Local Database / Outbox] --(Sync)--> [ASP.NET Core Backend]

This walkthrough describes the successful implementation of the Action Plan Collaborative Flow feature across the C# backend and Flutter mobile client.

## Core Accomplishments

1. **Persistent Root Cause & Correction Plan Mapping**:
   - Integrated `rootCause` into the Drift schema under `PendingActionPlanUpdates`.
   - Updated the domain transition logic to fully capture both `rootCause` and `correctionPlan` during state changes.
   - Synchronized these new columns with the database outbox and the ASP.NET Core remote API.

2. **Automated Verifier Resolution**:
   - Refactored ASP.NET Core backend `UpdateActionPlan` endpoint.
   - Automatically resolves `VerifierName` from the current authenticated user session context upon transitioning status to `closed`.

3. **Store Manager Collaborative Flow (`SubmitEvidenceSheet`)**:
   - Upgraded the bottom sheet layout to include two robust text fields: Proposed Root Cause and Proposed Correction Plan.
   - Fully validated and required both inputs before allowing submission.
   - Pre-populated the correction plan text field with the existing correction plan or default instructions.

4. **Auditor/Admin Collaborative Flow (`VerifyDialog`)**:
   - Created a modern, premium form dialog for verifying and rejecting action plans.
   - For verification, includes input fields for Verified Root Cause and Verified Correction Plan.
   - Pre-populates fields with the Proposed values from the Store Manager's submission to minimize typing.
   - Dynamically locked fields in the detail page list view once verified or closed.

## Modified Files

- [tables.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/_shared/database/tables.dart)
- [app_database.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/_shared/database/app_database.dart)
- [app_database.g.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/_shared/database/app_database.g.dart)
- [action_plan_outbox_dao.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/_shared/database/dao/action_plan_outbox_dao.dart)
- [action_plan_manager_transitions.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/action_plans/manager/action_plan_manager_transitions.dart)
- [action_plan_sync_module.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/action_plans/sync/action_plan_sync_module.dart)
- [ActionPlanController.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/ActionPlans/ActionPlanController.cs)
- [submit_evidence_sheet.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/action_plans/widgets/submit_evidence_sheet.dart)
- [action_plan_detail_actions.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/action_plans/pages/action_plan_detail_actions.dart)
- [stale_conflict_banner.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/action_plans/widgets/stale_conflict_banner.dart)
- [action_plan_detail_list.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/action_plans/widgets/action_plan_detail_list.dart)

## Validation Summary

- Verified offline storage behavior via: `action_plan_outbox_dao_stale_test.dart`
- Verified dynamic actions rendering according to PBAC permissions: `action_plan_detail_page_pbac_test.dart`
- Verified offline synchronization and stale closed action plan recovery: `sync_engine_action_plan_stale_state_test.dart`
- All unit and widget tests compile, execute, and pass successfully!
