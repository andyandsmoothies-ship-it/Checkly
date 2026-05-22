# Walkthrough: Visual QA Fixes — Profile & Admin Dashboard
**Date**: 2026-05-21T17:20:00+07:00
**ShortID**: e9416519
**Track**: B1 (Direct Implementation)

---

## Input Lineage
- **Source**: `C:\Users\HP\.gemini\antigravity\brain\e9416519-66e9-4247-9c80-313989293476\visual_qa_report.md.resolved`

---

## ASCII Overview
```
[ProfilePage]
  ─ IDENTITY zone     (kept)
  ─ WORKSPACE zone    (kept)
  ─ ACTIVITY zone     (DELETED — duplicated bottom nav tabs)
  ─ SETTINGS zone     (kept)
  ─ MY ACCOUNT zone   (kept)

[AdminDashboardPage]
  ─ CompactStatusPanel (stats) → onTap REMOVED → pure info chips, no chevron
  ─ Single menu Card   (SPLIT into 2 Cards)
      ├─ CORE Card    (User Mgmt, Store Mgmt, Role Mgmt, User Groups)
      └─ OPERATIONS Card (Approvals, Schedule, Analytics, Logs, Global Risk)
```

---

## Decision Log

| Heuristic Violation | Proposed Fix | Implemented |
|---|---|---|
| H8: ACTIVITY zone duplicates bottom nav ACTIVITY/INBOX | Delete entire zone | ✅ Deleted `SettingsSectionGroup(sectionLabel: 'ACTIVITY', ...)` block |
| H4: Stat tiles have chevrons implying navigation — same as the list below | Remove chevrons + onTap from stats | ✅ Made `StatRowData.onTap` optional (`VoidCallback?`). Chevron hidden when null. |
| H8: 9-item list is cognitively overwhelming | Split into two grouped cards | ✅ Split into CORE card (4 items) and OPERATIONS card (5 items) with `SectionHeader` labels |

**Key Design Decision — `CompactStatusPanel` change:**
Made `onTap` optional rather than adding a separate `informational` flag. This is backward-compatible — all other callers that pass `onTap` keep their chevrons and tap gestures. The Admin Dashboard is the first caller to omit `onTap`.

---

## Files Modified
| File | Change |
|---|---|
| `lib/features/profile/pages/profile_page.dart` | Removed Zone 3 (ACTIVITY block, 17 lines deleted). Updated class docstring. |
| `lib/_shared/widgets/compact_status_panel.dart` | `StatRowData.onTap` changed to `VoidCallback?`. Added `_buildRow()` helper. Chevron and InkWell conditionally hidden when `onTap` is null. |
| `lib/features/admin/pages/admin_dashboard_page.dart` | Removed `onTap` from all 4 `StatRowData` entries. Replaced single `_buildMenuItems` with `_buildCoreMenuItems`, `_buildOperationsMenuItems`, and `_interleave` helpers. Two distinct `Card` widgets with `SectionHeader` separators. |

---

## Verification Handoff
Steps for QA to verify:

1. **Profile Page** — Open app as any role. Go to Profile tab.
   - ✅ ACTIVITY section (My Activity, Notifications) must NOT appear.
   - ✅ Page should show: IDENTITY → WORKSPACE (if non-auditor) → SETTINGS → MY ACCOUNT.

2. **Admin Dashboard — Stats Panel** — Open app as admin. Go to Admin Dashboard.
   - ✅ The 4 stat tiles (USERS, STORES, TEMPLATES, OPEN PLANS) must NOT be tappable.
   - ✅ No chevron icons on the stat tiles.

3. **Admin Dashboard — Menu Groups** — Scroll down on Admin Dashboard.
   - ✅ Two distinct card sections labeled CORE and OPERATIONS.
   - ✅ CORE card: User Management, Store Management, Role Management, User Groups.
   - ✅ OPERATIONS card: Audit Approvals, Schedule Audit, Analytics, System Logs, Global Risk Management.
   - ✅ All items in both cards are still tappable (chevron icons present).

---

<test_trace>
flutter analyze — Full project
No issues found! (ran in 80.4s)
Exit code: 0
</test_trace>

<forensic_evidence>
flutter analyze: 0 issues, 0 warnings.
</forensic_evidence>

---

## Gotcha Protocol
No new gotchas. `CompactStatusPanel.onTap` is now optional — document for future callers:
> If using `StatRowData` without `onTap`, the row renders as an informational chip (no InkWell, no chevron). This is by design.
