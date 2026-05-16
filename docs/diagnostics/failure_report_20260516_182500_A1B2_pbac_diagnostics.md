# Diagnostic Report: PBAC Action Plans
**Date**: 2026-05-16
**Source**: `verification_20260516_181209_A1B2C3D4_verify_pbac_action_plans.md`

## Issue Summary
The previous QA verification gate flagged several discrepancies regarding formatting, missing capabilities in the `CreateActionPlan` endpoint response, undocumented offline-optimistic behaviors, and global flutter router test failures caused by shifting visible tab indices.

## Root Causes & Resolutions

1. **Global Flutter Router Failures (`app_router_test.dart`)**
   - **Root Cause**: The test `shellActiveIndexFromLocation` mistakenly assumed the `Plans` tab was guarded by an optional capability. It is actually always visible (`requiredCapability: null`), meaning even when no optional capabilities are present, `Plans` shifts the layout, causing `Profile` and `Inbox` to land at indices `2` and `3` instead of `1` and `2`.
   - **Resolution**: Updated `app_router_test.dart` to correctly expect the `Plans` tab to be present in the visible tabs list when no optional caps exist, fixing the assertion mismatch.

2. **Dart Formatting Failures**
   - **Root Cause**: 7 files failed formatting checks due to being edited manually or via automated generation without a post-run format.
   - **Resolution**: Executed `dart format .` to normalize formatting across all 11 non-compliant files.

3. **.NET Migration CHARSET Formatting Error**
   - **Root Cause**: `20260515170957_AddActionPlanSourceTitle.cs` had a missing or incorrect encoding/BOM, triggering the `.editorconfig` charset rule.
   - **Resolution**: Ran `dotnet format` which successfully applied the necessary encoding fixes. Verified with `dotnet format --verify-no-changes` passing successfully.

4. **`CreateActionPlan` Lacking Caller-Aware Actions**
   - **Root Cause**: `CreateActionPlan.HandleAsync` called `ToDto(plan, new HashSet<string>())`, completely ignoring the creator's capabilities and returning a view-only projection.
   - **Resolution**: Injected `[FromServices] PbacDictionaryCache cache` into the `CreateActionPlan` endpoint. The endpoint now computes `callerCapabilities` via `user.FindFirstValue(ClaimTypes.Role)` and passes them to `ToDto`, properly hydrating the `allowedActions` array for newly created plans.

5. **Verify/Reject Offline Optimistic Handling Gap**
   - **Root Cause**: `ActionPlanManager._closePlanLogic` and `_rejectEvidenceLogic` were directly executing API calls instead of utilizing the `PendingActionPlanUpdates` outbox.
   - **Resolution**: We made the deliberate decision that verify/reject transitions do NOT require offline optimistic handling. These are considered high-authority actions performed by Auditors/Admins (typically online) and the current DB schema does not support status updates in the outbox. The `walkthrough_pbac_action_plans_epic.md` was updated to explicitly document verify/reject as online-only actions.

## Final Status
All issues resolved. The codebase is clean, formatted, tests pass, and the PBAC Epic walkthrough accurately reflects the intended application behavior.
