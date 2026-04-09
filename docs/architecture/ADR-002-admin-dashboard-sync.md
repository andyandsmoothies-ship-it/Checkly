# ADR: Admin Dashboard — PBAC Phase 2 Sync Architecture
> **Thunderdome Synthesis** — `/synthesize` workflow
> Source A: `1199fa41` — Scout 1 (25,221 bytes, deep forensic audit)
> Source B: `af86409e` — Scout 2 (8,377 bytes, lean tactical analysis)
> **Revision 2:** Corrected Free Read-Cache Fallacy.

---

<latent_space_scratchpad>

## INTERNAL THUNDERDOME DEBATE (REVISED)

### The "Free Read-Cache" Fallacy Exposed
Initially, Option C (Hybrid Offline-Read / Online-Write) was declared the winner based on the premise that `CachedPolicies` already provided the local role data.

A forensic audit of `tables.dart` proved this false. `CachedPolicies` is a single-column table holding only the *logged-in user's* current permissions. It does NOT contain the global catalog of roles or what capabilities map to them. 
To build Option C, we would have to build three new Drift tables (`CachedRoleDefinitions`, `CachedCapabilityCatalog`, `CachedRoleAssignments`), plus their sync DAOs and Orchestrator logic. Option C's effort is identical to Option B's nightmare.

### The "Self-Demotion Ghost State"
Option C creates a catastrophic UX edge case. If Admin A opens the app offline, they see the Dashboard based on stale local cache. If Admin B demoted Admin A 5 minutes prior on the server, Admin A still thinks they are an Admin. When they go online and tap "Save", the server returns a harsh `403 Forbidden`.
Option A prevents this entirely: The UI forces a network fetch *before* rendering the dashboard. If they were demoted, the dashboard simply refuses to open.

**Thunderdome Pivot Verdict: Option A (Strict Online-Only) is the only structurally sound choice.**

</latent_space_scratchpad>

---

## 1. Normalized Options

| # | Scout | Core Hypothesis | Verdict |
|---|-------|-----------------|---------|
| **Option A** | Scout 1 | Online-Only. Simplest. No offline admin. | ✅ **Winner (The Final Pivot)** |
| **Option B** | Both | Offline mutations via outbox. | ☠️ **DEAD** (Split-brain risk) |
| **Option C** | Scout 2 | Online-Write + Offline-Read (Browse offline). | ☠️ **DEAD** (Ghost state UX + Schema bloat) |

---

## 2. Hostile Interrogation

> **@@SCAN Phase 2**: (1) Attack invented for EVERY option? YES. (2) No appeasement? YES.

### Attack 1 — Option A: The "Phantom Permission" UX Disaster
**Scenario:** Admin opens Role Management on a bad 3G signal. The spinner loops for 15 seconds. 
**Severity:** MEDIUM. 
**Mitigation:** Enforce strict Dio timeouts (e.g., 5 seconds) and show a clear "Requires Stable Internet Connection" empty state, rather than an infinite spinner. 

### Attack 2 — Option B: The Silent Security Regression
**Scenario:** Admin A revokes a permission offline. Admin B grants it online. Admin A syncs later. Last-write-wins silently destroys Admin B's intent without notifying either party.
**Severity:** CRITICAL. Impossible to mitigate without building a massive CRDT system for role mapping.

### Attack 3 — Option C: The "Self-Demotion" Ghost State
**Scenario:** Admin opens the Dashboard offline. They don't realize they were "fired" (demoted to Auditor) 10 minutes ago by the CEO. The stale cache shows them the Admin UI. They try to edit permissions, reconnecting to the network, and are met with a hostile `403 Forbidden` error because their actual token lacks privileges.
**Severity:** HIGH UX DAMAGE. Option A mitigates this by refusing to show the dashboard at all without a live server handshake.

---

## 3. Pugh Decision Matrix (Corrected)

> Baseline = Option A (`0`). Better = `+1`. Worse = `-1`.

| Dispatch NFR | Option A (Baseline) | Option B (Offline-First) | Option C (Hybrid) |
|---|:---:|:---:|:---:|
| **Security Integrity** | 0 | -1 ❌ (Silent overwrites) | 0 |
| **Concurrency Safety** | 0 | -1 ❌ (Multi-admin collision) | 0 |
| **Implementation Effort** | 0 | -1 ❌ (Outbox, CRDTs) | -1 ❌ (3 new Drift tables needed) |
| **UX Honesty** | 0 | +1 (Instant perception) | -1 ❌ (Ghost state risk) |
| **Blast Radius** | 0 | -1 ❌ (Modifies SyncEngine) | -1 ❌ (Modifies SyncEngine pulls) |
| **TOTAL** | **0** | **-3** | **-3** |

> **@@SCAN Phase 3**: Matrix tabulated ✅. Option A wins mathematically.

---

## 4. Final Verdict

**Winner: Option A — Strict Online-Only (Pessimistic)**

Building offline read-caching for global administrative security models adds schema migration risk, SyncEngine bloating, and UX friction (stale data) for an admin feature that is almost never used offline.

### The Master Dispatch Map for Phase 2

| Slice | Name | Scope | Route |
|:---:|---|---|---|
| **Slice 1** | **Backend Roles API** | C# Only. 3 new endpoints: `GET /roles`, `PUT /roles/{role}/capabilities` (full-replace), `GET /capabilities/catalog`. All gated by `admin:manage_roles` capability. | `/analyze-feature` → `/implement` |
| **Slice 2** | **Flutter Admin Dashboard UI** | Flutter Only. `RoleManager` (Dio-only, ValueNotifier — NO Drift). `RoleListPage`, `RoleDetailPage`. Full-page "Admin Dashboard Requires Internet Connectivity" empty state when offline. | `/analyze-feature` → `/implement` |

---

## 5. Mandatory Implementation Guards

These non-negotiable guards MUST be injected into the Feature Analysis brief for each slice:

| Guard | Mandate |
|-------|---------|
| **Full-Replace Semantics** | `PUT /roles/{role}/capabilities` sends the entire desired set, not a delta. Server does DELETE-then-INSERT inside one transaction. |
| **Capability Catalog Endpoint** | `GET /admin/capabilities/catalog` must exist before the Flutter UI is built, so the checkbox grid has a verified source of truth. |
| **Zero Drift Bias** | The Flutter implementation MUST NOT add any new tables to `tables.dart`. `RoleManager` stores state purely in RAM (`ValueNotifier`). |
| **Strict Online-Only UX** | If `ConnectivityService.isOffline`, the Role lists do not render. An empty state blocks entry. |

---

## 6. Handoff Block

| Field | Value |
|-------|-------|
| **Verdict** | Option A (Strict Online-Only). 2-Slice Master Dispatch generated. |
| **Option C Status** | ☠️ Rejected due to Drift schema bloat and Ghost State UX flaws. |
| **Next Immediate Action** | Dispatch a Scout to `/analyze-feature` for **Slice 1 (Backend Roles API)**. |
| **Persistent Path** | `.agents/tmp/research/decision_record_admin_dashboard_sync.md` |
