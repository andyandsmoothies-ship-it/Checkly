# ADR: PBAC Dynamic UI — Master Architecture Decision Record

**ShortID:** a736cb  
**Date:** 2026-05-07  
**Status:** DECIDED  
**Workflow:** /synthesize (The Thunderdome)

---

## [ORIGIN_IDEA]
Systematically eliminate hardcoded `role == 'x'` string checks from the Checkly Flutter frontend AND backend. Replace them with dynamic Policy-Based Access Control (PBAC) capability checks (`PolicyManager.can()` / `PermissionGuard`) and a typed `UserPersona` enum for structural layout decisions only. The goal is a scalable, secure, and maintainable authorization system with zero magic strings.

---

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260507_203733_pbacdyn_pbac-dynamic-ui.md`
- `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260507_205500_pbacdyn_pbac-dynamic-ui.md`

---

<latent_space_scratchpad>
## Internal Debate

Both research files converged on Option A independently. This is a strong signal — the idea is correct.

**The key synthesis insight is combining unique findings from each file:**
- File `203733` found the frontend risks: Offline Capability Drift and PolicyManager Race Conditions.
- File `205500` found the backend risk: the CapabilityAuthorizationHandler DB DDoS.

Neither file alone had the complete picture. The Master Architecture must include ALL three mitigations.

**Critical architectural nuance:** The `UserPersona` enum must NOT be derived at runtime from a cached role string. It must be a first-class field in the server's sync payload (`/api/auth` or `/api/system/capabilities` response). If it is computed from a cached role, the Offline Persona Desync attack vector is live.

**Backend RLS Decision:** Both files explicitly agreed — leave Row-Level Security as role/ownership-based. This is correct. PBAC handles "what can you DO", not "which rows can you READ". Mixing them is an ABAC overhaul and violates "Keep it Simple".

**Key gotcha for Builder:** The `CapabilityAuthorizationHandler` DDoS fix is a PREREQUISITE. It must be implemented BEFORE the Flutter sweep. If the Flutter app now calls capability-gated endpoints more frequently (because more things are gated), and the handler is still hitting the DB on every request, the fix will make things WORSE before the cache is in place.
</latent_space_scratchpad>

---

## Normalized Option Summary

### Option A: Hybrid PBAC + Typed UserPersona (THE WINNER)
- **Source:** Both research files, independently.
- **Core Idea:** Replace all feature/action/visibility checks with `PolicyManager.can(AppCapabilities.xyz)` and `PermissionGuard`. Replace all structural layout branches (e.g., "which dashboard scaffold to render") with a strongly-typed `UserPersona` enum. Leave backend Row-Level Security as role/ownership-based.
- **Unique Contributions:**
  - From `203733`: Found `PolicyManager` and `PermissionGuard` are already implemented. Found race condition and offline drift risks.
  - From `205500`: Found the backend `CapabilityAuthorizationHandler` has a DB DDoS vulnerability. Found no capability-filtered user list endpoint exists.

### Option B: Pragmatic Balance (REJECTED)
- Only migrates mutation/admin checks. Leaves dashboard routing in magic strings.
- **Fatal Flaw:** Violates GEMINI.md. Leaves the system broken for any future new role.

### Option C: Server-Driven UI / Full ABAC (REJECTED)
- Backend dictates widget layout. Full Attribute-Based Access Control.
- **Fatal Flaw:** App bricks when offline. Contradicts the offline-first architecture mandate.

---

## Red Team Attack Vectors

### Attack on Option A (The Winner)
**The Offline Persona Desync:** A user is promoted from Store Manager to Area Manager on the server while offline. Capabilities sync correctly on next login. But if `UserPersona` is derived from a cached role string, the dashboard scaffold is still the old single-store layout. Multi-store data is crammed into a single-store widget — broken UI with no error message.
- **Mitigation:** `UserPersona` MUST be a first-class field in the server's auth/capability sync payload. It must NOT be computed from a locally cached role string at runtime.

### Attack on Option B
**The New Role Silent Failure:** A new `regional_director` role is added. Capabilities are correctly seeded. But dashboard routing still checks `if (role == 'area_manager')`. The new role routes to the wrong dashboard silently. No test, no compiler warning catches this.
- **Verdict:** No mitigation. The option is architecturally broken by design.

### Attack on Option C
**The Offline Brick:** The Flutter app depends on the server to send widget instructions. When offline, there are no instructions. The dashboard is blank. A field-worker app designed for low-connectivity cannot function.
- **Verdict:** No mitigation without rebuilding the offline-first architecture from scratch.

---

## Pugh Decision Matrix

**Baseline:** Option A

| NFR Criterion | Option A (Baseline) | Option B | Option C |
|---|---|---|---|
| **Origin Idea Alignment** (3x weight) | `0` | `-1` | `-1` |
| **Offline Sync Safety** | `0` | `0` | `-1` |
| **Main Thread Performance** | `0` | `0` | `-1` |
| **Backend Database Load** | `0` (needs cache fix) | `0` | `-1` |
| **Blast Radius / Risk** | `0` | `+1` (smaller scope) | `-1` |
| **GEMINI.md Compliance** | `0` | `-1` | `0` |
| **Future-Proofing** | `0` | `-1` | `0` |
| **TOTAL** | **0** | **-2** | **-4** |

**Mathematical Winner: Option A**

---

## Final Verdict

**Option A: Hybrid PBAC + Typed UserPersona is the Master Architecture.**

The Master Architecture combines ALL findings from both research files:

1. **Flutter Sweep (from `203733`):** Replace every `role == 'x'` string in the Flutter codebase (`profile_page.dart`, `dashboard_manager.dart`, `history_list_view.dart`, admin sheets) with `PolicyManager.can(AppCapabilities.xyz)` or `PermissionGuard(capability: ...)`. Replace structural layout branches with a new strongly-typed `UserPersona` enum.
2. **Backend Cache Fix — PREREQUISITE (from `205500`):** Add `IMemoryCache` to `CapabilityAuthorizationHandler` to prevent DB DDoS. This MUST be implemented BEFORE the Flutter sweep goes live.
3. **New Backend Endpoint (from `205500`):** Create a `/api/users?capability=...` endpoint so the frontend does not need to download all users and filter locally.
4. **Leave RLS alone (both files agree):** Backend Row-Level Security stays as role/ownership-based. PBAC handles feature access only.
5. **Persona Sync Fix (from Red Team):** `UserPersona` must be included as a first-class field in the server sync payload — never derived from a cached local role string.

---

## Executive Business Summary

**For the Product Owner — Plain English:**

Right now, the app has a security risk. If we add a new job role (e.g., "Regional Director"), a developer must manually find and update dozens of hidden code checks across the app. Miss one, and a Regional Director sees the wrong screen — or worse, sees data they should not see.

After this change, the app will use a "Permissions Card" system. Each user gets a card from the server listing exactly what they are allowed to do. The app reads the card — it does not need to know the user's job title. Adding a new role now takes 1 database change, not 30 code changes.

The biggest risk found is on the backend server: it is currently asking the database "what can this user do?" on every single API call. This wastes database resources and could slow the app under heavy load. The first fix we must ship is a server-side cache that holds this answer in memory so the database is only asked once per user session.

---

## Handoff Block

**Final Verdict:** Option A — Hybrid PBAC + Typed `UserPersona`.

**Strict Constraints (Builder MUST NOT ignore):**
1. **PREREQUISITE FIRST:** Implement `IMemoryCache` in `CapabilityAuthorizationHandler` BEFORE deploying the Flutter capability sweep. Deploying Flutter changes first increases DB load before the fix is in.
2. **UserPersona Source of Truth:** The `UserPersona` enum value MUST come from the server sync payload as a first-class field. It must NEVER be computed from a locally cached role string.
3. **Backend RLS is OFF-LIMITS:** Do NOT touch Row-Level Security `.Where()` clauses in `GetStoreDashboard.cs` or `ListActionPlans.cs`. Leave role-based data scoping as-is.
4. **No New ABAC Patterns:** Do not introduce resource-scoped capabilities (e.g., `store:read:15`). This is a PBAC feature migration, not an ABAC overhaul.
5. **39+ Flutter occurrences:** `grep_search` found 39+ `role ==` instances in `lib/`. The Builder must use `grep_search` to locate all of them systematically — do not rely on memory.

**Execution Slices (Recommended Order):**
- **Slice 1 (Backend — BLOCKER):** Add `IMemoryCache` to `CapabilityAuthorizationHandler`. Add `/api/users?capability=` endpoint.
- **Slice 2 (Flutter — Core Sweep):** Replace `role ==` checks in `profile_page.dart`, `dashboard_manager.dart`, `history_list_view.dart` with `PolicyManager.can()` / `PermissionGuard`.
- **Slice 3 (Flutter — Structural):** Create `UserPersona` typed enum. Replace all layout/scaffold branching logic.
- **Slice 4 (Flutter — Admin):** Replace role filters in `AdminAuditManager`, `UserEditSheet` dropdowns with capability-based backend endpoint.

**Requirements Alignment Check:**
> [!WARNING]
> The introduction of the `/api/users?capability=` endpoint is a new API contract not previously defined in any `requirements.md` file. If a requirements document exists for this feature, it MUST be updated to include this new endpoint before the Builder begins Slice 1.

**AI Agent Mission Brief:**
> Fix the backend `CapabilityAuthorizationHandler` DB DDoS with `IMemoryCache` first (BLOCKER). Then sweep all 39+ `role ==` instances in the Flutter `lib/` directory, replacing them with `PolicyManager.can(AppCapabilities.xyz)` / `PermissionGuard`, and create a typed `UserPersona` enum for structural layout branches only.

**Next Workflow Command:**
```
/analyze-epic c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\decision_record_20260507_211849_a736cb_pbac-synthesize.md
```
