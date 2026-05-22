# Walkthrough: Profile Campaign Integration
**Date**: 2026-05-21T18:35:00+07:00
**ShortID**: 5a7b8c9d
**Track**: A (Direct Build — UI only)

---

## Input Lineage
- **Source**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\homepage_campaign_relocation\implementation_plan_20260521_183500_5a7b8c9d_profile_campaign_integration.md`

---

## ASCII Overview
```
BEFORE (after previous slice):
[Profile Page → MY WORKSPACE → Admin]
  └── Card
       ├── AdminCommandCard  (Admin Dashboard, primary)
       ├── Divider (always shown)
       └── SecondaryTools (Templates + Campaigns as list tiles)

[PLANS tab / ActionPlansPage]
  ├── _CampaignsNavCard (static card at top)
  └── search + filter chips + plan list

AFTER:
[Profile Page → MY WORKSPACE → Admin]
  └── Card
       ├── AdminCommandCard (Admin Dashboard, primaryContainer bg)
       ├── SizedBox(height:8)
       ├── AdminCommandCard (Campaigns, tertiaryContainer bg)  ← NEW
       └── [if hasTemplates]
            ├── SizedBox(height:4) + Divider
            └── SettingsSectionGroup (Templates only)

[PLANS tab / ActionPlansPage]
  └── search + filter chips + plan list  ← _CampaignsNavCard REMOVED
```

---

## Decision Log

| Plan Step | Implemented |
|---|---|
| Add `overrideIconColor` + `overrideTextColor` to `AdminCommandCard` | ✅ Both added as `Color?`. Defaults fall back to `cs.primary` / `cs.onPrimaryContainer` — backward-compatible. |
| Add Campaigns as second `AdminCommandCard` in `_buildAdminWorkspace` | ✅ Uses `cs.tertiaryContainer` / `cs.tertiary` / `cs.onTertiaryContainer` |
| Make divider + secondary tools conditional on `hasTemplates` | ✅ Wrapped in `if (hasTemplates) ...[]` spread |
| Remove Campaigns from `_buildAdminSecondaryTools` | ✅ Method now only builds Templates tile |
| Remove `_CampaignsNavCard` call from `ActionPlansPage` | ✅ Removed from Column children |
| Delete `_CampaignsNavCard` class | ✅ Deleted — 40 lines of dead code removed |

**Key design decision**: Used `Icons.campaign_rounded` (filled variant) for the card icon to match the plan spec. The tertiary color scheme visually differentiates it from the primary Admin Dashboard card — two distinct affordances, not a hierarchy.

---

## Verification Handoff
Manual steps for QA on emulator:

1. **Campaigns card on Profile** — Log in as Admin → Profile tab → MY WORKSPACE.
   - ✅ Two stacked cards: "Admin Dashboard" (primary/blue bg) and "Campaigns" (tertiary/distinct bg).
   - ✅ Tapping "Campaigns" navigates to `/programs` (ProgramListPage).
   - ✅ Back button returns to Profile.

2. **Templates conditional** — Verify with user who HAS `templatesCreate` capability:
   - ✅ A divider + "Templates" list tile appears below the Campaigns card.

3. **Templates hidden** — Verify with user who LACKS `templatesCreate` capability:
   - ✅ NO divider, NO Templates tile. Only two `AdminCommandCard`s visible.

4. **PLANS tab clean** — Navigate to PLANS tab:
   - ✅ No "Campaigns" nav card at top. Page starts directly with search bar + filter chips.

---

<test_trace>
rtk flutter analyze (full project)
Analyzing lib...
No issues found! (ran in 6.4s)
Exit code: 0
</test_trace>

<forensic_evidence>
flutter analyze: 0 issues, 0 warnings.
admin_command_card.dart: 2 new optional params (overrideIconColor, overrideTextColor) added — backward-compatible. 95 lines total.
profile_workspace_section.dart: Campaigns elevated to AdminCommandCard, hasTemplates guard restored. 153 lines total.
action_plans_page.dart: _CampaignsNavCard call removed, class deleted. 287 lines total (down from 328).
</forensic_evidence>

---

## Gotcha Protocol
No new gotchas. Note for future:
> `AdminCommandCard` now supports full color theming via 3 optional overrides: `overrideColor` (bg), `overrideIconColor` (icon), `overrideTextColor` (text/chevron). All default to primary scheme. Use tertiary scheme for secondary-tier navigation cards.
