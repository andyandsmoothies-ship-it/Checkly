[ORIGIN_IDEA]
The user requested research on applying a "Capability-Driven UI" into the current PBAC (Policy-Based Access Control) system. This means evaluating how the UI adapts, renders, and restricts features based on the user's loaded capabilities instead of static roles.

<latent_space_scratchpad>
- **Current Architecture**: The codebase currently utilizes `PermissionGuard` (a reactive Flutter widget wrapping `AuthManager.capabilities`) to conditionally show, hide, or disable individual widgets. The router uses `PolicyManager.can()` for some guards. Backend uses `[RequirePermission]` and `IClaimsTransformation`.
- **The Core Problem**: Capability-Driven UI asks *how* we should structure the UI. Should the UI hide buttons (Current)? Should it disable them with tooltips? Or should the backend dictate the UI (Server-Driven UI)?
- **Option A (The Native Evolution)**: Stick to `PermissionGuard` but standardize the UX. When do we hide vs when do we disable? (e.g., Hide entire tabs, but disable inline actions with a tooltip "Requires Admin").
- **Option B (The Route-First Guard)**: Extend PBAC to the GoRouter level explicitly. Hiding a button is useless if the user can type the URL. UI capabilities must perfectly match Router capabilities.
- **Option C (Server-Driven Capability UI)**: The backend DTOs inject `allowedActions: []` into every entity payload. The Flutter UI stops checking `PolicyManager` for granular actions and just renders what the DTO tells it.
- **Debate**: Option C breaks the "Offline First" constraint. Checkly is an offline-first app. If the backend dictates the UI per entity, the user cannot interact with cached entities offline because the backend isn't there to calculate `allowedActions`. We MUST reject Option C. Option A+B is the pragmatic path.
</latent_space_scratchpad>

## Current Codebase Reality (Status Quo)
Based on `grep_search` across the `lib/` directory, Checkly currently utilizes a highly localized PBAC rendering strategy:
- **`PermissionGuard`**: A reactive `StatelessWidget` that listens to `AuthManager.capabilities`. It either renders the child, renders an empty `SizedBox.shrink()` (hiding it), or renders a disabled version (`Opacity(0.5)` + `IgnorePointer`).
- **`PolicyManager`**: A synchronous class used primarily to bypass reactive streams when checking permissions in GoRouter redirects.
- **Backend Authorization**: Relying on custom `PermissionAuthorizationRequirement` to evaluate claims injected via `IClaimsTransformation`.

## E2E Workflow Map
`[AuthManager caches Capabilities]` -> `[GoRouter checks PolicyManager on deep-link]` -> `[Page Loads]` -> `[PermissionGuard wraps specific actions (e.g., FAB, List items)]` -> `[User clicks action]` -> `[Backend verifies token Claims via [RequirePermission]]`

**Context Handoff Points**:
1. **Login -> Local Cache**: JWT is decoded, capabilities are saved to SQLite/SharedPreferences.
2. **Router -> Widget**: Route protects the *Page*. `PermissionGuard` protects the *Mutation*.
3. **App -> API**: The backend completely distrusts the frontend and re-evaluates PBAC natively.

## Impact Spectrum

| Option | Approach | Architecture Implication | Verdict |
|--------|----------|--------------------------|---------|
| **(A) Standardized Local PBAC (Native Fit)** | Standardize `PermissionGuard` usage. Define explicit rules: *Hide* structural elements (Tabs, Pages). *Disable* contextual elements (Edit buttons) with Tooltips so users know features exist. | Minimal architectural change. Relies heavily on Flutter to know PBAC matrix. Requires maintaining capabilities in sync on frontend. | **APPROVED** - Fits existing paradigms perfectly. |
| **(B) Route-Driven PBAC** | Push PBAC directly into `GoRouter`. Bind `AppCapabilities` natively to route definitions. If a user lacks a capability, the route doesn't even mount. | Clean security posture, but leads to jarring UX if users are deep-linked to restricted pages without a localized "Fallback" UI explaining why. | **REJECTED** - Too rigid for micro-interactions within a page. |
| **(C) Server-Driven Capabilities (Enterprise)** | The backend API calculates permissions per-record (e.g., `TemplateDto` includes `canEdit: false`). Frontend `PolicyManager` is deleted. | Massive DTO bloat. Complete violation of the Offline-First mandate. Flutter cannot work offline if the API dictates UI. | **REJECTED** - Violates Global Rule 2 (Offline-first architecture). |

## Blind Spots & NFR Risks
1. **Network Payload Size**: If we were to migrate to Option C, embedding permission flags into every single list item DTO (e.g., 500 templates) would massively inflate JSON payload sizes, risking timeout on edge networks.
2. **Offline Capability Drift**: If an Admin removes a Manager's capabilities on the server, but the Manager's mobile app is offline, the local `AuthManager.capabilities` cache remains highly permissive. The UI will show buttons the user can no longer use, leading to sudden 403s when they finally sync.
3. **Route Navigation Leaks**: Hiding a button via `PermissionGuard` is a UI fix. If the underlying `GoRoute` is not explicitly protected by the same `PolicyManager.can()` check, malicious users can bypass the UI and type the URL path directly.

## Conflicts with Rules
- **Conflict with Offline-First Mandate**: Option C (Server-Driven PBAC) conflicts fundamentally with Checkly's offline architecture. If the UI relies on backend DTOs to determine what buttons to show, the app becomes non-functional without a live connection. We must retain Option A (Local PBAC) to ensure the UI renders instantly from the local Drift database.

<forensic_evidence>
- `view_file`: `lib/_shared/widgets/permission_guard.dart` (Verified existing wrapper component)
- `view_file`: `lib/_shared/services/policy_manager.dart` (Verified synchronous router-friendly checking)
- `view_file`: `.agents/skills/dotnet-rbac-authorization/SKILL.md` (Verified backend claims transformation)
- `grep_search`: `PermissionGuard` in `lib/` (Found widespread usage across pages and tabs)
</forensic_evidence>

---

## Handoff Block
**Final Verdict**: Option A (Standardized Local PBAC) is viable and approved. 
**Sizing**: Track A (Low Effort / High Value). Concurrency: Can be applied incrementally per feature slice.

**AI Agent Mission Brief**: 
The research confirms we should utilize the existing `PermissionGuard` and `PolicyManager`. The next step is to analyze how this specifically applies to the Campaign execution flow to ensure PBAC hides unauthorized elements without breaking offline support.

**Next Command**: 
`@[/analyze-feature] c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260514_203600_PBAC01_capability_ui.md`
