# ADR: Capability-Driven UI Architecture for Checkly PBAC
**Record ID**: SYN01
**Date**: 2026-05-14
**Status**: Decided
**Author**: Scout (AI Architect)

---

## Input Lineage

| # | Artifact |
|---|----------|
| R1 | `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260514_203600_PBAC01_capability_ui.md` |
| R2 | `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260514_203551_ARCH_capability_driven_ui.md` |
| REF1 | `C:\Users\HP\Documents\GitHub\Checkly\docs\reference\api7-ai-learning-center-api-101-hypermedia-apis.md` |
| REF2 | `C:\Users\HP\Documents\GitHub\Checkly\docs\reference\www-apiscene-io-dx-ai-driven-hateoas-hypermedia-restful-api-.md` |

---

## [ORIGIN_IDEA]

> "Apply a Capability-Driven UI to the current PBAC system. One thing I am considering is the **consistency between database → logic → UI**. Right now I cannot fully have a dynamic permission system to freely control those 3 elements."

This is the immutable business goal. Any option that does not solve this DB↔Logic↔UI consistency problem is disqualified, regardless of technical elegance.

---

<latent_space_scratchpad>

## Internal Debate

**Core tension identified:**
- R1 (PBAC01) focused on the UI-only layer. It concluded: "Keep PermissionGuard, standardize it." This is a safe, low-risk answer — but it does NOT fully solve the [ORIGIN_IDEA]. The user wants DB↔Logic↔UI to be consistent. Just standardizing PermissionGuard still leaves a gap: when a Campaign goes from "Draft" to "Active", the server knows this affects permissions, but the local `PermissionGuard` still reads from a static JWT capability string. This causes UI/API drift.
- R2 (ARCH) correctly identified this gap and proposed the Hybrid approach: keep global JWT PBAC for routing, but add `AllowedActions: []` to volatile entity DTOs. This is the more complete answer to the [ORIGIN_IDEA].
- R2's Option B (Full BaseDto) is seductive but crosses the Blast Radius line — dozens of DTOs, dozens of Flutter models.
- R2's Option C (True HATEOAS) is explicitly rejected by R2 itself and both references confirm: for a mobile offline-first app, full HATEOAS hypermedia (`_links: { href, method }`) creates type-safety destruction and offline breakage. The HATEOAS references confirm this is the pattern for server-driven web clients, not for typed mobile SDKs against a SQLite-first architecture.

**HATEOAS Reference Analysis:**
- API7.ai ref: "Increased Payload Size" + "Client Development Complexity" are the top two challenges. For 500 entity lists, embedding full `_links` per item causes payload explosion on edge networks. Confirmed reject for mobile.
- APIscene ref: "If the cat is not adopted, the API suggests an adoption link" — this is the conceptual model we want. But the implementation does NOT need full `href/method` tuples. Simple `allowedActions: ["edit", "delete"]` string arrays achieve the same DISCOVERABILITY goal without destroying type-safety in Dart/C#.

**The Pragmatic Realization:**
HATEOAS's core VALUE for Checkly is not the full hypermedia format (`_links` with `href/method`) — it is the principle of **server-side calculation of available actions based on entity state**. We adopt the PRINCIPLE, not the full SPEC. The pattern becomes: `DTO.AllowedActions = server calculates based on (user claims + entity state)`.

**Offline conflict resolution:**
- Full HATEOAS = broken offline (buttons disappear).
- Hybrid HATEOAS-lite = manageable offline: Flutter uses `allowedActions` from cached DTO. Server PBAC still acts as the final guard. If cached data is stale and user tries an action they lost (e.g., Admin revoked permissions while offline), the API returns 403. The UI then shows an error. This is acceptable UX — the button stays visible offline based on cached state, but the API rejects if stale. This is the SAME behavior that exists today with `PermissionGuard` reading a cached JWT.

**Decisive conclusion**: R2's Option A (Hybrid Entity-Driven UI) solves the [ORIGIN_IDEA] more completely than R1's "standardize PermissionGuard" recommendation. But R2's Option A must be SCOPED to volatile entities only (Campaigns, Submissions) — NOT a full BaseDto sweep.

</latent_space_scratchpad>

---

## Normalized Option Summary

### Option 1 — R1: Standardize PermissionGuard (PBAC01)
**Source**: `research_20260514_203600_PBAC01_capability_ui.md`
**Hypothesis**: The current `PermissionGuard` + `PolicyManager` pattern is correct. The problem is inconsistent usage. Standardize the UX rules: *hide* structural elements (tabs, pages); *disable* with tooltip for inline actions.
**Architecture change**: Minimal. Zero new backend code. Zero new DTOs.
**Blast radius**: 🟢 Low. Only Flutter UI changes.
**Solves [ORIGIN_IDEA]**: ❌ Partial. Fixes the visual inconsistency but does NOT fix DB↔Logic↔UI drift when entity state changes.

---

### Option 2 — R2 Option A: Hybrid Entity-Driven UI (ARCH)
**Source**: `research_20260514_203551_ARCH_capability_driven_ui.md`
**Hypothesis**: Keep global PBAC (JWT claims) for routing. Add `List<string> AllowedActions` to volatile entity DTOs (Campaigns, Submissions). Flutter `ActionGuard` widget reads from model, not from global `AppCapabilities` enum.
**Architecture change**: Medium. New DTO field on 2-3 entities. New mapping logic in C# services. New `ActionGuard` widget in Flutter.
**Blast radius**: 🟡 Medium. Touches DTOs, mappers, Flutter models, Drift tables (cache decision required).
**Solves [ORIGIN_IDEA]**: ✅ Yes. DB (entity state) → Logic (server calculates AllowedActions) → UI (ActionGuard renders from DTO). All 3 layers are consistent.

---

### Option 3 — R2 Option B: Full BaseDto Sweep (ARCH)
**Source**: `research_20260514_203551_ARCH_capability_driven_ui.md`
**Hypothesis**: Apply `AllowedActions` to ALL entity DTOs via a shared `BaseDto` in C#.
**Architecture change**: High. Dozens of DTOs, mappers, Flutter models.
**Blast radius**: 🔴 High. Touches all server entities and all Flutter models.
**Solves [ORIGIN_IDEA]**: ✅ Over-solves it. Too much risk for entities that have no volatile permission behavior.

---

### Option 4 — True HATEOAS (Both R1/R2 rejected)
**Hypothesis**: Backend sends full hypermedia links `{ "rel": "edit", "href": "/api/programs/1", "method": "PUT" }`. Flutter generates UI dynamically from `_links`.
**Architecture change**: Extreme. Destroys Dart type-safety. Destroys offline support.
**Blast radius**: 🔴 Critical. Violates offline-first mandate.
**Solves [ORIGIN_IDEA]**: ❌ No. Breaks the app for offline users.

---

## Red Team — Hostile Interrogation

### Attack on Option 1 (Standardize PermissionGuard)
**Catastrophic scenario**: An Area Manager is mid-campaign-execution on a bad network. At 9:00 AM, an Admin removes the `campaigns:execute` capability from the Area Manager role in the DB (perhaps due to policy change). The Area Manager's JWT doesn't expire for another 8 hours. The `PermissionGuard` reads the cached JWT, still sees `campaigns:execute`, and shows the "Execute Audit" button. The Area Manager submits the audit. The server accepts it (token is still valid). The business now has an unauthorized submission in the database.

**This is not a UX problem. This is a data integrity problem.** Option 1 does NOT fix this because it never checks entity-level state. The server-side `[RequirePermission]` guards against unauthorized access at the endpoint level but cannot account for "this specific entity was locked after the user cached their JWT."

**Verdict**: Option 1 is insufficient for the [ORIGIN_IDEA]. It solves the visual consistency problem but not the DB-Logic-UI synchronization problem.

---

### Attack on Option 2 (Hybrid Entity-Driven UI)
**Catastrophic scenario**: `GET /api/campaigns?page=1&size=50` returns 50 campaigns. The server must now calculate `AllowedActions` for each of the 50 campaigns. The mapping logic calls `PolicyManager.CanUserAct(user, campaign)` — this requires checking the user's claims PLUS the campaign's current `Status` field. If this query hits a sub-query per entity (N+1), 50 campaigns = 50 extra DB queries per list load. On edge networks with a slow DB, this causes `GET /campaigns` to time out.

**Mitigation available**: The AllowedActions calculation MUST be done in the SQL projection layer (EF Core `.Select()` with a compiled, set-based calculation), not in a loop in the service layer. To prevent EF Core from throwing a runtime translation exception, the backend developer MUST evaluate the user's global claims in-memory *before* the query (e.g., `bool hasExecute = user.HasClaim(...)`), and pass those simple booleans into the `.Select()` ternary operators. This guarantees 100% translation to SQL and prevents N+1 degradation.

**Secondary attack**: If `AllowedActions` is cached in Drift SQLite offline, the Drift schema must also store this field. This means the Drift migration adds a column. Every future `AllowedActions` update (from a sync) must invalidate and re-cache the entity. If the sync engine does not propagate `AllowedActions` correctly, the offline UI shows incorrect buttons.

**Mitigation**: `AllowedActions` must NOT be cached in Drift. It is a transient computed field. When offline, Drift returns null for `allowedActions`. The `ActionGuard` widget MUST accept a `fallbackCapability: AppCapabilities.campaignsExecute` parameter. If `actions` is missing (offline), it falls back to checking the user's cached JWT role (exactly like the old `PermissionGuard`). This perfectly preserves the offline-first mandate without altering the DB schema.

**Verdict**: Option 2 is viable with two mandatory constraints: (a) AllowedActions computed in DB projection, not in a service loop; (b) AllowedActions is NOT persisted to Drift, instead using a `fallbackCapability` in the UI when offline.

---

### Attack on Option 3 (Full BaseDto Sweep)
**Catastrophic scenario**: A developer adds `AllowedActions` to `TemplateDto`. The mapping logic must calculate `AllowedActions` for Templates. But Templates have no volatile permission logic — permissions are always static (you either have `templates:edit` or you don't). The developer now writes dead-code mapping logic for every Template returned. Every API test now needs to assert `AllowedActions`. The codebase grows by thousands of lines of mapping code that adds no business value. Six months later, a different developer doesn't know why Templates have `AllowedActions` and deletes it — breaking the Flutter UI silently.

**Verdict**: Option 3 is rejected. It creates maintenance debt without proportional value.

---

## Pugh Decision Matrix

**Baseline**: Option 1 (Standardize PermissionGuard) = `0`
**Competing**: Option 2 (Hybrid Entity-Driven UI) = scored relative to baseline.
**Option 3** (Full BaseDto) and **Option 4** (True HATEOAS) are pre-rejected and shown for record.

| Non-Functional Requirement | Weight | Option 1 (Baseline) | Option 2 (Hybrid) | Option 3 (Full BaseDto) | Option 4 (HATEOAS) |
|---|:---:|:---:|:---:|:---:|:---:|
| **[ORIGIN_IDEA] Alignment** — Solves DB↔Logic↔UI consistency | **3x** | `0` | `+1` | `+1` | `-1` |
| **Offline-First Compliance** — App works with no connection | **2x** | `0` | `0` | `0` | `-1` |
| **Entity State Accuracy** — UI reflects entity-level permission, not just role | **2x** | `-1` | `+1` | `+1` | `+1` |
| **Blast Radius** — How many files/layers are touched | **1x** | `0` | `-1` | `-1` | `-1` |
| **N+1 DB Risk** — Risk of per-entity DB sub-queries on list endpoints | **2x** | `0` | `-1` | `-1` | `0` |
| **Developer Cognitive Load** — Two paradigms to remember? | **1x** | `0` | `-1` | `-1` | `-1` |
| **Type Safety** — Dart/C# strong typing preserved | **2x** | `0` | `0` | `0` | `-1` |
| **Maintenance Cost (Long Term)** — Is dead mapping code introduced? | **1x** | `0` | `0` | `-1` | `-1` |

### Weighted Scores

| Option | Calculation | **Total** |
|---|---|:---:|
| Option 1 (Baseline) | `0` | **0** |
| **Option 2 (Hybrid)** | `3(+1) + 2(0) + 2(+1) + 1(-1) + 2(-1) + 1(-1) + 2(0) + 1(0)` | **+2** |
| Option 3 (Full BaseDto) | `3(+1) + 2(0) + 2(+1) + 1(-1) + 2(-1) + 1(-1) + 2(0) + 1(-1)` | **+1** |
| Option 4 (HATEOAS) | `3(-1) + 2(-1) + 2(+1) + 1(-1) + 2(0) + 1(-1) + 2(-1) + 1(-1)` | **-9** |

**🏆 Mathematical Winner: Option 2 — Hybrid Entity-Driven UI (`+2` vs Baseline)**

---

## Final Verdict

> **Decision: Option 2 — Hybrid Entity-Driven UI (HATEOAS-lite Principle)**
>
> Keep global PBAC (JWT claims via `PermissionGuard`) for page/tab/route-level gating.
> Add `List<string> AllowedActions` to **volatile entity DTOs only** (Campaigns, Submissions).
> The server calculates this array from `(user claims + entity state)` in the DTO projection layer.
> Flutter uses a new `ActionGuard` widget that reads `model.allowedActions` instead of `AppCapabilities.*` for these volatile entities.
> `AllowedActions` is a **transient field** — never persisted to Drift SQLite.

### Mandatory Implementation Constraints
1. **No N+1 & No Translation Exceptions**: `AllowedActions` MUST be calculated inside the EF Core `.Select()` projection. PROHIBITED: Calculating in a `foreach` loop in the service layer. Claims must be evaluated to booleans *before* the LINQ query to ensure EF Core can translate the logic to SQL.
2. **No Drift persistence**: `AllowedActions` is ephemeral. It is NOT added to any Drift table. Offline fallback: The `ActionGuard` MUST accept a `fallbackCapability` string to check the cached JWT when the entity's `allowedActions` list is null.
3. **Scope lock**: Apply ONLY to Campaigns and Submissions initially. Do NOT expand to Templates, Programs, or any entity with static permissions.
4. **Enum-typed keys**: The action strings (`"edit"`, `"execute"`, `"delete"`) MUST be defined as `static const` strings in a shared `CampaignActions` class (Dart) and a C# `CampaignActions` static class. No magic strings.
5. **Dual-paradigm is temporary**: Over time, `PermissionGuard` with global capabilities handles tabs/pages. `ActionGuard` with entity actions handles inline buttons. This IS two paradigms. This is acceptable trade-off for the scoped rollout, but MUST be documented in `GEMINI.md`.

---

## Executive Business Summary (For Product Owner)

**What this means in real life:**

Right now, when an Area Manager opens a Campaign, the "Execute Audit" button is shown based on their role in general. The system does not know if *this specific campaign* has been locked, completed, or had its permissions revoked recently. This can cause confusion (button shows, but API rejects with a cryptic error), or worse — unauthorized submissions.

**With this change:**
- The server will send a small extra field alongside each Campaign: a list of what actions this user can do **on this campaign right now** (e.g., `["view", "execute"]` or `["view"]` if locked).
- The Flutter app will show or hide the action buttons based on this server-calculated list, not a generic role check.
- This means: if a Campaign is in "Completed" state, even a user with full permissions will correctly see no "Execute" button — because the server says so.
- **Offline behavior**: If the user is offline, the app dynamically falls back to checking their general role (like it does today). This gives us the absolute best of both worlds: precise control when online, and seamless fallback when offline.

**Business benefits**: Fewer phantom 403 errors in the UI. Cleaner UX. Compliance with PBAC rules enforced at the entity level, not just the role level.

**Operational tradeoffs**: Medium implementation effort. Backend engineers must write projection logic carefully to avoid performance issues on list endpoints.

**Maintenance cost**: Low — scoped to 2 entity types. If done correctly with enum-typed action keys, the pattern is self-documenting.

---

## Handoff Block

### Final Verdict
**Option 2 — Hybrid Entity-Driven UI (HATEOAS-lite)** wins with `+2` vs Baseline.
Concretely: Add `List<string> AllowedActions` to `CampaignResponseDto` and `SubmissionResponseDto`. Compute in EF Core projection. New `ActionGuard` Flutter widget reads from the DTO model.

### Strict Constraints (Next Agent MUST NOT Ignore)
- 🔴 **NO N+1**: AllowedActions must be a computed expression inside the EF `.Select()` — not a service-layer loop. Evaluate claims to booleans *before* the query to prevent EF Core translation errors.
- 🔴 **NO Drift persistence**: AllowedActions is transient. Implement `fallbackCapability` in `ActionGuard` to handle offline modes cleanly.
- 🟡 **Scope lock**: Campaign + Submission only. Zero scope creep to other entity types.
- 🟡 **Magic strings banned**: Action keys must be `static const` in both C# and Dart.
- 🟡 **PermissionGuard preserved**: Do NOT delete or deprecate `PermissionGuard`. It remains valid for page/tab gating.

### Execution Slices
| Slice | Scope | Track |
|---|---|---|
| **Slice 1** | Add `AllowedActions` to `CampaignResponseDto`. Write EF projection logic. Backend only. | B (Medium) |
| **Slice 2** | Create `ActionGuard` widget in Flutter. Wire to `CampaignModel.allowedActions`. | B (Medium) |
| **Slice 3** | Repeat for `SubmissionResponseDto` + Submission detail page. | B (Medium) |

### Requirements Alignment Check
> [!IMPORTANT]
> This decision MODIFIES the entity interaction model. If there is a `requirements.md` for Campaigns or Submissions, those documents must be updated to reflect that button visibility is now controlled by `model.allowedActions` (server-computed) rather than by static `PermissionGuard(capability: AppCapabilities.xxx)` checks.

### AI Agent Mission Brief
Implement `List<string> AllowedActions` on `CampaignResponseDto` and `SubmissionResponseDto`, computed in EF Core projection based on user claims and entity state. Create a Flutter `ActionGuard` widget that reads from the DTO's `allowedActions` list. Do NOT persist to Drift. Do NOT touch other entity types.

### Next Workflow Command
```
/implement C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260514_205137_SYN01_capability_driven_ui.md
```
