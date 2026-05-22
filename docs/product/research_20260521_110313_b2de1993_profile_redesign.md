# Research: Profile Page Redesign + Templates Nav Relocation
**ID**: research_20260521_110313_b2de1993_profile_redesign  
**Agent**: Scout (Architect)  
**Date**: 2026-05-21  
**Status**: FINAL — Viable  

---

## [ORIGIN_IDEA]
> The user wants to:
> 1. **Remove TEMPLATES from the bottom navigation bar** (it is currently a 5th tab, gated by `templates:create` capability — visible only to Admin).
> 2. **Move Templates access into the Profile page**, under the correct role section, as a menu tile that navigates to `/templates`.
> 3. **Redesign the Profile page for all roles** — currently it is a flat, generic list. The goal is a premium, role-aware layout that organizes information into clear zones: identity, role-specific actions, workspace tools, settings, and sign out.

---

<latent_space_scratchpad>
## Internal Reasoning

### Problem 1: Where should Templates live?

Templates (`templatesCreate` capability) is a **content management feature**, not a daily operational tool. It belongs in the "workspace management" zone of the Profile page — not in the bottom nav alongside HOME, ACTIVITY, PLANS, INBOX which are daily operational screens.

Who has `templatesCreate`? Looking at `AppCapabilities.adminDomainCapabilities`: `templatesCreate` is an admin-domain capability. In practice, only Admin or specially configured roles will have it. So it's a **power-user tool** that belongs in an admin/management section.

Where exactly on Profile? The existing `_managementItems()` already creates role-specific sections. Templates should be added as a "Workspace Tools" section visible only when the user `caps.contains(AppCapabilities.templatesCreate)`. This is cleaner than hardcoding to persona — it stays PBAC-consistent.

### Problem 2: Router impact of removing Templates from ShellRoute

Current: `/templates` is inside `ShellRoute` (has bottom nav). Removing it from `ShellTab.all` list will cause the tab to disappear from the nav bar (the `all.where()` filter won't exclude it — it will still be rendered if the route is still in the ShellRoute).

Wait — actually the tab visibility is controlled by `ShellTab.all` list in `shell_tab.dart`. The route `/templates` is ALSO inside `ShellRoute` in `app_router.dart`. These are two separate concerns:
1. The TAB appearing in the bottom bar = controlled by `ShellTab.all`
2. The ROUTE `/templates` having a bottom nav scaffold = controlled by being inside ShellRoute

If we just delete the ShellTab entry for TEMPLATES, the tab disappears from the nav, but `/templates` still has a bottom nav (since it's still inside ShellRoute). That's fine — profile page will call `context.push('/templates')` which will render within the shell. The existing tests in `app_router_rbac_test.dart` test `/templates/new` (the write guard) — no test covers the shell tab visibility. We need a new test.

### Problem 3: Profile Page Redesign Architecture

Current layout is 4 dumb sections stacked in a ListView. There is no visual hierarchy signal about which section belongs to what "zone". The user wants premium.

Looking at Material 3 Profile page patterns and what Checkly already has:
- `ProfileHeader` widget exists — small avatar + name + role badge
- `SettingsSectionGroup` — Card with ListTiles
- `ProfileCapabilitiesSection` — ExpansionTile with chips
- `SignOutTile`, `ThemeToggleTile`

Design approach: Divide into 4 named zones with clear visual hierarchy:
1. **IDENTITY ZONE** — Large avatar (not small), full name, role badge, email subtitle. This should feel personal and premium. Consider a colored gradient banner behind the avatar.
2. **MY WORKSPACE** (role-specific) — Role-aware tiles: Admin → Admin Dashboard + Templates; AreaManager → My Region + Templates (if caps); StoreManager → My Store; Auditor → nothing here.
3. **ACTIVITY & NOTIFICATIONS** — My Activity, Notifications (existing tiles)  
4. **SETTINGS** — Theme toggle, Documentation, Help
5. **ACCOUNT** — My Capabilities (collapsed by default), Sign Out, Version

This is the "Layered Card" pattern — each zone is visually separated, with section labels (small caps text above each card group), which is standard Material 3 settings page design.

### Key Insight: Do NOT use `UserPersona` to gate Templates
Use `caps.contains(AppCapabilities.templatesCreate)` directly. This follows the existing PBAC philosophy in `shell_tab.dart` (line 38: `requiredCapability: AppCapabilities.templatesCreate`). If we use persona-based check, we break the PBAC model.

### What files change?
1. `shell_tab.dart` — DELETE the TEMPLATES ShellTab entry
2. `profile_page.dart` — Rewrite layout + add Templates tile (capability-gated)
3. `profile_header.dart` — Expand to a premium identity card (gradient header)
4. `settings_section_group.dart` — Add optional `sectionLabel` parameter
5. No router changes needed (route stays inside ShellRoute — still works fine)
6. New test: shell active index test for Templates tab removal

### Files NOT changing (intentional)
- `app_router.dart` — `/templates` route stays inside ShellRoute (has bottom nav when navigated from profile, which is fine)
- Backend: Zero changes
- All template pages: Zero changes
</latent_space_scratchpad>

---

## Current Codebase Reality

<forensic_evidence>

### Evidence 1: TEMPLATES ShellTab (shell_tab.dart, line 34-39)
```dart
ShellTab(
  icon: Icons.description_outlined,
  label: 'TEMPLATES',
  route: '/templates',
  requiredCapability: AppCapabilities.templatesCreate,  // Only admin-class roles
),
```
This tab is already hidden from Auditors and Store Managers. It only appears for Admin (confirmed by screenshot: Admin sees 6 tabs, Store Manager sees 5).

### Evidence 2: Profile page sections (profile_page.dart, lines 29-101)
- ALL roles share the same flat structure: management section → general section → support section → capabilities → sign out
- Management section logic lives in `_managementItems()` (lines 125-161)
- Templates is NOT mentioned anywhere in profile_page.dart

### Evidence 3: Capability gating mechanism (main_shell.dart, line 170-173)
```dart
final visibleTabs = ShellTab.all.where((tab) {
  return tab.requiredCapability == null ||
      caps.contains(tab.requiredCapability);
}).toList();
```
Removing TEMPLATES from `ShellTab.all` is the clean, single-source-of-truth removal.

### Evidence 4: Router — /templates inside ShellRoute (app_router.dart, line 81-83)
```dart
GoRoute(
  path: '/templates',
  builder: (context, state) => const TemplateListPage(),
),
```
It's inside the ShellRoute block (lines 59-90). So `/templates` still renders WITH the bottom nav even after removing the tab — this is desired behavior (navigating from profile keeps the shell).

### Evidence 5: Existing profile widgets
- `ProfileHeader` — tiny 56px avatar, name, role badge. Needs upgrade to premium.
- `SettingsSectionGroup` — Card with dividers. No section label support.
- `ProfileCapabilitiesSection` — ExpansionTile, collapsed by default. Keep as-is.

### Evidence 6: RBAC test file (app_router_rbac_test.dart, 132 lines)
- Has 6 tests covering `/admin/dashboard` and `/templates` route guards.
- NO test for `shellActiveIndexFromLocation` after removing the TEMPLATES tab.
- A new unit test is needed: "Admin with templatesCreate cap sees 5 tabs (not 6)".

</forensic_evidence>

---

## E2E Workflow Map

```
CURRENT STATE:
[Bottom Nav] → HOME | ACTIVITY | PLANS | TEMPLATES(*) | PROFILE | INBOX
              (*) gated: only visible when caps has 'templates:create'

User taps TEMPLATES → /templates → TemplateListPage (with bottom nav shell)

PROPOSED STATE:
[Bottom Nav] → HOME | ACTIVITY | PLANS | PROFILE | INBOX
              (TEMPLATES tab removed from ShellTab.all)

User taps PROFILE → /profile → ProfilePage (redesigned)
  ↓
  ProfilePage shows "Workspace Tools" section (PBAC-gated: templates:create)
  ↓
  User taps "Templates" tile → context.push('/templates')
  ↓
  /templates still inside ShellRoute → TemplateListPage renders WITH bottom nav
  ↓
  PROFILE tab stays highlighted (location = '/templates', no tab matches → stays at last active)

State Machine for Tab Highlight after move:
  /profile    → PROFILE tab active (correct)
  /templates  → No tab matches → falls back to index 0 (HOME)  ← RISK!

MITIGATION: This is acceptable behavior. The user navigated "into" templates from
profile. The back button returns them to profile. The home tab being highlighted
is a minor cosmetic issue — same behavior as /admin/dashboard today.
Alternative: Add /templates to PROFILE tab's route prefix check. But this
couples routing logic and is overengineering.
```

```
PROFILE PAGE LAYOUT STATE MACHINE (all roles):

ProfilePage
├── [IDENTITY ZONE]        ← Always visible
│   └── ProfileIdentityCard (gradient banner + large avatar + name + role badge + email)
│
├── [MY WORKSPACE]         ← Role-specific, collapsed if no items
│   ├── Admin persona      → Admin Dashboard tile + Templates tile (if templatesCreate cap)
│   ├── AreaManager        → My Region tile + Templates tile (if templatesCreate cap)
│   ├── StoreManager       → My Store tile + Templates tile (if templatesCreate cap)
│   └── Auditor            → (no workspace tiles, section hidden)
│
├── [ACTIVITY]             ← Always visible
│   ├── My Activity tile   → /activity
│   └── Notifications tile → /inbox
│
├── [SETTINGS]             ← Always visible
│   ├── Theme toggle
│   ├── Documentation tile
│   └── Help tile
│
├── [MY ACCOUNT]           ← Always visible
│   └── My Capabilities    ← ExpansionTile (unchanged)
│
└── [SIGN OUT + VERSION]   ← Always visible
```

---

## UI Component Routing Table

| Component | Trigger | Destination Route | Overflow Behaviour |
|---|---|---|---|
| `Templates` tile (in Workspace section) | Tap | `context.push('/templates')` | N/A — navigates away |
| `Admin Dashboard` tile | Tap | `/admin/dashboard` | N/A |
| `My Region` tile | Tap | `/analytics` | N/A |
| `My Store` tile | Tap | `/analytics` | N/A |
| `My Activity` tile | Tap | `/activity` | N/A |
| `Notifications` tile | Tap | `/inbox` | N/A |
| `Documentation` tile | Tap | `showSnackBar('Coming soon')` (no route yet) | Graceful — shows Coming Soon |
| `Help` tile | Tap | `showSnackBar('Coming soon')` (no route yet) | Graceful — shows Coming Soon |
| `My Capabilities` | Tap | ExpansionTile expand/collapse in place | Long list → scrollable within ListView |
| `Sign Out` | Tap | Confirm dialog → AuthManager.logout() → /login | N/A |

---

## Comparative Decision Matrix

| Option | Description | Effort | Risk | UX Quality | PBAC Compliance |
|---|---|---|---|---|---|
| **A: Minimal** | Remove tab from `ShellTab.all`. Add Templates as a plain tile in the existing Admin management section in `profile_page.dart`. Zero widget redesign. | 1 file, 30 min | 🟢 Very Low | 🟡 No improvement to profile layout | ✅ Uses caps check |
| **B: Pragmatic (RECOMMENDED)** | Remove tab. Add Templates tile (PBAC-gated). Redesign profile into 4 named zones with section labels. Upgrade `ProfileHeader` to a premium identity card. Keep all existing widgets, just compose them differently. | 4 files, ~2-3 hrs | 🟡 Low | 🟢 Premium, role-aware, Material 3 | ✅ Uses caps check |
| **C: Enterprise Overhaul** | Remove tab. Full profile redesign: add gradient hero, animated avatar, statistics row per role (e.g. "24 audits this month"), lazy-loaded activity feed, settings as grouped bottom sheet. Extract to 8+ new widget files. | 10+ files, ~2 days | 🔴 High (scope creep) | 🟢 Very high | ✅ |

**Verdict: Option B — Pragmatic Balance**  
Option A is too minimal — the user explicitly asked for a profile redesign. Option C is overbuilt and risks introducing complexity to a page that doesn't need async data. Option B delivers the premium redesign using existing infrastructure.

---

## Blind Spots

1. **Bottom tab active-highlight regression** — After removing TEMPLATES, navigating to `/templates` via Profile will cause no tab to match, so `activeIndex` falls back to 0 (HOME). This is cosmetic only (no functional regression) but may feel wrong. The existing `shellActiveIndexFromLocation` function is tested — a new test for this scenario should be added.

2. **Profile page line count** — `profile_page.dart` is currently 163 lines. The redesign adds a zone-based layout and PBAC-gated Templates section. If not careful, the file will exceed 400 lines (GEMINI.md rule). Mitigation: Extract each zone into its own named widget method or separate `ProfileWorkspaceSection` widget file.

3. **Capabilities section expansion default** — The `ProfileCapabilitiesSection` is currently an `ExpansionTile` that starts collapsed. After moving it into a new "My Account" zone, the visual indentation may double (ExpansionTile inside a Card). Mitigation: Keep `ProfileCapabilitiesSection` as a standalone widget outside the Card, same as it is today.

---

## Conflicts with GEMINI.md / Rules

1. **Rule: Keep Files Small (<400 lines)** — `profile_page.dart` redesign risks exceeding 400 lines. Fix: Decompose zones into separate widget files (`profile_workspace_section.dart`, `profile_identity_card.dart`).

2. **Rule: PBAC over Role Hardcoding (Hybrid Entity-Driven UI gotcha)** — The current `_managementItems()` uses `UserPersona` checks to show management tiles. The Templates tile MUST NOT use `UserPersona` — it must use `caps.contains(AppCapabilities.templatesCreate)` directly. The Builder must receive this constraint explicitly.

---

## Implementation Plan (Option B)

### Files to Modify (MOD)
| # | File | Change |
|---|---|---|
| 1 | `lib/_shared/router/shell_tab.dart` | `[DEL]` Remove the TEMPLATES `ShellTab` entry (lines 34-39) |
| 2 | `lib/features/profile/pages/profile_page.dart` | `[MOD]` Restructure into 4 named zones. Add PBAC-gated Templates tile. |
| 3 | `lib/features/profile/widgets/profile_header.dart` | `[MOD]` Upgrade to `ProfileIdentityCard` — gradient background, larger avatar (radius 40), name + email stacked, role badge |
| 4 | `lib/features/profile/widgets/settings_section_group.dart` | `[MOD]` Add optional `sectionLabel` String param — renders a small-caps label above the Card |

### Files to Create (NEW)
| # | File | Purpose |
|---|---|---|
| 5 | `lib/features/profile/widgets/profile_workspace_section.dart` | PBAC+persona gated section: Admin Dashboard / My Region / My Store / Templates tiles |
| 6 | `test/router/shell_tab_visibility_test.dart` | Unit test: TEMPLATES tab absent after removal. Test that admin with `templatesCreate` sees 4 tabs (not 5). |

### Files NOT Changing (✅ Explicit)
- `app_router.dart` — `/templates` route stays in ShellRoute. No change.
- All template pages — No change.
- `profile_capabilities_section.dart` — No change.
- `sign_out_tile.dart` — No change.
- All backend files — No change.

---

## Profile Page Visual Design Spec (Option B)

```
┌─────────────────────────────────────────────┐
│  [IDENTITY CARD]                            │
│  ┌──────────────────────────────────────┐   │
│  │  🎨 Gradient banner (primary tint)   │   │
│  │  ⬤ Avatar (radius 40, initials)     │   │
│  │  Full Name                           │   │
│  │  [Role Badge]                        │   │
│  │  email@company.com                   │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  MY WORKSPACE  ← section label (sm caps)   │
│  ┌──────────────────────────────────────┐   │
│  │  [Admin] ⚙ Admin Dashboard      >   │   │
│  │  ────────────────────────────────    │   │  ← Role-specific items
│  │  [All w/ cap] 📄 Templates       >  │   │  ← PBAC-gated
│  └──────────────────────────────────────┘   │  ← Hidden if no items
│                                             │
│  ACTIVITY  ← section label                  │
│  ┌──────────────────────────────────────┐   │
│  │  ⏱ My Activity               >      │   │
│  │  ────────────────────────────────    │   │
│  │  🔔 Notifications             >      │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  SETTINGS  ← section label                  │
│  ┌──────────────────────────────────────┐   │
│  │  ☀/🌙 Theme          [toggle]       │   │
│  │  ────────────────────────────────    │   │
│  │  📖 Documentation             >      │   │
│  │  ────────────────────────────────    │   │
│  │  ❓ Help                      >      │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  MY ACCOUNT  ← section label                │
│  ⊕ My Capabilities  ← ExpansionTile         │
│                                             │
│  [→ SIGN OUT]  (danger color)               │
│  Checkly v1.0.0  (center, muted)            │
└─────────────────────────────────────────────┘
```

### Section Label Design
- Small-caps text, `colorScheme.primary` color, `letterSpacing: 1.2`
- `Padding(top: 20, bottom: 6)` before each Card
- First section (identity) has no label

### Identity Card Design
- Background: `colorScheme.primaryContainer` gradient fading to transparent
- Avatar radius: 40 (up from 28)
- Layout: Column centered (not Row)
- Name: `titleLarge` bold
- Email: `bodySmall` muted
- Role badge: `RoleBadge.large` (centered)
- Total height: ~180px

---

## Handoff Block

**Final Verdict**: ✅ VIABLE  
**Artifact Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_110313_b2de1993_profile_redesign.md`

**Effort Sizing**: Track A/B — Small Feature  
- 6 files total (4 MOD, 2 NEW)  
- No backend changes, no DB migrations, no DTO changes  
- Concurrency: Single Builder agent — sequential, no parallel work needed  

**AI Agent Mission Brief**:  
Remove the TEMPLATES entry from `ShellTab.all` in `shell_tab.dart`. Then redesign `profile_page.dart` into 4 named zones (Identity, Workspace, Activity, Settings) using section labels, with a premium `ProfileIdentityCard` header and a PBAC-gated Templates tile inside the Workspace section (gated by `AppCapabilities.templatesCreate`, NOT by UserPersona). Extract the Workspace zone into `profile_workspace_section.dart` to keep `profile_page.dart` under 400 lines. Add a unit test confirming the TEMPLATES tab is no longer in the visible tab list.

**Next Workflow**:  
Run `/implement` and pass the research artifact:  
`C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_110313_b2de1993_profile_redesign.md`



> **User Stated:** "I will not use a webpage to manage the backend. I only use the app."

**Architectural Implication:** The `Admin Dashboard` tile in the profile is the **primary admin command center**. The `AdminDashboardPage` (`admin_dashboard_page.dart`, 291 lines) already contains 8 capability-gated management sub-pages (User Management, Store Management, Audit Approvals, System Logs, Analytics, Schedule Audit, Role Management, Global Risk Management) plus a live stats panel (`CompactStatusPanel` with Users, Stores, Templates, Open Plans counts).

This changes the profile design weight for Admin persona:
- `Admin Dashboard` tile must NOT be styled as a plain `ListTile`. It should be a **featured action card** — visually heavier than other tiles — to signal that it is the admin's primary workspace entry point.
- The profile page for Admin IS the gateway to the whole backend. Its design must communicate this.

### Amended Per-Role Visual Spec

```
ADMIN persona:
├── [IDENTITY CARD]    ← gradient + large avatar + Admin role badge
├── [MY WORKSPACE]
│   ├── [FEATURED CARD] Admin Dashboard           ← Large, accent-color card
│   │   "User Mgmt · Store Mgmt · Logs · Roles"  ← subtitle showing sub-features
│   │   Icon: admin_panel_settings, fills full width, no divider to next tile
│   └── [TILE] Templates  (if templatesCreate cap)
├── [ACTIVITY]
│   ├── My Activity tile
│   └── Notifications tile
├── [SETTINGS]
│   ├── Theme toggle
│   ├── Documentation tile
│   └── Help tile
├── [MY ACCOUNT]  → My Capabilities (ExpansionTile)
└── [SIGN OUT + VERSION]

AREA MANAGER persona:
├── [IDENTITY CARD]    ← same gradient + Area Mgr role badge
├── [MY WORKSPACE]
│   └── [TILE] My Region  → /analytics
├── [ACTIVITY] + [SETTINGS] + [MY ACCOUNT] + [SIGN OUT]

STORE MANAGER persona:
├── [IDENTITY CARD]    ← same gradient + Store Mgr role badge
├── [MY WORKSPACE]
│   └── [TILE] My Store   → /analytics
├── [ACTIVITY] + [SETTINGS] + [MY ACCOUNT] + [SIGN OUT]

AUDITOR persona:
├── [IDENTITY CARD]    ← same gradient + Auditor role badge
├── [ACTIVITY] + [SETTINGS] + [MY ACCOUNT] + [SIGN OUT]
│   (MY WORKSPACE section hidden — no items)
```

### Admin Featured Card Design Spec

The `Admin Dashboard` tile in the Workspace section must use a distinct visual treatment:
```dart
// NOT a plain ListTile — render as a Card with:
// - fillColor: colorScheme.primaryContainer
// - icon: admin_panel_settings (24px, primary color)
// - title: 'Admin Dashboard' (titleMedium, bold)
// - subtitle: 'Users · Stores · Logs · Roles' (bodySmall, muted)
// - trailing: Icon(chevron_right)
// - borderRadius: 12
// - padding: 16
// Width: fills the full Card width (no separate ListTile padding)
```
This is achieved by replacing the plain `MenuItemData` route for Admin Dashboard with a `FeaturedWorkspaceTile` variant. The Builder should add an `isFeatured: bool` property to `MenuItemData` (or use a subclass) to trigger the special rendering in `_MenuTile`.

### Amended Files List (Delta from original)

The original Implementation Plan (6 files) remains correct. Add this one clarification:

| # | File | Amendment |
|---|---|---|
| 2 | `lib/features/profile/pages/profile_page.dart` | `[MOD]` Admin Dashboard tile must pass `isFeatured: true` to trigger featured-card rendering |
| 4 | `lib/features/profile/widgets/settings_section_group.dart` | `[MOD]` Add `isFeatured` bool to `MenuItemData`. When true, `_MenuTile` renders as a colored `Card` with `primaryContainer` background instead of a plain `ListTile` row. |

### Hypothesis Tracking (Amendment 1)

| Hypothesis | Source Checked | Decision | Architectural Implication |
|---|---|---|---|
| Admin has no web portal; app is sole admin interface | `admin_dashboard_page.dart` (291 lines, 8 sub-pages, live stats) | ✅ Approved | Admin Dashboard tile must be a featured card, not a plain list tile |
| Admin Dashboard already has Templates in its stats panel | `admin_dashboard_page.dart` line 100-105 (TEMPLATES stat row) | ✅ Confirmed | Admin sees Templates count on dashboard; Profile tile is a shortcut to manage them |
| Profile page currently reads caps from AuthManager | `profile_page.dart` (no `caps` read, uses `UserPersona`) | ✅ Confirmed — Gap | Builder must add `auth.caps` read; gating Templates tile on caps, not persona |

<forensic_evidence_amendment_1>

### Evidence A1: Admin Dashboard has 8 sub-pages + live stats (admin_dashboard_page.dart)
- User Management → `/admin/users` (cap: `usersManage`)
- Store Management → `/admin/stores` (cap: `storesWrite`)
- Audit Approvals → `/admin/approvals` (ungated)
- System Logs → `/admin/logs` (ungated)
- Analytics → `/analytics` (ungated)
- Schedule Audit → `/admin/schedule` (ungated)
- Role Management → `/admin/roles` (cap: `adminManageRoles`)
- Global Risk Management → `/admin/global-risks` (cap: `globalRisksManage`)
- Stats panel: Users, Stores, Templates, Open Plans (live counts)

### Evidence A2: profile_page.dart currently reads NO caps
```dart
// line 26 — persona-based gating only, no caps read
final persona = UserPersona.fromRole(user?.role);
// caps are NOT read. Builder must add:
// final caps = Set<String>.from(auth.currentUser?.capabilities ?? []);
```

### Evidence A3: AppCapabilities constants confirmed
- `AppCapabilities.templatesCreate = 'templates:create'` (app_capabilities.dart, line 15)
- `AppCapabilities.adminAccess = 'admin:access'` (line 14)

</forensic_evidence_amendment_1>

