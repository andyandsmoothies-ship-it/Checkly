# ADR: UI PBAC Capability Mapping — Thunderdome Decision

**Date:** 2026-05-10T17:34:20+07:00
**Author:** Scout (AI Architect)
**Workflow:** /synthesize (Thunderdome)
**Status:** DECIDED

---

## [ORIGIN_IDEA]

> The backend's 403 enforcement creates bad UX when a user clicks an unauthorized button. The UI must proactively read PBAC capabilities from `AuthManager` and hide/disable controls *before* an API call is ever made. The UI must be "capability-aware" and "dumb" — it reads, it does not compute permissions.

---

## Input Lineage

| Artifact | Path |
|---|---|
| R1 | `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260510_173000_r1_uicaps.md` |
| R2 | `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260510_172009_uicaps_ui-capability-mapping.md` |

---

## Architecture Diagram (ASCII)

```
[Backend PBAC Engine]
       |
       v  GET /api/system/capabilities
[PolicyApiService]
       |
       v  Upsert
[Drift SQLite Cache]
       |
       v  Cold Boot Load / Live Notify
[AuthManager.capabilities (ValueNotifier)]
       |
       v  ValueListenableBuilder
[PermissionGuard (per widget)]
       |
     [Yes]           [No]
       |               |
  [Render Widget]  [Empty Widget / hidden]
```

---

<latent_space_scratchpad>

## Internal Debate

**Q: Are R1 and R2 actually competing? Or are they the same solution?**

A: They are the same *strategy* (Option A — Strict Native Fit) but differ significantly in *scope and depth*:
- R1 is a strategic research note. It identifies the problem, maps the E2E flow, and recommends Option A with 3 identified blind spots (CLS, offline staleness, UX discoverability).
- R2 is a tactical execution brief. It includes a concrete UI Capability Map (which screen needs which capability), a Mermaid sequence diagram, and a specific call-out on the `ValueListenableBuilder` rebuild concern.

This is NOT a conflict — it is a complement. R2's Capability Map is the concrete implementation blueprint R1 was missing. The synthesis winner must absorb both artifacts.

**Q: Should we "hide" or "disable" buttons?**

R1 raises the "Discoverability vs Security" tradeoff explicitly. R2 is silent on this.
- Hide (empty widget): Cleaner. No confusion about why a button exists if you can't use it. Matches what `PermissionGuard` does by default.
- Disable with tooltip: Better discoverability — user knows the feature exists but needs permission. More code (state management for disabled state + tooltip text).

Decision: **Default to HIDE.** The `PermissionGuard` already implements hide-by-default. A future UX iteration can add disabled-with-tooltip for specific high-discoverability scenarios (e.g., the "Create Program" FAB for auditors who can see programs but not create them). Do not pre-optimize.

**Q: Is the ValueListenableBuilder rebuild overhead a real concern?**

R2 raises it. Verdict: No. `PermissionGuard` uses `ValueListenableBuilder`, which only rebuilds the wrapped subtree when `capabilities` changes. Capabilities only change on login, logout, or explicit sync — not on every render cycle. This is not a hot path concern.

**Q: What makes the synthesis meaningful (not just "both agree, pick A")?**

The synthesis value is:
1. R1 → R2 forms a complete picture: R1 = WHY + TRADEOFFS, R2 = HOW + MAP.
2. The Capability Map from R2 is the critical missing deliverable from R1. It must be preserved in the Handoff Block below as the canonical list of screens + capabilities.
3. The hide vs. disable decision is resolved here.
4. The "manual discipline" blast radius is named and its mitigation is prescribed.

</latent_space_scratchpad>

---

## Normalized Options

| Option | Strategy | Verdict |
|---|---|---|
| **(A) Strict Native Fit** | Wrap every protected widget in `PermissionGuard` using `AppCapabilities` constants. Route guards via `PolicyManager`. | ✅ **SELECTED** |
| **(B) Role + Capability Split** | Macro role checks for layout, capability checks for micro-actions. | ❌ Eliminated — violates PBAC golden rule, triggers GEMINI.md Gotcha #8 |
| **(C) Server-Driven UI** | Backend returns JSON layout of buttons/menus. | ❌ Eliminated — breaks offline-first architecture |

---

## Red Team Attack Vectors

### Option A — Regression by Convention Gap
> A new developer adds a "Bulk Delete" button to Submissions and forgets `PermissionGuard`. No compiler error. The 403 regression is silent and screen-specific. The architecture is correct; the enforcement is not automatic.
> **Mitigation:** Add a PR convention: any new `ElevatedButton`/`IconButton`/`PopupMenuButton` on a feature screen must link to a `PermissionGuard` or explicitly document why it is public. Static lint can flag unguarded buttons near known action verbs (`onDelete`, `onCreate`). Low cost.

### Option B — Split-Brain Silent Exclusion (GEMINI.md Gotcha #8)
> An `area_manager` role is added. Macro role check at layout level: "Is Admin?" → No → hide Manager section. But `area_manager` has `submissions:execute` capability. The user is silently excluded from a feature they are authorized for. This is the exact documented bug.
> **Mitigation:** None. The architecture is fundamentally misaligned with PBAC. Eliminated.

### Option C — Stale JSON Layout in Offline Mode
> App goes offline. Last cached layout JSON shows "Create Submission" button (cached when user had capability). Admin revokes capability. User clicks button offline. On reconnect, submission queues and hits 403. Identical failure to status quo but with 5× more code.
> **Mitigation:** None acceptable. The offline-first contract cannot be honored with server-driven layout. Eliminated.

---

## Pugh Decision Matrix

**Baseline = Option A (0)**

| NFR / Criterion | Weight | **Option A** | **Option B** | **Option C** |
|---|:---:|:---:|:---:|:---:|
| [ORIGIN_IDEA] Alignment | 3× | `0` | `-1` | `-1` |
| Offline-First Compatibility | 3× | `0` | `-1` | `-1` |
| Blast Radius / Refactor Cost | 2× | `0` | `-1` | `-1` |
| Reuse of Existing Infrastructure | 2× | `0` | `0` | `-1` |
| GEMINI.md Rule Compliance | 2× | `0` | `-1` | `0` |
| Performance (Render Overhead) | 1× | `0` | `+1` | `0` |
| Developer Ergonomics (new features) | 1× | `-1` | `0` | `-1` |
| Capability Sync Lag Exposure | 1× | `0` | `0` | `0` |
| **Weighted Total** | | **-1** | **-12** | **-11** |

**Winner: Option A — Strict Native Fit** (least negative; only penalty is the manual discipline cost, which is manageable)

---

## Final Verdict

> **Option A — Strict Native Fit (PermissionGuard Wrapping)** is the correct implementation strategy.

- The PBAC infrastructure (`PermissionGuard`, `PolicyManager`, `AuthManager`, `AppCapabilities`) is **already production-ready** in the codebase.
- The implementation gap is **coverage only** — not architecture.
- Options B and C are structurally eliminated by PBAC principles and Checkly's offline-first contract respectively.

---

## Synthesis: What R1 + R2 Together Produce

The two research artifacts are complementary, not competing. The canonical solution absorbs both:

| R1 Contribution | R2 Contribution |
|---|---|
| Strategic WHY (bad 403 UX) | Tactical HOW (per-screen capability map) |
| 3 named blind spots (CLS, offline staleness, UX discoverability) | `ValueListenableBuilder` rebuild concern (dismissed) |
| E2E text flow | Mermaid sequence diagram |
| High-level scope (Submissions, Programs, Admin) | Concrete screen → capability map (Templates, Programs, Submissions, Shell Tabs) |

**The Capability Map from R2 is the canonical implementation target.**

---

## Canonical UI Capability Map (from R2, locked)

```
[Shell / Navigation]
  - Programs tab     → requires: programs:read
  - Templates tab    → requires: templates:read

[Template Management]
  - New Template FAB → requires: templates:create
  - Edit Template    → requires: templates:update
  - Delete Template  → requires: templates:delete

[Program / Assignment]
  - Create Program FAB          → requires: programs:create
  - Assign Auditor dropdown     → filter users: must have submissions:execute

[Audits / Submissions]
  - Start Audit FAB             → requires: submissions:create
  - Submit / Finalize action    → requires: submissions:execute (+ delegate validation)
```

---

## UX Decision: Hide vs. Disable

**Resolved here:** Default to **HIDE** (empty widget) for standard actions. 
However, for **primary screen actions** (like the main "Start Audit" FAB), hiding the button completely can cause user confusion (selective discoverability).

- Update `PermissionGuard` to accept an optional `showAsDisabled: bool` parameter.
- If true, render the child widget in a greyed-out/disabled state that shows a tooltip/snackbar when tapped ("You lack the required capability").
- Use this sparingly; default is always hide.

---

## Executive Business Summary (for Product Owner)

**In plain English, what are we doing?**

Right now, the app shows buttons (e.g., "Create New Audit") to users who don't have permission to use them. When they click those buttons, the server says "No" with an error (403). This is confusing and unprofessional.

We are fixing this by making the app "smart enough" to hide those buttons **before** the user ever clicks them. The app already has all the technical machinery to do this — it just hasn't been applied consistently to every screen.

**What is the business benefit?**
- Users only see what they can do → less confusion, fewer support tickets.
- The app feels more professional and role-appropriate for each user type (Auditor vs. Store Manager vs. Admin).
- No security risk changes: the backend still enforces all permissions. We are adding a UX layer, not replacing the security layer.

**What is the cost?**
- A developer must manually audit each screen and apply the "hide" wrapper to each button.
- New buttons added in the future need the same discipline. This is a low but ongoing maintenance cost.
- No new libraries. No new servers. No new database tables. Pure Flutter code changes.

**Risk:**
- Very low. If a developer forgets to wrap a button, the worst outcome is a user sees a button that then returns an error — the same behavior as today. The backend always wins.

---

## Handoff Block

### Final Verdict
**Option A — Strict Native Fit (PermissionGuard Wrapping)**

### Strict Constraints (Builder must not ignore)
1. **Use `AppCapabilities` constants.** NEVER use raw capability strings.
2. **Prevent Navigation Crashes.** Do NOT wrap individual `NavigationDestination` items. Compute the list of tabs dynamically via a getter based on `AuthManager.capabilities` and clamp the `currentIndex` to `tabs.length - 1`.
3. **Backend-Driven Dropdowns.** The "Assign Auditor" dropdown MUST be filtered by the backend (e.g., `GET /api/users?requireCapability=...`). Do not filter this locally.
4. **Prevent Flash of Unauthorized Content.** `PermissionGuard` must return an empty/loading widget while `AuthManager` is initializing, only revealing the child when state is definitively resolved.
5. **Automated Enforcement.** A Python script (`verify_pbac_ui.py`) MUST be created in `.agents/scripts/` to scan `lib/features/` and fail the build if it finds unguarded `FloatingActionButton` or `ElevatedButton` widgets.
6. **Modify `PermissionGuard`.** You ARE authorized to modify `PermissionGuard` to support `showAsDisabled: true` and handle the initialization loading state.

### Execution Slices
The Builder should implement screen-by-screen in this priority order:

| Slice | Scope | Capability Target |
|---|---|---|
| S0 | Core Infrastructure | Upgrade `PermissionGuard` (disabled state + loading flash fix) & write `verify_pbac_ui.py` |
| S1 | Submissions screen — FABs and actions | `submissions:create`, `submissions:execute` |
| S2 | Templates screen — FABs and actions | `templates:create`, `templates:update`, `templates:delete` |
| S3 | Programs screen — FABs, Assign dropdown | `programs:create`, `submissions:execute` (via backend API filter) |
| S4 | Shell Navigation — Dynamic tab computation | `programs:read`, `templates:read` |

### Requirements Alignment Check
> [!WARNING]
> The existing `requirements.md` (if any) for the PBAC feature may only describe backend permission enforcement. The UI-level capability hiding described here is a **new UX layer**. If a requirements document exists, it should be updated to include the Canonical UI Capability Map above as a formal User Story acceptance criterion.

### AI Agent Mission Brief
Audit the Flutter UI screens (Submissions, Templates, Programs, Shell Navigation) and wrap every protected action button / tab in `PermissionGuard(capability: AppCapabilities.xyz)` using the Canonical UI Capability Map in this ADR. The architecture is already built — coverage is the only gap.

### Next Workflow Command
```
/implement C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\uicaps\decision_record_20260510_173420_15a74aa9_uicaps.md
```
