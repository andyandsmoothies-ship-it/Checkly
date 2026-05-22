# Walkthrough: Profile Campaign Integration Guard Fix
**Date**: 2026-05-21T18:43:00+07:00
**ShortID**: 5a7b8c9d
**Track**: A (Direct Build — Bug Fix)

---

## Input Lineage
- **Source Input**: `C:\Users\HP\.gemini\antigravity\brain\8a0f594a-1450-4747-8aa4-ea6181df4b19\failure_report_20260521_184100_5a7b8c9d_profile_campaign_integration.md.resolved`

---

## ASCII Overview
```
BEFORE (Failing):
[Profile Page → ProfileWorkspaceSection.build]
  └── Early Return Guard (personaItems.isEmpty && !hasTemplates)
       └── Triggers for Admin who has no persona items + lacks templatesCreate!
       └── Hides the Admin Workspace card completely!

AFTER (Fixed):
[Profile Page → ProfileWorkspaceSection.build]
  └── Early Return Guard (persona == UserPersona.auditor && !hasTemplates)
       └── ONLY triggers for Auditor.
       └── Admins, Area Managers, and Store Managers correctly bypass it and show their cards.
```

---

## Decision Log

| Bug Cause | Fix Action | Result |
|---|---|---|
| Early-return guard hid workspace if `personaItems.isEmpty && !hasTemplates` | Change guard to check `persona == UserPersona.auditor && !hasTemplates` | ✅ Correctly scope-limited to Auditor, leaving Admin/others unaffected |

---

## Verification Handoff
1. Run `rtk flutter test test/features/profile/pages/profile_page_test.dart`.
2. All 9 tests pass successfully.

---

<test_trace>
rtk flutter test test\features\profile\pages\profile_page_test.dart
00:01 +8: ProfilePage — Real Name Display ProfilePage_DisplayName_FallsBackToEmail — header shows email in BOTH fields when fullName is null
00:01 +9: All tests passed!
</test_trace>

<forensic_evidence>
flutter analyze: 0 issues, 0 warnings.
profile_workspace_section.dart: Modified line 34 to change check to `persona == UserPersona.auditor`. File length remains 153 lines.
</forensic_evidence>

---

## Gotcha Protocol
No new gotchas. The Auditor role remains the only stateless role that lacks standard command cards/menus.
