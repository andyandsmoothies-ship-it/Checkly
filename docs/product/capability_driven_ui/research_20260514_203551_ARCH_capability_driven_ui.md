# Research: Applying Capability-Driven UI (HATEOAS) into Checkly PBAC

[ORIGIN_IDEA]: "the applying Capability-Driven UI into my current PBAC. 1 thing i am considering is the consistent between the database - logic - and UI right now i cannot fully having the dynamic permission system to freely control those 3 elements."

<latent_space_scratchpad>
**Reasoning & Tradeoffs:**
- **Status Quo**: Currently, PBAC lives in `role_capabilities` (DB). C# API validates it via `[Authorize(Policy="x")]` or inside endpoint logic. Flutter UI uses `PermissionGuard(capability: "x")` to selectively render buttons. 
- **The Gap**: If PBAC rules change dynamically (e.g., an entity's status changes from 'Draft' to 'Active', or an Area Manager loses execution rights), the Flutter client often still renders the button (relying on `PermissionGuard`) but the API rejects it (403). This creates UI/API drift.
- **SDUI / Capability-Driven UI**: To bridge this, API responses need to include `_actions: []` or `allowedActions: []` for each entity.
- **E2E Scope**: 
  - Backend: All major Entity DTOs (e.g., `ProgramResponse`, `SubmissionResponse`) must inherit a base DTO or interface `IActionableDto { IEnumerable<string> Actions { get; } }`. The backend mapping logic calculates this array by cross-referencing the user's claims + the entity's state.
  - Frontend: `PermissionGuard` needs a structural shift. Instead of checking global static strings `AppCapabilities.programsCreate`, it should accept dynamic action arrays from the models: `ActionGuard(actions: model.actions, required: 'edit')`. Global capabilities (like showing a nav bar item) might still rely on the token claims, but entity-specific actions rely on the DTO.
</latent_space_scratchpad>

## E2E Workflow Map: Capability-Driven UI Injection

### Upstream Triggers (Backend DTOs)
1. User requests `GET /api/programs/123`.
2. Backend queries the DB, getting the Program.
3. Backend Service checks User Claims (`programs:execute`, `programs:manage`) + Entity State (`Program.Status`).
4. Service maps Entity to DTO, appending `Actions = ["view", "edit"]`.

### Downstream Effects (Frontend UI)
1. Flutter receives `ProgramDto` via standard HTTP call.
2. The UI renders the Program Details Page.
3. Instead of `PermissionGuard(capability: AppCapabilities.programsEdit)`, the UI uses `if (program.actions.contains('edit')) { renderEditButton(); }`.
4. The button perfectly mirrors backend dynamic logic without hardcoded capability checks.

## Impact Spectrum

### Option A: Strict Native Fit (Hybrid Entity-Driven UI)
- **Concept**: Leave global PBAC (token-based claims) alone for high-level routing (e.g., Can I access the Dashboard?). Add `List<string> AllowedActions` ONLY to specific, highly-volatile entities (like Campaigns or Audits).
- **Pros**: Low risk. Fixes the biggest pain points (entity state mutations) without rewriting the entire app's security model.
- **Cons**: Creates two parallel paradigms for developers to remember ("Use PermissionGuard for pages, use `model.actions` for buttons").
- **Effort**: Medium (Track B).

### Option B: Pragmatic Balance (Full BaseDto Implementation)
- **Concept**: Create a `BaseDto` in C# containing `public IEnumerable<string> Actions { get; set; } = [];`. Update all mappers. Create a `SmartActionWidget` in Flutter that takes an entity and an action key.
- **Pros**: Standardizes the pattern across the entire application. Perfect alignment between DB, Logic, and UI for all resources.
- **Cons**: Requires sweeping changes across dozens of DTOs and Flutter models.
- **Effort**: High (Track C).

### Option C: Enterprise Textbook Overhaul (True HATEOAS)
- **Concept**: The backend doesn't just send action strings, it sends full hypermedia links: `{"rel": "edit", "href": "/api/programs/1", "method": "PUT"}`. The frontend UI dynamically generates forms based on the `href` endpoints.
- **Pros**: The holy grail of SDUI. The frontend doesn't even need to know the API routes anymore.
- **Cons**: Massively over-engineered for a Flutter mobile app. Destroys type-safety.
- **Effort**: Extreme (Reject).

## Blind Spots & Risks
1. **Performance Cost (N+1)**: Calculating capabilities for a single entity is fast. Calculating `AllowedActions` for a list of 500 entities (e.g., `GET /api/programs`) might cause severe database N+1 issues if the permission logic requires sub-queries.
2. **Offline Mode (Flutter)**: Checkly is an offline-first app (SQLite Drift). If the UI relies on API payloads for `actions`, the buttons might disappear when the user goes offline because the local SQLite cache doesn't know how to calculate complex PBAC state.
3. **Action Key Drift**: The strings used in the `actions` array (e.g., `"edit"`, `"delete"`) must be strictly typed as enums on both the C# and Dart sides to prevent silent failures caused by typos.

## Conflicts with Rules
- **Conflict**: Local SQLite offline support requires models to exist in Drift. If we add `AllowedActions` to DTOs, we must decide if those actions are cached in SQLite or re-calculated by Dart offline. This directly challenges the "Offline-first with SQLite" platform architecture rule.
- **Conflict**: The codebase currently relies heavily on `PermissionGuard` for all UI gating. Transitioning to DTO-driven actions means deprecating a core, tested shared utility.

<forensic_evidence>
- `grep_search` on `PermissionGuard` (found widespread usage in `admin_active_campaigns_widget.dart`, `template_detail_page.dart`, etc.)
- `grep_search` on `ProgramDto` in `server/` to verify DTO mapping patterns.
</forensic_evidence>

---

## Handoff Block

**Final Verdict**: Viable. **Option A (Hybrid)** is the safest path forward. Global capabilities (like `programs:create`) stay in the JWT/PBAC claims, but entity-specific actions (like editing a specific campaign) migrate to the DTO's `allowedActions` array. This perfectly balances consistency without breaking offline support.

**Effort Sizing**: Track B (Medium). Concurrency Strategy: Pick one entity (e.g., `Program`) and implement the end-to-end slice as a proof-of-concept before expanding.

**AI Agent Mission Brief**:
You are awaiting the user's decision on the Capability-Driven UI architecture. Once approved, implement the `AllowedActions` array on the `ProgramDto` in C#, map it dynamically based on PBAC + Entity State, and update the Flutter UI to render buttons conditionally based on the DTO payload.

**Next Workflow Command**:
`@/implement {c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260514_203551_ARCH_capability_driven_ui.md}`
