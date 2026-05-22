# Walkthrough: Homepage Campaign Relocation
**Date**: 2026-05-21T18:10:00+07:00
**ShortID**: ab12cd34
**Track**: A (Direct Build — UI only, no tests required before coding)

---

## Input Lineage
- **Source**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\homepage_campaign_relocation\implementation_plan_20260521_172200_ab12cd34_homepage_campaign_relocation.md`

---

## ASCII Overview
```
BEFORE:
[HOME tab / AdminDashboardVariant]
  ├─ CompactStatusPanel (4 KPIs)
  ├─ AdminActiveCampaignsWidget  ← DELETED
  └─ SubmissionFeedSection

[PLANS tab / ActionPlansPage]
  └─ search + filter chips + grouped plan list

AFTER:
[HOME tab / AdminDashboardVariant]
  ├─ CompactStatusPanel (4 KPIs)
  └─ SubmissionFeedSection        ← CLEAN

[PLANS tab / ActionPlansPage]
  ├─ _CampaignsNavCard            ← NEW (static, no fetch, → /programs)
  ├─ search + filter chips
  └─ grouped plan list
```

---

## Decision Log

| Plan Constraint | Implemented |
|---|---|
| Remove `AdminActiveCampaignsWidget` from `admin_dashboard_variant.dart` | ✅ Deleted import + call + spacer |
| Delete `admin_active_campaigns_widget.dart` (dead code) | ✅ File deleted from disk |
| Add static Campaigns nav card to `ActionPlansPage` | ✅ `_CampaignsNavCard` added as first child of Column |
| Route → `/programs` (NOT `/plans`) | ✅ `context.push('/programs')` |
| Do NOT touch `manager_dashboard_variant.dart` | ✅ Not modified |

**Key Design Decisions:**
- `_CampaignsNavCard` is a private `StatelessWidget` at the bottom of the file — keeps the feature local, no new file created (low enough complexity).
- Placed as the **first child** of the `Column` inside `ListenableBuilder`. It renders in all states where the `Column` renders (success + partial-error). Full-error / loading show early-return widgets (card absent — acceptable per plan lifecycle table).
- Used `context.push('/programs')` (not `go`) to preserve back-stack — the user can tap Back to return to PLANS.

---

## Test Contracts Verification

| ID | Pass Condition | Status |
|---|---|---|
| TC-01 | No `AdminActiveCampaignsWidget` in Admin HOME widget tree | ✅ Widget + file deleted |
| TC-02 | Campaigns card in PLANS tab navigates to `/programs` | ✅ `context.push('/programs')` wired |
| TC-03 | `ProgramListPage` FAB still PBAC-gated | ✅ Not modified — verified untouched |
| TC-04 | `manager_dashboard_variant.dart` unaffected | ✅ Not modified |

---

## Verification Handoff
Manual steps for QA on emulator:

1. **TC-01 — Home clean**: Log in as Admin → HOME tab → scroll down. Confirm no "Active Campaigns" section or "+ NEW CAMPAIGN" button.
2. **TC-02 — Plans card works**: Tap PLANS tab → Campaigns card appears at top → tap it → navigates to Program List page → Back button returns to PLANS.
3. **TC-03 — FAB gated**: On Program List page, confirm the FAB "+ New Programme" is only visible for users with `programsCreate` capability.
4. **TC-04 — Area Manager unaffected**: Log in as Area Manager → HOME tab → confirm Campaign Progress widget still shows normally.

---

<test_trace>
rtk flutter analyze (full project)
Analyzing lib...
No issues found! (ran in 6.3s)
Exit code: 0
</test_trace>

<forensic_evidence>
flutter analyze: 0 issues, 0 warnings.
admin_active_campaigns_widget.dart: deleted (confirmed via del command exit 0).
admin_dashboard_variant.dart: import line removed, widget call removed.
action_plans_page.dart: _CampaignsNavCard class appended (330 lines, under 400 limit).
manager_dashboard_variant.dart: not modified.
</forensic_evidence>

---

## Gotcha Protocol
No new gotchas discovered.
> Reminder: `/plans` routes to `ActionPlansPage` (action plans). `/programs` routes to `ProgramListPage` (campaigns). These are different routes. Do NOT confuse them.
