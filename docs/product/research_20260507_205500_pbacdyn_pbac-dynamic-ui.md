# Research: PBAC Dynamic UI Migration

## [ORIGIN_IDEA]
The user's objective is to systematically eliminate hardcoded role-based checks (like 'admin' or 'auditor' string literals) across the Checkly frontend and backend. These checks currently dictate UI visibility (tabs, buttons) and data filtering (dropdowns). The goal is to replace them with dynamic Policy-Based Access Control (PBAC) capability checks to ensure a more scalable, secure, and maintainable authorization system, minimizing hardcoding as much as possible.

---

<latent_space_scratchpad>
## Internal Reasoning & Tradeoffs

**Hypothesis**: We can eliminate all `role == 'x'` checks in the frontend.
**Source Checked**: `grep_search` in `lib/` and `server/`.
**Rejected/Approved**: Partially Rejected.
**Architectural Implication**: While we *can* and *should* eliminate role checks for **Mutation/Visibility** (e.g., "Can this user see the Void button?"), we cannot eliminate role checks for **Domain Schemas/Structural Logic**. For example, an `Area Manager` intrinsically has a different data schema (they manage multiple `assignedStoreIds`) than a `Store Manager` (manages one `storeId`). Trying to "PBAC" schema differences is an anti-pattern. We should introduce a `UserPersona` typed enum for structural branches, and `PolicyManager.can(AppCapabilities.xyz)` for everything else.

**Backend RLS (Row-Level Security)**:
The backend currently scopes data (e.g., `GetStoreDashboard.cs`) using `role == "store_manager"`. PBAC capabilities (e.g., `stores:read`) grant *functional* permission, but lack *resource constraints* (which store?). Removing role-based scoping requires a massive Attribute-Based Access Control (ABAC) overhaul. 
**Tradeoff Decision**: Leave Row-Level Security on the backend as role-based (or ownership-based) to abide by "Keep it Simple". Focus the PBAC migration exclusively on Feature Access and API execution.

**DDoS Risk in `CapabilityAuthorizationHandler`**:
My `grep_search` revealed that the backend `CapabilityAuthorizationHandler` executes `await db.RoleCapabilities.AnyAsync(...)` on *every single request*. The loaded skill `dotnet-rbac-authorization` explicitly warns that this causes "IClaimsTransformation DB DDoS" if not cached. This is a critical prerequisite fix.
</latent_space_scratchpad>

## E2E Workflow Map

**Upstream Triggers (Frontend `lib/`)**
1. **Dropdowns/Filters**: Forms (e.g., `AdminAuditManager`, `UserEditSheet`) check `u['role'] == 'auditor'` to populate auditor selection lists.
2. **Feature Toggles**: UI logic (e.g., `history_list_view.dart`, `profile_page.dart`) checks `role == 'admin'` to show the "Void" button or specific tabs.
3. **Data Shape Modifiers**: Forms dynamically render multi-selects vs single-selects based on `role == 'area_manager'`.

**Downstream Effects (Backend `server/`)**
1. **Endpoint Resolution**: The frontend sends requests, and `CapabilityAuthorizationHandler` queries the DB per request to map the user's role to a capability.
2. **Data Scoping (RLS)**: Endpoints like `ListActionPlans.cs` check the user's role to append `.Where()` clauses to EF Core queries, limiting the records returned.
3. **Dropdown API**: There is currently no endpoint that returns users *by capability*. The app relies on downloading the entire user list.

## Comparative Decision Matrix

| Approach | Description | Source Checked | Status | Architectural Implication |
| :--- | :--- | :--- | :--- | :--- |
| **A: Hybrid Capability & Typed Persona (Recommended)** | Replace Feature/UI Access with `policyManager.can()`. Add backend endpoints to serve capability-filtered lists (e.g., `/api/users?capability=...`). Replace remaining structural role checks with a strongly-typed `UserPersona` enum. Leave backend Data Scoping (RLS) as is. | `lib/features/admin`, `server/Features` | **Approved** | Pragmatic. Solves the hardcoded string problem, introduces type safety for schema variations, and prevents backend over-engineering. |
| **B: Total ABAC Overhaul** | Implement Attribute-Based Access Control. Capabilities include resource IDs (e.g., `store:read:15`). | N/A | **Rejected** | Violates "Keep it Simple". Massive backend rewrite. |
| **C: Local Frontend Filtering** | Keep backend as is. Sync all capabilities to the client, download all users, and filter locally. | `server/Features/Admin/ListUsers.cs` | **Rejected** | Terrible network payload bloat. Huge data privacy leak (fetching all users). |

## <forensic_evidence>
Executed `grep_search` for `role ==|currentUserRole ==|role'\] ==` in `c:\Users\HP\Documents\GitHub\Checkly\lib` (Found 39 occurrences across router, DAOs, dashboards, and admin sheets).
Executed `grep_search` for `Role ==|ClaimTypes.Role|User.IsInRole` in `c:\Users\HP\Documents\GitHub\Checkly\server` (Found >24 occurrences across EF Core queries and Authorization Handlers).
Loaded Skill: `dotnet-rbac-authorization`
Loaded Skill: `flutter-architecture`
</forensic_evidence>

---

## Handoff Block

- **Verdict**: Viable. Proceed with Option A. We will migrate access/action checks to PBAC capabilities using `PolicyManager`. We will migrate remaining structural role checks to a typed `UserPersona` enum. We will fix the backend DDoS vulnerability in the Authorization Handler.
- **Sizing**: Track C (Epic). Requires backend caching fixes, new endpoints, and sweeping multiple Flutter features.
- **AI Agent Mission Brief**: The Builder agent needs to sweep the Flutter codebase to replace hardcoded `role == 'x'` strings with `PolicyManager.can(AppCapabilities.xyz)`, create a typed `UserPersona` enum for layout structural branches, and add an `IMemoryCache` to the backend `CapabilityAuthorizationHandler` to prevent database exhaustion.
- **Next Command**: Please pass this directly to the feature analysis workflow by running: `/analyze-epic {c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260507_205500_pbacdyn_pbac-dynamic-ui.md}`
