# Architectural Decision Record: PBAC UI Mapping Strategy

## Input Lineage
- c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260516_120114_02_pbac_ui_mapping.md
- c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260516_115210_pbac_ui.md

## [ORIGIN_IDEA]
Evaluate PBAC (Policy-Based Access Control) UI capability mapping for enterprise-grade consistency, preferring strong structural limits over maximum flexibility when deciding between showing/hiding UI elements vs relying on capabilities.

<latent_space_scratchpad>
Both research artifacts point toward the same structural flaw: the project lacks a strict boundary between global routing PBAC and item-level contextual PBAC. Both recommend a "Bimodal" or "Strict Hybrid" approach. 
I must rigidly red-team this to ensure we aren't adopting it blindly. What are the severe risks of computing HATEOAS `allowedActions` on the backend? N+1 query explosions if evaluating item-level ownership across a paginated list of 500 items. What are the severe risks of local `PolicyManager` checks? Frontend drift where UI elements decouple from backend domain states, allowing clicks that lead to 403 Forbidden errors and destroying UX. The Pugh matrix will decide based on Origin Idea alignment (consistency/structural safety over flexibility).
</latent_space_scratchpad>

## Normalized Summary of Options
*   **Option A: Strict Bimodal / Hybrid**: Use `PolicyManager` strictly for Global Navigation (tabs, routes). Use `ActionGuard` (backend-driven `allowedActions`) strictly for contextual entity actions (buttons, cards).
*   **Option B: Frontend Heavy**: Use `PolicyManager` everywhere. The UI checks both user capability and entity status locally.
*   **Option C: Pure HATEOAS**: Backend controls all navigation and action buttons dynamically. No local `PolicyManager` usage.

## Red Team Attack Vectors
*   **Option A (Strict Bimodal) Attack**: **N+1 Database Explosion.** If the backend must compute `allowedActions` for every item in a large paginated list, and computing those actions requires ownership or hierarchy checks against the DB, the endpoint will spiral into an N+1 query disaster, bringing down the production database under moderate load.
*   **Option B (Frontend Heavy) Attack**: **Decoupled State Cascade.** The backend introduces a new entity status (e.g., "Archived"). The frontend `PolicyManager` logic isn't updated. Users see an active "Submit Evidence" button on archived items. They click it, triggering unexpected backend validation errors, or worse, if the backend lacks strict endpoint guards, modifying archived data.
*   **Option C (Pure HATEOAS) Attack**: **Offline Paralysis.** A mobile user goes offline to an oil rig and creates a local entity. Because the backend hasn't generated the HATEOAS `allowedActions` payload, the offline UI renders zero action buttons. The user is completely blocked from continuing their local workflow.

## The Pugh Decision Matrix

*Baseline Option: Option B (Frontend Heavy - Status Quo)*

| Criteria | Option B (Baseline) | Option A (Strict Bimodal) | Option C (Pure HATEOAS) |
| :--- | :--- | :--- | :--- |
| **Origin Idea Alignment (Structural Limits)** | 0 | +1 | -1 |
| **Database Load (N+1 Risk)** | 0 | -1 | -1 |
| **Offline Sync Capability** | 0 | 0 | -1 |
| **Blast Radius (UI State Drift)** | 0 | +1 | +1 |
| **Total Score** | **0** | **+1** | **-2** |

## Final Verdict
**Option A (Strict Bimodal / Hybrid)** is the mathematical winner. The structural consistency and elimination of UI state drift completely outweigh the database load risk, which can be mitigated via SQL projections on the backend rather than lazy loading.

## Executive Business Summary
To make our application "Enterprise Grade", we must stop making the mobile app guess which buttons a user is allowed to click based on the status of an item. Every time we change the rules, the app breaks. We are moving to a model where the server strictly tells the app which buttons are available for a specific item (like "Edit" or "Void"). However, for general navigation (like the Home tab), the app will still manage its own permissions. This guarantees that users never see a button they can't click, eliminating confusing "Access Denied" errors and reducing maintenance costs.

## Handoff Block
### 1. Final Verdict
Implement **Option A (Strict Bimodal)**. `PolicyManager` for Global Navigation. `ActionGuard` (backend `allowedActions`) for Contextual UI.

### 2. Strict Constraints
*   **Database Risk Mitigation (Boolean-to-String Pattern)**: To prevent EF Core query translation crashes, building string arrays directly inside `.Select()` projections is strictly forbidden. Developers MUST compute capabilities as raw booleans in the SQL projection (e.g., `CanEdit = userRole == "admin" || entity.StoreId == userStoreId`). After `.ToListAsync()` completes, use those in-memory booleans to populate the `allowedActions` string array via a Domain Entity or DTO Factory method (e.g., `entity.GetAllowedActions(canEdit, canDelete)`).
*   **Offline Fallback Ruleset**: If an entity is created locally while offline (e.g., `syncStatus == 'pending'`), the local repository MUST inject a default `allowedActions` payload that grants full local access (e.g., `["view", "edit", "delete"]`) until the record successfully syncs with the server.
*   **Drift Schema Update**: The local SQLite database schema (Drift) MUST be updated to include a `cached_allowed_actions` String column to store the array as a serialized JSON string, ensuring cached actions survive app restarts while offline.
*   **Default-Deny ActionGuard**: The Flutter `ActionGuard` widget MUST fail closed. If the `allowedActions` array is null or missing, it must hide the protected UI element entirely.

### 3. Execution Slices
*   **Slice 1**: Refactor `ActionPlanDto` to return properly computed `allowedActions`.
*   **Slice 2**: Refactor `action_plan_detail_page.dart` to remove local `PolicyManager` capability checks and replace them with `ActionGuard` driven by the DTO.

### 4. Requirements Alignment Check
If existing `requirements.md` documents specify frontend capability checks or local state evaluation rules for buttons, they MUST be updated to reflect that the API is now the single source of truth for contextual actions.

### 5. AI Agent Mission Brief
The PBAC standard is locked: Global UI = `PolicyManager`, Item UI = `ActionGuard`. The current task is to migrate Action Plans to this standard by updating the DTO and refactoring `action_plan_detail_page.dart` to use `ActionGuard`.

### 6. Next Workflow Command
```
@[/analyze-feature] c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260516_120520_SYN_pbac_ui.md
```
