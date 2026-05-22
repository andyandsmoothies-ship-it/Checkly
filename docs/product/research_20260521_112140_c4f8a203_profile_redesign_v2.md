# Research: Profile Page Redesign v2 — App-Only Admin + Enriched Design
**ID**: research_20260521_112140_c4f8a203_profile_redesign_v2
**Agent**: Scout (Architect)
**Date**: 2026-05-21
**Status**: FINAL — Viable
**Prior Research**: `docs/product/research_20260521_110313_b2de1993_profile_redesign.md` (read and confirmed intact)

---

## [ORIGIN_IDEA]
> The user wants to:
> 1. **Remove TEMPLATES from the bottom navigation bar** (already designed in prior research).
> 2. **Move Templates access into the Profile page** for the correct role (PBAC-gated by `templatesCreate`).
> 3. **Redesign the Profile page for ALL roles** — premium, role-aware, well-organized.
> 4. **NEW:** "I will not use a webpage to manage backend, I only use the app." — The Admin Dashboard tile in the Profile page is the **sole admin interface**. Its design must reflect this importance.
> 5. **NEW:** User wants design ideas from workflows/skills — enrich the profile visual design with proper Material 3 patterns, progressive disclosure, and role-appropriate hierarchy.

---

<latent_space_scratchpad>
## Internal Reasoning

### What changed vs. prior research?

Prior research (b2de1993) correctly identified:
- Remove TEMPLATES from `ShellTab.all`
- Add Templates tile (PBAC-gated) to Profile Workspace section
- Redesign Profile into 4 named zones
- Upgrade ProfileHeader to a premium identity card
- Extract Workspace zone to keep profile_page.dart < 400 lines

NEW CONSTRAINT: "I only use the app to manage backend."
This changes the **weight** of the Admin persona's Workspace section.
`admin_dashboard_page.dart` is a FULL admin hub:
- 8 PBAC-gated sub-pages
- Live stats panel (Users, Stores, Templates, Open Plans counts)
This is not a "nice to have" tile. It is the admin's command center.

**Design implication for Admin:**
The `Admin Dashboard` tile must be rendered as a FEATURED CARD — not a plain `ListTile` like every other item. It must:
- Occupy the full width of the Workspace section card
- Have a distinct background (`primaryContainer`)
- Show a subtitle listing the key sub-features ("Users · Stores · Approvals · Logs")
- Use a large icon (admin_panel_settings)

### Profile Page Current Reality (audited live):
- `profile_page.dart` = 163 lines. Layout: flat ListView, 4 dumb sections, no visual zones.
- `profile_header.dart` = Row layout, 28px avatar, name + role badge. No email. No gradient.
- `settings_section_group.dart` = Card + ListTiles. No `sectionLabel` support.
- `profile_capabilities_section.dart` = ExpansionTile. Unchanged.
- `sign_out_tile.dart` = Danger-color tile with confirm dialog. Unchanged.
- Management section (`_managementItems()`) uses `UserPersona` — NOT caps. This is a PBAC violation for the Templates tile specifically.
- NO `caps` read in `profile_page.dart`. Builder must add `auth.currentUser?.capabilities`.

### Design Skills Referenced:
- **ui-ux-designer SKILL.md**: Material 3 settings page, progressive disclosure, section labels in small-caps, identity card patterns, visual hierarchy with zone-based grouping.
- **interaction-design SKILL.md** (from skills list): Micro-interactions — section labels that animate in, haptic feedback on ListTile taps (already in `_MenuTile.onTap` via `HapticFeedback.lightImpact()`).
- **Material 3 canonical profile pattern**: Identity at top (large, personal), then role-specific workspace, then generic settings at bottom. Sign Out anchored at very bottom.

### Per-Role Design Decisions:

**ADMIN:**
- Identity Card: gradient `primaryContainer` background, avatar radius 40, name bold, email muted, "Admin" badge centered.
- MY WORKSPACE: FEATURED Admin Dashboard card (full width, accent bg, subtitle lists sub-features) + Templates tile (PBAC-gated by `templatesCreate`).
- The workspace section is the most populated for Admin and must feel like a control panel gateway.

**AREA MANAGER:**
- Identity Card: same gradient pattern, "Area Mgr" badge.
- MY WORKSPACE: Single "My Region" tile → `/analytics`.
- Workspace section is minimal (1 tile). Still show section label to maintain layout consistency.

**STORE MANAGER:**
- Identity Card: same pattern, "Store Mgr" badge.
- MY WORKSPACE: Single "My Store" tile → `/analytics`.
- Same as Area Manager in weight.

**AUDITOR:**
- Identity Card: same pattern, "Auditor" badge.
- MY WORKSPACE: HIDDEN entirely (0 items, section not rendered).
- First non-identity section is ACTIVITY.
- This is the most common role. No bloat.

### File Impact (delta from prior research):

Prior research planned 6 files. This v2 adds one clarification:
- `settings_section_group.dart` needs `isFeatured: bool` on `MenuItemData` to trigger featured-card rendering for Admin Dashboard.

Total file count: SAME (6 files: 4 MOD, 2 NEW). No additions.

### Key Gotcha for Builder:
`profile_page.dart` currently uses `UserPersona` to gate management items.
The Templates tile MUST use `caps.contains(AppCapabilities.templatesCreate)` instead.
But Admin Dashboard / My Region / My Store CAN continue using `UserPersona` (these are identity-based, not capability-based).
The Builder must NOT rip out `UserPersona` gating for workspace tiles — only ADD caps-based gating for the Templates tile.

### Admin Dashboard in Profile vs. Admin Dashboard page itself:
The profile tile is a SHORTCUT. The Admin Dashboard page (`/admin/dashboard`) is the full hub.
The profile tile does NOT duplicate the dashboard — it navigates to it.
The profile tile just needs to SIGNAL the richness of what is inside (subtitle listing sub-features).
</latent_space_scratchpad>

---

## Current Codebase Reality

<forensic_evidence>

### Evidence 1: TEMPLATES ShellTab — shell_tab.dart, lines 34-39
```dart
ShellTab(
  icon: Icons.description_outlined,
  label: 'TEMPLATES',
  route: '/templates',
  requiredCapability: AppCapabilities.templatesCreate,
),
```
Visible only when user has `templates:create` cap.

### Evidence 2: profile_page.dart — 163 lines, no caps read
```dart
// line 26 — persona-based gating only
final persona = UserPersona.fromRole(user?.role);
// caps are NOT read anywhere in this file
// Management tiles use persona checks, not caps
```
Gap: Builder must add: `final caps = Set<String>.from(auth.currentUser?.capabilities ?? []);`

### Evidence 3: profile_header.dart — 28px avatar, Row layout
```dart
CircleAvatar(radius: 28, ...)
Row(children: [avatar, Expanded(name + role badge)])
```
No email displayed. No gradient. Must be upgraded to premium identity card.

### Evidence 4: settings_section_group.dart — no sectionLabel support
```dart
class SettingsSectionGroup extends StatelessWidget {
  final List<MenuItemData> items;
  final bool themeToggle;
  // NO sectionLabel parameter
```
Must add `String? sectionLabel` param and `bool isFeatured` on `MenuItemData`.

### Evidence 5: AdminDashboardPage — 291 lines, IS the sole admin hub
Verified at `lib/features/admin/pages/admin_dashboard_page.dart`:
- 8 PBAC-gated management sub-pages (User Mgmt, Store Mgmt, Audit Approvals, System Logs, Analytics, Schedule Audit, Role Mgmt, Global Risk Mgmt)
- Live stats: Users, Stores, Templates, Open Plans (via `CompactStatusPanel`)
- This IS the sole admin backend interface. No web portal exists.

### Evidence 6: _managementItems() — correct persona gates for workspace tiles
```dart
if (persona == UserPersona.admin) → Admin Dashboard tile
if (persona == UserPersona.areaManager) → My Region tile
if (persona == UserPersona.storeManager) → My Store tile
```
These STAY as persona-based gates. Only Templates uses caps gate.

### Evidence 7: AppCapabilities.templatesCreate = 'templates:create'
```dart
// lib/_shared/constants/app_capabilities.dart, line 15
static const templatesCreate = 'templates:create';
```

### Evidence 8: Existing active task (prior research) — COMPLETE
`task_20260521_110313_b2de1993_profile_redesign.md` — Status: COMPLETE.
Prior research is valid and intact. This v2 extends it, does NOT replace it.

</forensic_evidence>

---

## E2E Workflow Map

```
CURRENT STATE:
[Bottom Nav] → HOME | ACTIVITY | PLANS | TEMPLATES(*) | PROFILE | INBOX
              (*) gated: only visible when caps has 'templates:create'

PROPOSED STATE:
[Bottom Nav] → HOME | ACTIVITY | PLANS | PROFILE | INBOX
              (TEMPLATES tab removed from ShellTab.all)

Admin flow:
  Tap PROFILE → ProfilePage
    └── [MY WORKSPACE]
          ├── [FEATURED CARD] Admin Dashboard → /admin/dashboard
          │     └── AdminDashboardPage (8 sub-pages + stats)
          └── [TILE] Templates (if templatesCreate cap) → /templates

Store Manager flow:
  Tap PROFILE → ProfilePage
    └── [MY WORKSPACE]
          └── [TILE] My Store → /analytics

Auditor flow:
  Tap PROFILE → ProfilePage
    └── [NO WORKSPACE SECTION]
    └── [ACTIVITY section first]

Tab highlight after Templates relocation:
  /profile    → PROFILE tab active ✅
  /templates  → No tab match → falls to index 0 (HOME tab) ← cosmetic only
  /admin/dashboard → No tab match → falls to HOME tab ← same behavior as today
```

```
PROFILE PAGE LAYOUT STATE MACHINE — All roles:

ProfilePage
├── [IDENTITY ZONE]         ← Always visible, all roles
│   └── ProfileIdentityCard
│         - Gradient bg (primaryContainer → transparent)
│         - CircleAvatar radius 40 (initials, white on primary)
│         - Full name (titleLarge, bold, center)
│         - Email (bodySmall, muted, center)
│         - RoleBadge (centered, medium size)
│         - Total height: ~180px
│
├── [MY WORKSPACE]          ← Visible only if persona has workspace items
│   Section label: "MY WORKSPACE" (small-caps, primary color, letter-spacing 1.2)
│
│   ADMIN:
│   └── [FEATURED CARD] Admin Dashboard
│         - background: primaryContainer
│         - icon: admin_panel_settings (primary, 24px, in colored bg box)
│         - title: 'Admin Dashboard' (titleMedium, bold)
│         - subtitle: 'Users · Stores · Approvals · Logs' (bodySmall, muted)
│         - trailing: chevron_right
│         - route: /admin/dashboard
│   └── [TILE] Templates (if caps.contains(templatesCreate))
│         - standard ListTile styling
│         - route: /templates
│
│   AREA MANAGER:
│   └── [TILE] My Region → /analytics
│
│   STORE MANAGER:
│   └── [TILE] My Store → /analytics
│
│   AUDITOR: (section hidden entirely)
│
├── [ACTIVITY]              ← Always visible, all roles
│   Section label: "ACTIVITY"
│   └── Card:
│         - My Activity tile → /activity
│         - [divider]
│         - Notifications tile → /inbox
│
├── [SETTINGS]              ← Always visible, all roles
│   Section label: "SETTINGS"
│   └── Card:
│         - Theme toggle
│         - [divider]
│         - Documentation tile (no route → snackbar "Coming soon")
│         - [divider]
│         - Help tile (no route → snackbar "Coming soon")
│
├── [MY ACCOUNT]            ← Always visible, all roles
│   Section label: "MY ACCOUNT"
│   └── ProfileCapabilitiesSection (ExpansionTile, collapsed by default)
│
└── [SIGN OUT + VERSION]    ← Always visible, all roles
      - SignOutTile (danger color, confirm dialog)
      - "Checkly v1.0.0" (center, muted, bodySmall)
```

---

## UI Component Routing Table

| Component | Role Visible | Trigger | Destination | Overflow |
|---|---|---|---|---|
| `ProfileIdentityCard` | All | Static | N/A | N/A |
| `Admin Dashboard` (featured) | Admin only | Tap | `/admin/dashboard` | N/A |
| `Templates` tile | Any role with `templatesCreate` cap | Tap | `/templates` | N/A |
| `My Region` tile | Area Manager | Tap | `/analytics` | N/A |
| `My Store` tile | Store Manager | Tap | `/analytics` | N/A |
| `My Activity` tile | All | Tap | `/activity` | N/A |
| `Notifications` tile | All | Tap | `/inbox` | N/A |
| `Theme toggle` | All | Switch | In-place state change | N/A |
| `Documentation` tile | All | Tap | snackbar "Coming soon" | Graceful |
| `Help` tile | All | Tap | snackbar "Coming soon" | Graceful |
| `My Capabilities` | All | Tap | ExpansionTile in-place | Long list → scrolls within ListView |
| `Sign Out` | All | Tap | Confirm dialog → logout → /login | N/A |

---

## Comparative Decision Matrix

| Option | Description | Effort | Risk | UX Quality | PBAC Compliance |
|---|---|---|---|---|---|
| **A: Minimal** | Remove tab. Add Templates as plain `ListTile` in existing Admin management section. No redesign. Zero visual improvement. | 1 file, 30 min | 🟢 Very Low | 🔴 No improvement, Admin Dashboard gets no prominence | ✅ If uses caps |
| **B: Pragmatic (RECOMMENDED)** | Remove tab. Add Templates tile (PBAC-gated). Redesign into 4 named zones. Upgrade ProfileHeader to identity card with gradient. Add `isFeatured` to Admin Dashboard tile. Add `sectionLabel` to `SettingsSectionGroup`. | 6 files, 2-3 hrs | 🟡 Low | 🟢 Premium, role-aware, Material 3 | ✅ caps-gated Templates |
| **C: Enterprise Overhaul** | Above + live stats mini-panel on profile for Admin (copies from AdminDashboardPage), animated avatar, role-specific action chips, async data loading. | 10+ files, 2 days | 🔴 High — premature async complexity, scope creep | 🟢 Very High | ✅ |

**Verdict: Option B**
Option A ignores the premium design ask. Option C adds async data loading that is premature — the Admin Dashboard already shows stats when you navigate to it. Profile page should stay a lightweight navigation layer.

---

## Blind Spots

1. **Admin Dashboard tile bottom-nav highlight after navigation** — Navigating from Profile → Admin Dashboard (`/admin/dashboard`) will cause no bottom tab to match, so `shellActiveIndexFromLocation` returns index 0 (HOME). This is cosmetic only. The Back button returns to Profile. Acceptable with existing test coverage.

2. **`profile_page.dart` line count after redesign** — Current 163 lines. Adding identity card, section labels, zone structure risks exceeding 400 lines. **Mitigation:** Extract `ProfileIdentityCard` to `profile_identity_card.dart` and `ProfileWorkspaceSection` to `profile_workspace_section.dart`. These are already planned in prior research.

3. **Admin-only `isFeatured` rendering in `settings_section_group.dart`** — Adding `isFeatured: bool` to `MenuItemData` changes a shared widget used by ALL roles. If Builder uses `isFeatured: true` outside Admin (accidental), all section groups will render wrong. **Mitigation:** Add assertion: `assert(!isFeatured || route != null, 'Featured tiles must have a route')`. Keep `isFeatured = false` as default — no behavioral change for existing tiles.

---

## Conflicts with GEMINI.md / Rules

1. **Rule: Keep Files Small (<400 lines)** — `profile_page.dart` is currently 163 lines. Adding full zone layout risks violation. Fix: Extract `ProfileIdentityCard` and `ProfileWorkspaceSection` into separate widget files (as planned).

2. **Rule: PBAC over Role Hardcoding (Hybrid Entity-Driven UI gotcha)** — Current `_managementItems()` uses `UserPersona` for workspace tiles. Templates tile MUST use `caps.contains(AppCapabilities.templatesCreate)`. Builder must NOT add Templates inside the `UserPersona.admin` block — it goes in a separate caps check below all persona checks.

3. **Rule: No Magic Strings** — `route: '/templates'` must use a named constant or route path constant if one exists in the codebase. Builder to verify if `AppRoutes` constants file exists before using raw strings.

---

## Implementation Plan (Option B — Supersedes Prior Research)

### Files to Modify [MOD]
| # | File | Change |
|---|---|---|
| 1 | `lib/_shared/router/shell_tab.dart` | `[DEL]` Remove the TEMPLATES `ShellTab` entry (lines 34-39) |
| 2 | `lib/features/profile/pages/profile_page.dart` | `[MOD]` Add `caps` read. Restructure into 4 named zones with section labels. Add Templates tile (caps-gated). Admin Dashboard tile passes `isFeatured: true`. |
| 3 | `lib/features/profile/widgets/profile_header.dart` | `[MOD → RENAME]` Upgrade to `ProfileIdentityCard` — gradient bg, radius 40 avatar, name + email centered column, centered RoleBadge |
| 4 | `lib/features/profile/widgets/settings_section_group.dart` | `[MOD]` Add `String? sectionLabel` to `SettingsSectionGroup`. Add `bool isFeatured = false` to `MenuItemData`. When `isFeatured: true`, `_MenuTile` renders with `primaryContainer` background and `titleMedium` bold text instead of standard `ListTile` styling. |

### Files to Create [NEW]
| # | File | Purpose |
|---|---|---|
| 5 | `lib/features/profile/widgets/profile_workspace_section.dart` | Encapsulates the MY WORKSPACE zone. Receives `persona` and `caps`. Renders: featured Admin Dashboard card (admin), My Region tile (area manager), My Store tile (store manager), Templates tile (any role with `templatesCreate`). Returns `SizedBox.shrink()` for Auditor. |
| 6 | `test/router/shell_tab_visibility_test.dart` | Unit test: `shellActiveIndexFromLocation` no longer finds TEMPLATES in visible tabs. Admin with `templatesCreate` sees 4 visible tabs (HOME, ACTIVITY, PLANS, PROFILE — wait, +INBOX = 5). Confirm exact count. |

### Files NOT Changing (Explicit)
- `app_router.dart` — `/templates` route stays inside ShellRoute. No change.
- `profile_capabilities_section.dart` — Unchanged.
- `sign_out_tile.dart` — Unchanged.
- `theme_toggle_tile.dart` — Unchanged.
- All template pages — Unchanged.
- All admin pages — Unchanged.
- All backend files — Unchanged.

---

## Profile Page Visual Design Spec (Option B, Enriched)

```
┌─────────────────────────────────────────────────┐
│  [IDENTITY CARD — all roles]                    │
│  ┌─────────────────────────────────────────┐    │
│  │ 🎨 Gradient: primaryContainer → clear   │    │
│  │                                         │    │
│  │         ●  Avatar (radius 40)           │    │
│  │         initials, white on primary      │    │
│  │                                         │    │
│  │         Full Name (titleLarge, bold)    │    │
│  │         email@company.com (muted)       │    │
│  │         [Role Badge — centered]         │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  MY WORKSPACE  ← section label (primary, 1.2ls) │
│  ┌─────────────────────────────────────────┐    │
│  │  ADMIN ONLY:                            │    │
│  │  ┌───────────────────────────────────┐  │    │
│  │  │ 🔵 [primaryContainer bg]          │  │    │
│  │  │ ⚙  Admin Dashboard          >    │  │    │
│  │  │    Users · Stores · Approvals     │  │    │
│  │  └───────────────────────────────────┘  │    │
│  │  ─────────────────────────────────────  │    │
│  │  📄 Templates (if templatesCreate cap)> │    │
│  └─────────────────────────────────────────┘    │
│  [section hidden for Auditor]                   │
│                                                 │
│  ACTIVITY  ← section label                      │
│  ┌─────────────────────────────────────────┐    │
│  │  ⏱  My Activity                    >   │    │
│  │  ─────────────────────────────────────  │    │
│  │  🔔 Notifications                   >  │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  SETTINGS  ← section label                      │
│  ┌─────────────────────────────────────────┐    │
│  │  ☀/🌙 Theme              [toggle]       │    │
│  │  ─────────────────────────────────────  │    │
│  │  📖 Documentation                   >  │    │
│  │  ─────────────────────────────────────  │    │
│  │  ❓ Help                             >  │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  MY ACCOUNT  ← section label                    │
│  ⊕ My Capabilities  ← ExpansionTile (no card)  │
│                                                 │
│  [→ SIGN OUT]  (danger color, full-width btn)   │
│  Checkly v1.0.0  (center, muted, bodySmall)     │
└─────────────────────────────────────────────────┘
```

### Section Label Spec
- Font: `labelSmall`, `letterSpacing: 1.5`, `fontWeight: w600`
- Color: `colorScheme.primary`
- Padding: `EdgeInsets.only(top: 20, bottom: 6, left: 4)`
- Applied via `sectionLabel` param on `SettingsSectionGroup`

### Identity Card Spec
- Container: `primaryContainer` with linear gradient (opacity 0.4 → 0.0, top to bottom)
- Shape: `RoundedRectangleBorder(borderRadius: 16)`
- Avatar: `CircleAvatar(radius: 40)`, `backgroundColor: colorScheme.primary`, white initials
- Layout: `Column(crossAxisAlignment: center)` — avatar, 12px gap, name, 4px gap, email, 8px gap, RoleBadge
- Total height: ~200px including padding

### Admin Dashboard Featured Card Spec
- `MenuItemData(isFeatured: true, icon: Icons.admin_panel_settings, label: 'Admin Dashboard', description: 'Users · Stores · Approvals · Logs', route: '/admin/dashboard')`
- When `isFeatured == true`, `_MenuTile` renders:
  ```
  Container(
    decoration: BoxDecoration(
      color: colorScheme.primaryContainer,
      borderRadius: 12,
    ),
    padding: EdgeInsets.all(16),
    child: Row(
      children: [
        Container(padding: 10, decoration: circle primary bg, child: Icon(adminIcon, primary)),
        16px gap,
        Expanded(Column: title (titleMedium bold) + description (bodySmall muted)),
        chevron_right icon,
      ]
    )
  )
  ```

---

## Handoff Block

**Final Verdict**: ✅ VIABLE
**Artifact Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_112140_c4f8a203_profile_redesign_v2.md`

**Prior Research** (do not delete):
`C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_110313_b2de1993_profile_redesign.md`

**Effort Sizing**: Track A/B — Small Feature
- 6 files total (4 MOD, 2 NEW)
- No backend changes, no DB migrations, no DTO changes
- Concurrency: Single Builder agent — sequential, no parallel work needed

**AI Agent Mission Brief**:
Remove TEMPLATES from `ShellTab.all`. Redesign `profile_page.dart` into 5 named zones (Identity, Workspace, Activity, Settings, Account) using section labels from `SettingsSectionGroup`. Upgrade `ProfileHeader` to a premium `ProfileIdentityCard` (gradient bg, radius-40 avatar, centered column with email). Add `isFeatured: bool` to `MenuItemData` — Admin Dashboard tile uses `isFeatured: true` to render with `primaryContainer` background as the primary admin command-center entry point. Add Templates tile gated by `caps.contains(AppCapabilities.templatesCreate)` (NOT by persona). Extract `ProfileWorkspaceSection` and `ProfileIdentityCard` to keep `profile_page.dart` under 400 lines.

**Next Workflow**:
Run `/implement` and pass **this** research artifact (v2):
`C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_112140_c4f8a203_profile_redesign_v2.md`
