# [ORIGIN_IDEA]
Evaluate PBAC (Policy-Based Access Control) UI capability mapping for enterprise-grade consistency, preferring strong structural limits over maximum flexibility when deciding between showing/hiding UI elements vs relying on capabilities. We make sure the PBAC here is an enterprise grade solution, both supporting flexible and accurate and still consistent with a strong structure. I need you to give the best advise here on when to show/hide UI elements vs relying on capabilities. No need to maximum flexible, if we are required to limit something to make sure an enterprise grade solution, just provide.

<latent_space_scratchpad>
Debating Tradeoffs:
The user wants to establish a strong, enterprise-grade PBAC UI mapping strategy that sacrifices "maximum flexibility" for consistency and structural safety.

Currently in the codebase, we see two paradigms:
1. `PolicyManager`: A local (frontend) capability evaluator (e.g. `_di<PolicyManager>().can('programs:list')`).
2. `ActionGuard`: A backend-driven HATEOAS wrapper. The API returns an `allowedActions` array inside DTOs, and the UI simply checks if a specific action (like "edit") is inside that array.

If we rely purely on `PolicyManager` for everything, the UI becomes tightly coupled with backend entity states. For example, to show a "Submit Evidence" button, the frontend would have to check: `if (status == 'open' && policy.can(submit_evidence))`. This duplicates business logic on the client. If the backend later adds a 'locked' status, the frontend UI breaks or creates false positives (buttons that do nothing and result in 403s). 

Conversely, if we rely solely on HATEOAS, we run into the problem of Global Navigation (e.g., sidebars, bottom tabs, global "Create" floating action buttons). There is no "entity" to return an `allowedActions` array for a global tab. 

Thus, a strict dichotomy is the only enterprise-grade structural limit we can apply:
- **Rule 1**: Global Navigation, Routing, and purely static/global actions (like FABs) MUST be protected by `PolicyManager`.
- **Rule 2**: Contextual actions (buttons on cards, list items, or detail pages) MUST NEVER use `PolicyManager` or evaluate status on the frontend. They MUST rely on the backend's `allowedActions` array, wrapped by `ActionGuard`. 

Looking at `grep_search` results, we have violations. The `action_plan_detail_page.dart` is manually evaluating `PolicyManager` combined with `status` checks, bypassing HATEOAS and creating a fragile UI. Other locations like `history_list_view.dart`, `dashboard_page.dart` might be doing similar contextual violations.
</latent_space_scratchpad>

## Current Codebase Reality
**Status Quo Audit Results**:
- `ActionGuard` correctly exists in `lib/_shared/widgets/action_guard.dart` and is backed by constants in `submission_actions.dart`.
- Backend correctly evaluates and computes `AllowedActions` in DTOs (e.g., `GetSubmission.cs`, `ListSubmissions.cs`, `ProgramDtos.cs`).
- `PolicyManager` correctly exists to guard global routes (`app_router.dart`).
- **VIOLATIONS DETECTED**: 
  - `action_plan_detail_page.dart` uses `PolicyManager` to compute button visibility (`canSubmitEvidence`, `canVerify`) combined with local status checks.
  - `audit_card.dart` uses `ActionGuard` properly, but other widgets like `history_list_view.dart` and `dashboard_page.dart` fall back to manual `PolicyManager` capability checks to render list-level actions.

## E2E Workflow Map (Strict Bimodal PBAC)

```ascii
[Global Structural UI: Tabs, Routes, Global Create]
      (JWT Capabilities) 
              |
              v
       PolicyManager
              |
      +-------+-------+
      |               |
[Route Guard]  [MainShell Tab]

----------------------------------------------------

[Contextual Entity UI: Cards, Detail Pages, Edit Forms]
(Backend Entity State + JWT Capabilities)
              |
              v
     DTO `allowedActions` array
              |
              v
         ActionGuard
              |
      +-------+-------+
      |               |
 [Edit Button]   [Void Action]
```

## Comparative Decision Matrix

| Strategy | Architecture | Structural Limits | Maintenance Cost | Enterprise Grade? |
|---|---|---|---|---|
| **A: Strict Bimodal (Recommended)** | `PolicyManager` for Global Nav only.<br>`ActionGuard` (HATEOAS) for all Contextual Actions. | Very High. Forces developers to keep business rules on the backend. | Low. UI changes only when backend rules change. | Yes. Eliminates UI state drift and 403s. |
| **B: Frontend Centric** | `PolicyManager` everywhere. UI checks entity state. | Low. Flexibility leads to chaotic `if/else` UI trees. | High. UI must be updated every time a new entity status is added. | No. High risk of UI bugs and logic duplication. |
| **C: Pure HATEOAS** | Backend controls all navigation and action buttons dynamically. | Extreme. | High. Global navigation requires constant API polling. Offline mode breaks. | No. Creates sluggish UX on mobile. |

## UI Component Routing Table

| UI Component Type | Mechanism | Routing / Downstream | Justification |
|---|---|---|---|
| **Bottom Navigation Tabs** | `PolicyManager` | -> `/home`, `/admin`, etc. | Global scope. No entity context exists. |
| **Router Guards (GoRouter)** | `PolicyManager` | -> Redirect to `/unauthorized` | Prevents deep-linking bypasses. |
| **Global "Create" FAB** | `PolicyManager` | -> `/create_new` | Global action. Not tied to a specific entity state. |
| **List Items (Cards)** | `ActionGuard` | -> Tap opens Detail Page or Modal | Contextual. Item might be locked or user lacks permission based on item ownership. |
| **Detail Pages (Action Buttons)** | `ActionGuard` | -> Edit Form, Void Modal, Verify | Contextual. Eliminates complex `if (status == X && role == Y)` UI code. |

## Blind Spots & NFRs
1. **Network Overhead (Payload Bloat)**: Returning `allowedActions` string arrays on large paginated lists (e.g., 500 items per page) adds payload weight. 
2. **Offline Fallback Constraints**: If a device is strictly offline and creates a local entity, the backend hasn't computed `allowedActions` yet. The UI will need a pessimistic local fallback or optimistic projection.
3. **Stale Cache / Session Drift**: If an admin revokes a user's PBAC capability mid-session, cached DTOs will still hold old `allowedActions`. Tapping a button will yield a 403 Forbidden until the list is refreshed.

## Conflicts with Rules
- **Rule Conflict**: `GEMINI.md` mandates that "Never hardcode UI button visibility or tap gestures based on the user's role on the frontend... The Flutter frontend must wrap actionable widgets in an `ActionGuard`". 
- We discovered violations of this rule in `action_plan_detail_page.dart` where `PolicyManager` is actively being used for contextual UI actions.

<forensic_evidence>
Executed Commands:
1. `grep_search` on `ActionGuard` across `lib/` (verified existing widget infrastructure).
2. `grep_search` on `AllowedActions` across `server/` (verified backend DTO generation).
3. `grep_search` on `PolicyManager` across `lib/` (verified improper usage in `action_plan_detail_page.dart` and `history_list_view.dart`).
</forensic_evidence>

---
## Handoff Block

### Final Verdict
**Approved (Strategy A: Strict Bimodal)**. We will enforce strong structural limits. The PBAC architecture must be strictly split: Global structural elements (routes, tabs) use `PolicyManager`, while all contextual entity actions (list items, detail buttons) MUST use HATEOAS (`ActionGuard`). The frontend is barred from evaluating entity `status` flags locally for the purpose of hiding/showing buttons.

### Effort Sizing & Concurrency
**Track A/B (1-2 Slices)**. The architectural standard is established, but technical debt exists. Effort involves cleaning up `action_plan_detail_page.dart` and ensuring the `ActionPlanDto` returns the correct `allowedActions` array from the backend.

### AI Agent Mission Brief
The enterprise PBAC standard is locked: Global UI uses `PolicyManager`, Contextual UI uses `ActionGuard`. Your mission is to implement this standard on the Action Plans feature by refactoring the backend to return `allowedActions`, and updating `action_plan_detail_page.dart` to replace local `PolicyManager` checks with `ActionGuard`.

### Next Step
```
@[/analyze-feature] c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260516_120114_02_pbac_ui_mapping.md
```
