<latent_space_scratchpad>
KEY ARCHITECTURAL DISCOVERY:
- `/plans` shell tab → `ActionPlansPage` (action plans, NOT campaigns)
- `/programs` → `ProgramListPage` (the campaign list — full page, already has FAB)
- The UX eval said "move to PLANS tab" — but `PLANS` = action plans. 
- Correct interpretation: remove from HOME, add a quick-link entry point within the PLANS tab 
  or make `/programs` accessible as a prominent card INSIDE `ActionPlansPage`.
- OR: simpler — the PLANS tab is the correct semantic home (plans = programmes = campaigns). 
  The fix should be: rename/augment the PLANS tab to also surface the Campaigns entry point.
- SIMPLEST SAFE FIX: 
  1. Delete `AdminActiveCampaignsWidget` from `admin_dashboard_variant.dart` (lines 10 + 68-69)
  2. Inside `ActionPlansPage` (PLANS tab), add a "Campaigns" section that links to `/programs`.
     This is pure UI — no data fetching needed, just a navigation card.
  3. `admin_dashboard_variant.dart` stays clean — just metrics + submission feed.

OUT OF SCOPE:
- `manager_dashboard_variant.dart`'s `CampaignProgressWidget` — that is Area Manager specific context, 
  it is NOT the same widget. Do NOT touch.
- `ProgramListPage` itself — it is correct, no changes needed.
- Backend changes — zero.
- Tests for `ActionPlansPage` — only if we add logic (we won't; it's a navigation card).
</latent_space_scratchpad>

# Implementation Plan: Homepage Campaign Relocation

**Plan ID**: `ab12cd34`
**Generated**: 2026-05-21T17:22:00+0700
**Track**: A (Route 1 — Direct Build, UI-Only)

## Input Lineage
- **Source Input**: `c:\Users\HP\.gemini\antigravity\brain\e9416519-66e9-4247-9c80-313989293476\ux_heuristic_eval_homepage.md`

> [!WARNING]
> **Critical Architectural Finding (Pre-read Before Building)**
> The shell tab labeled `PLANS` routes to `ActionPlansPage` — which is **action plans**, not campaigns.
> The campaign list lives at `/programs` (a detail route, not a shell tab).
> The Builder MUST NOT route the new Campaigns card to `/plans`. It must use `context.push('/programs')`.

---

## Executive Summary & Out of Scope

**What we build**: Remove the `AdminActiveCampaignsWidget` block (including the `+ NEW CAMPAIGN` button) from the Admin Dashboard variant on the Homepage. Add a lightweight "Campaigns" navigation card inside the `PLANS` tab (`ActionPlansPage`) so the Admin can still reach campaigns in one tap.

**Why this solves the problem**: The Homepage becomes a pure dashboard (metrics + recent activity). The `PLANS` tab becomes the unified entry point for all planning workflows.

**Out of Scope**:
- `manager_dashboard_variant.dart` and its `CampaignProgressWidget` — that is Area Manager-specific. Do NOT touch.
- `ProgramListPage` itself — already correct with its own FAB.
- Any backend changes — zero.
- Any database migrations — zero.
- Renaming the `PLANS` shell tab label — the user did not request this.

---

## System Context
- **Connectivity**: Online-only feature. `AdminActiveCampaignsWidget` fetches from live API; removing it removes that fetch call from Home.
- **PBAC Gate**: The `+ NEW CAMPAIGN` button is gated by `AppCapabilities.programsCreate`. The new navigation card in PLANS must apply the same `PermissionGuard` wrapper for the creation shortcut, but the "View Campaigns" card is always visible to Admins.
- **RBAC Scope**: Admin role only. `manager_dashboard_variant.dart` is NOT in scope.

---

## Lifecycle Context (4-State Matrix)

### After the change — `ActionPlansPage` (PLANS tab):
| State | Behavior |
|-------|----------|
| **Success** | Action Plans list renders normally. A new "Campaigns" navigation card appears at the top or bottom. |
| **Empty** | No action plans found. The "Campaigns" card still renders (it is static). |
| **Error** | Action plans fail to load. Error banner shown. "Campaigns" card is unaffected (it is static — no fetch). |
| **Loading** | Loading spinner for plans. "Campaigns" card is unaffected (renders immediately). |

---

## Constraint Traceability

| Constraint (from UX eval) | Covered By | Test ID |
|---|---|---|
| H8: Duplicated primary actions (`+ NEW CAMPAIGN` + FAB on same screen) | Delete `AdminActiveCampaignsWidget` from dashboard. FAB in `ProgramListPage` becomes the sole CTA. | TC-01 |
| H4: Fractured workflow — Campaigns on HOME, not PLANS tab | Add Campaigns nav card in `ActionPlansPage` | TC-02 |
| H8: Homepage clutter — too many sections | Delete the entire `AdminActiveCampaignsWidget` section | TC-01 |

---

## Test Contracts

| ID | Description | Pass Condition | Fails If |
|---|---|---|---|
| TC-01 | Homepage (Admin) no longer shows "Active Campaigns" section or `+ NEW CAMPAIGN` button | Neither the `AdminActiveCampaignsWidget` nor the `FilledButton.icon` for "NEW CAMPAIGN" exists in the widget tree | Widget still renders on scroll |
| TC-02 | PLANS tab shows a "Campaigns" entry point | Tapping the card navigates to `/programs` (ProgramListPage) | Card missing OR routes to wrong path |
| TC-03 | The `+ New Campaign` FAB in `ProgramListPage` is still PBAC-gated | Only visible to users with `programsCreate` capability | FAB visible without capability |
| TC-04 | `CampaignProgressWidget` in `manager_dashboard_variant.dart` is NOT changed | Area Manager dashboard renders identically before and after | Widget removed or modified |

---

## Test Fixture & Payloads
- **Required Fixture State**: Logged-in Admin user with `programsCreate` capability.
- **Test Method**: Manual hot-reload on emulator. Screenshot before and after.
- No HTTP payloads (pure UI change — no API endpoints added or removed).

---

## Tools & Commands
- **Skills**: None required (pure UI).
- **Test Command**: `rtk flutter test lib/features/dashboard/` and `rtk flutter test lib/features/action_plans/`
- **Manual Check**: Hot-reload emulator, navigate HOME → confirm Campaigns section gone. Navigate PLANS → confirm card present and tappable.

---

## Proposed Changes

| Action | File | Reason |
|---|---|---|
| `[MOD]` | `lib/features/dashboard/pages/widgets/admin_dashboard_variant.dart` | Delete `AdminActiveCampaignsWidget` import (line 10) and its widget call (lines 68-69) |
| `[MOD]` | `lib/features/action_plans/pages/action_plans_page.dart` | Add a static "Campaigns" navigation card linking to `/programs` |
| `[DEL]` | `lib/features/dashboard/pages/widgets/admin_active_campaigns_widget.dart` | Dead code after removal — delete the file entirely |

**Component Routing Table:**
| Component | Route | Truncation Limit | Overflow Action |
|---|---|---|---|
| Campaigns nav card (new) | `context.push('/programs')` | Title: 1 line | `TextOverflow.ellipsis` |
| "New Campaign" shortcut (optional, PBAC-gated) | `context.push('/programs/new')` | N/A (icon button) | N/A |

---

## Concept Diagram

```
BEFORE:
[HOME tab]
  ├── KPI Metrics
  ├── Active Campaigns section  ← PROBLEM (3 API-fetched cards + big button)
  └── Recent Activity feed

[PLANS tab]
  └── Action Plans list only

AFTER:
[HOME tab]
  ├── KPI Metrics
  └── Recent Activity feed        ← CLEAN

[PLANS tab]
  ├── Campaigns nav card  ← NEW (static, no fetch, routes to /programs)
  └── Action Plans list

[/programs route]  (unchanged)
  └── ProgramListPage (full campaign list + FAB for New Campaign)
```

---

## Execution Slices

### Execution Phase: Remove & Relocate Campaign Entry Point

- **Plain English Summary**: Delete the "Active Campaigns" widget block from the Admin's homepage. Add a single, clean navigation card to the PLANS tab that takes the Admin to the full campaign list.
- **Why this step now?**: This is the entire feature — it is a simple deletion and one addition. There is no dependency ordering needed.
- **Scenario Focus**: Basic Scenario (Happy Path).
- **Value Delivered**: Admin's homepage is a clean dashboard. Tapping PLANS → seeing Campaigns is intuitive and consistent.
- **Entry State Required**: `admin_dashboard_variant.dart` and `admin_active_campaigns_widget.dart` exist unchanged. `ActionPlansPage` exists and renders correctly.
- **Exit State Guaranteed**: Homepage renders with zero campaign references. PLANS tab shows a Campaigns card. `admin_active_campaigns_widget.dart` is deleted (not just unused).
- **Architectural Scope**:
  - `admin_dashboard_variant.dart` — remove 2 lines (import + widget call)
  - `admin_active_campaigns_widget.dart` — delete file
  - `action_plans_page.dart` — add 1 static navigation card widget
- **Complexity**: **Low** — 3 files, pure widget tree edits, no state or logic changes.
- **Acceptance Criteria**:
  - TC-01: No "Active Campaigns" on Admin HOME tab
  - TC-02: "Campaigns" card on PLANS tab navigates to `/programs`
  - TC-03: `ProgramListPage` FAB still PBAC-gated (unchanged, just verify)
  - TC-04: Area Manager dashboard unaffected

---

<command_logs>
- grep_search: "campaign" in lib/ → found AdminActiveCampaignsWidget in admin_dashboard_variant.dart (line 68)
- view_file: admin_dashboard_variant.dart → confirmed import line 10, widget at line 68
- view_file: admin_active_campaigns_widget.dart → 243 lines, fully self-contained StatefulWidget
- view_file: shell_tab.dart → PLANS tab routes to '/plans', not '/programs'
- view_file: app_router.dart:74 → '/plans' → ActionPlansPage (NOT ProgramListPage)
- view_file: app_router.dart:180 → '/programs' → ProgramListPage (correct target for campaigns)
- view_file: program_list_page.dart → already has FAB gated by programsCreate
- view_file: manager_dashboard_variant.dart → CampaignProgressWidget is Area Manager only
</command_logs>

---

## Handoff Block

**Summary for Builder**: Delete the `AdminActiveCampaignsWidget` from the Admin homepage. This widget is fully self-contained in `admin_active_campaigns_widget.dart` — delete that file entirely after removing its import and call from `admin_dashboard_variant.dart`. Then add a static "Campaigns" navigation card to `ActionPlansPage` (the PLANS tab) that calls `context.push('/programs')`. Do NOT route to `/plans` — that is the wrong page. Do NOT touch `manager_dashboard_variant.dart`.

**Execution Sequence (ONE AT A TIME)**:
- **Execution Phase**: Plan → **Build** (Route 1 — Direct Build, no tests required before coding; verify manually after)

**Absolute Plan Path**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\homepage_campaign_relocation\implementation_plan_20260521_172200_ab12cd34_homepage_campaign_relocation.md`
