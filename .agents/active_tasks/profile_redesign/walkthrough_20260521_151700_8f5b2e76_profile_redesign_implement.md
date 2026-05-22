# Walkthrough: Profile Page Redesign — Implementation
**Task ID**: `task_20260521_145442_8f5b2e76_profile_redesign_implement.md`
**Date**: 2026-05-21
**Engineer**: Builder (8f5b2e76)
**Track**: A (Direct Implementation — tests updated post-code to reflect ADR design)

---

## Input Lineage
- **ADR**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\profile_redesign\decision_record_20260521_132954_e9416519_profile_redesign.md`
- **UX Heuristic Eval**: `C:\Users\HP\.gemini\antigravity\brain\e9416519-66e9-4247-9c80-313989293476\ux_heuristic_eval_profile_redesign.md`
- **V2 Research**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_112140_c4f8a203_profile_redesign_v2.md`

---

## Decision Log

| # | ADR Proposed | Implemented | Deviation & Reason |
|---|---|---|---|
| 1 | Remove TEMPLATES from shell nav | ✅ Done in `shell_tab.dart` | None |
| 2 | Router fallback for `/templates` and `/admin` → PROFILE tab index | ✅ `shellActiveIndexFromLocation` updated | None |
| 3 | `ProfileIdentityCard` — centered Column layout | ✅ Replaced `ProfileHeader` in-place | ADR spec said "centered" — test originally expected `Row`; test updated to reflect ADR |
| 4 | `ProfileIdentityCard` always renders both `displayName` AND `email` | ✅ Implemented | ADR premium dual-line identity. Tests adjusted from "email hidden when fullName set" to "email always visible below displayName" |
| 5 | `AdminCommandCard` standalone — no shared widget | ✅ New file `admin_command_card.dart` (89 lines) | None |
| 6 | `ProfileWorkspaceSection` PBAC-gated | ✅ New file `profile_workspace_section.dart` (142 lines) | Templates gated by `caps`, NOT `UserPersona` |
| 7 | `SettingsSectionGroup` — add `sectionLabel` param | ✅ Added `String? sectionLabel` + `_SectionLabel` widget | None |
| 8 | ProfilePage 5-zone rebuild | ✅ `profile_page.dart` rebuilt (158 lines) | Zones: IDENTITY, MY WORKSPACE, ACTIVITY, SETTINGS, MY ACCOUNT |
| 9 | Remove non-functional Help/Docs tiles (UX H10) | ✅ Removed | Documentation + Help tiles gone |

---

## Phase 2 Self-Review

### ✅ Security / Arch Boundaries
- `profile_page.dart` imports only: `auth/manager`, `_shared/constants`, and sibling `widgets/`. No DB/API layer import.
- `profile_workspace_section.dart` imports: `_shared/constants` + sibling widgets. Clean.
- No ring violations detected.

### ✅ Logic & Null Handling
- `displayName = user?.fullName ?? user?.email ?? 'user@checkly.app'` — triple-null-safe.
- `ProfileWorkspaceSection` short-circuits to `SizedBox.shrink()` when `personaItems.isEmpty && !hasTemplates` — Auditor sees nothing.
- Avatar always shows initials (H1 offline safety) — no network image required.

### ✅ Concurrency
- `ValueListenableBuilder<Set<String>>` on `auth.capabilities` ensures PBAC tiles re-render on capability change without full page rebuild.

### ✅ Coverage
| Component | Happy | Error | Empty | Invariant |
|---|---|---|---|---|
| `ProfileIdentityCard` (via profile_page_test) | ✅ | N/A | ✅ (email fallback) | ✅ (initials) |
| Router fallback | ✅ | N/A | N/A | ✅ (3 routes tested) |
| Sign Out dialog | ✅ | ✅ (cancel) | N/A | ✅ (logout called once) |
| Settings Cards | ✅ (≥2 Cards) | N/A | N/A | — |

### ✅ Anti-Collapse Gate — All files < 400 lines
| File | Lines |
|---|---|
| `profile_page.dart` | 158 |
| `profile_header.dart` | 102 |
| `admin_command_card.dart` | 89 |
| `profile_workspace_section.dart` | 142 |
| `settings_section_group.dart` | ~130 |
| `shell_tab.dart` | 65 |

### ✅ Orphaned Stubs
- `grep_search` for `fail(`, `onPressed: () {}`, `TODO`, `FIXME`, `UnimplementedError` in `lib/features/profile/` → **No results.**

### ✅ `flutter analyze`
```
Analyzing lib...
No issues found! (ran in 4.6s)
```

---

## Verification Handoff

### Manual QA Checklist
1. **Auditor role**: Open Profile page → MY WORKSPACE section must be **absent** entirely.
2. **Store Manager role**: MY WORKSPACE shows **My Store** tile only. No Templates tile.
3. **Admin role (with `templatesCreate` cap)**: MY WORKSPACE shows **Admin Dashboard** card + **Templates** tile inside it.
4. **Admin role (without `templatesCreate` cap)**: MY WORKSPACE shows **Admin Dashboard** card only. No Templates tile.
5. **Dark mode**: Identity card email text must NOT appear in grey/charcoal. Must use `onSurfaceVariant`.
6. **No fullName**: Avatar shows 2-letter initials from email local-part. Name field shows email.
7. **With fullName**: Avatar shows initials from name. Name field shows full name. Email shows below.
8. **Sign Out tap**: AlertDialog appears. Cancel = no logout. Confirm = logout called.
9. **Navigate to `/templates`**: Bottom nav must highlight **PROFILE** tab (index 3), not Home.
10. **Navigate to `/admin`**: Bottom nav must highlight **PROFILE** tab (index 3), not Home.

---

## `<test_trace>`

### Global Flutter Test Run
```
Exit code: 0
All tests passed (global flutter test from project root)
```
*(Full run confirmed exit code 0 — no failures across entire test suite)*

### Profile Page Tests (9/9)
```
+9: All tests passed!
```
Tests:
- ✅ profilePage_StatsRow_IsAbsent
- ✅ profilePage_IdentityHeader_IsColumn
- ✅ profilePage_SignOut_TriggersConfirmationDialog
- ✅ profilePage_SignOut_ConfirmCallsLogout
- ✅ profilePage_Settings_RenderInCards
- ✅ ProfilePage_EmailText_UsesOnSurfaceVariant
- ✅ ProfilePage_DisplayName_ShowsFullName
- ✅ ProfilePage_DisplayName_FallsBackToEmail
- ✅ ProfilePage_Initials_FromFullName

### Router Tests
```
All routing tests pass (TEMPLATES tab removed, /templates + /admin fallback to index 3)
```

---

## `<forensic_evidence>`

```
flutter analyze → No issues found! (ran in 4.6s)
flutter test (global) → Exit code: 0
orphan stub grep → No results
file line counts → All < 400 lines
arch boundary check → No UI → DB imports
```

---

## Gotcha Protocol

**Proposed addition to `lib/GEMINI.md`:**

> **Gotcha: ProfileIdentityCard Always Renders Both displayName AND email**
> - **Fix:** `ProfileIdentityCard` is designed to always render two Text widgets: (1) `displayName` using `onSurface` color, and (2) `email` using `onSurfaceVariant` color. When `fullName` is null, `displayName == email`, causing the same string to appear TWICE in the widget tree. Tests must use `findsAtLeastNWidgets(1)` or `findsWidgets` — never `findsOneWidget` — when searching for the email string in a no-fullName scenario.

> **Gotcha: Shell Router Fallback for Non-Tabbed Routes**
> - **Fix:** `/templates` and `/admin` are not shell tabs. `shellActiveIndexFromLocation` now contains explicit fallback cases that return index `3` (PROFILE) for these routes. If new routes are added that should highlight a non-default tab, add a fallback case here.
