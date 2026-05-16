# Epic Walkthrough: Enterprise Action Plan PBAC Migration

This document outlines the complete end-to-end implementation of the Policy-Based Access Control (PBAC) migration for the Action Plans module. The goal of this epic was to migrate from legacy, frontend-driven role-guessing to a **Bimodal Hybrid PBAC Model** where the backend serves as the source of truth for all permitted actions.

---

## 🏗️ Phase A: Backend Action Contract

The backend was upgraded to act as the sole source of truth for what actions a user can perform on any given action plan based on their permissions and the entity's state.

1. **New Action Keys**: Defined strongly typed action constants (`submitEvidence`, `verifyClose`, `rejectEvidence`) in `ActionPlanActions.cs`.
2. **DTO Projection**: Updated the `ActionPlanDto` record to include a new `string[] AllowedActions` property.
3. **Endpoint Projections**:
   - Updated `ListActionPlans`, `GetActionPlan`, `CreateActionPlan`, and `UpdateActionPlan` handlers.
   - Leveraged `IAuthorizationService` dynamically within the projections to verify claims (e.g., `AppCapabilities.ActionPlansWrite` and `Verify`) to compute exact buttons the user can see based on the plan's current status (`open` vs `pending_verify`).
4. **Testing**: Implemented exhaustive integration tests in `ActionPlanAllowedActionsTests.cs` to guarantee that different token claims accurately modify the returned `AllowedActions` array without causing N+1 queries.

---

## 💾 Phase B: Flutter DTO, Drift Cache, & Offline State

The frontend data layer was completely upgraded to securely hold, cache, and optimistically transition the new server payload.

1. **Flutter DTO Extension**: Extended the Flutter `ActionPlanDto` to serialize and deserialize `allowedActions`.
2. **Drift Database Migration (v28)**: 
   - Added a `cached_allowed_actions` column to the local SQLite database.
   - Configured it to store the array as serialized JSON so that it persists safely offline.
3. **Manager & Cache Split**: 
   - Extracted all caching serialization logic into `action_plan_cache_mapper.dart` to prevent the `ActionPlanManager` from bloating past the 250-line complexity limit.
   - Updated the sync engine to persist `allowedActions` during background synchronization.
4. **Optimistic Offline Transitions**: 
   - Updated `action_plan.dart` domain logic to safely default `allowedActions` to `['view', 'edit', 'delete']` for locally created offline plans.
   - Ensured that when a store manager optimistically submits evidence while offline, the local `allowedActions` are safely re-computed or retained until the server provides the final truth.
   - **Decision Guard**: Verification and Rejection transitions by Auditors/Admins are strictly online-only, throwing network errors offline rather than queuing in the outbox, matching intended enterprise security behaviors.
5. **Testing**: 41 ATDD scenarios were green-lit to guarantee deterministic cache persistence and offline stability.

---

## 🖥️ Phase C: Detail UI Enforcement & File Split

The UI layer was aggressively cleaned up to blindly obey the backend's `allowedActions` array, removing all local guessing logic.

1. **`ActionPlanActionGuard` Widget**: 
   - Built a fail-closed wrapper widget that listens solely to `plan.allowedActions`.
   - If the required action string is missing, the widget gracefully falls back or hides its children.
2. **Clean UI Orchestration**: 
   - Refactored `ActionPlanDetailPage.dart`, shrinking it from >300 lines down to 155 lines.
   - Orchestration logic (BottomSheet for submitting evidence, Dialogs for verifying/rejecting) was extracted into the cleanly scoped `action_plan_detail_actions.dart`.
3. **Action Bar Refactor**: 
   - Rewrote `ActionPlanActionBar` to remove all legacy boolean flags (`canSubmitEvidence`, `canVerify`). 
   - The UI buttons now dynamically appear strictly based on the guard wrapping them.
4. **Complete Verification**: 
   - Ran `flutter test` across the module; all UI tests assert that buttons remain strictly hidden when permissions are stripped.
   - `flutter analyze` completed with 0 warnings.

---

> [!SUCCESS] Epic Finished
> The Action Plans feature is now fully operating on the Enterprise PBAC standard. The UI is clean, offline persistence is fully supported, and all security decisions are computed at the server boundary.
