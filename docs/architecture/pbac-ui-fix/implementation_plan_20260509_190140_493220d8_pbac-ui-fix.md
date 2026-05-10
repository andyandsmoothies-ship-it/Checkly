<latent_space_scratchpad>
Key findings:
- Backend has 18 constants. Flutter has 11. Delta = 7 missing constants.
- Missing: programsList, programsExecute, programsManage, programsReview, programsAssignmentsMy, programsAssignmentsList, globalRisksManage.
  Note: analyticsView IS missing from Flutter (backend has it at line 33), but analyticsAdmin IS present.
- template_card.dart is 258 lines — under the 400-line rule. OK to edit directly.
- app_capabilities.dart is 42 lines. Very small.
- The isAdmin flag in template_list_page.dart is computed by checking `templatesCreate`, then passed to TemplateCard.
  - This means: if you have templatesCreate but NOT templatesDelete, you still see "Delete".
  - Fix: TemplateCard needs to take 3 separate booleans OR lookup PolicyManager directly.
  - Decision: inject PolicyManager directly inside TemplateCard (simpler, no prop drilling).
  - Risk: TemplateCard is a StatelessWidget — direct GetIt access is fine.
- adminDomainCapabilities Set in app_capabilities.dart must also be audited (does it need new entries?).
  - New programs capabilities are store-manager/area-manager scope, NOT admin-domain. Only programsCreate is admin-domain.
  - globalRisksManage IS admin-domain — add it.
- No programs UI files need to be patched yet because those UI screens don't exist in Flutter (the Programs feature is backend-only per previous sessions).
  - Only the constants file needs the new programs strings. The UI guard patches will be done when the programs UI is built.
- Quick Start leak is the only urgent guard to add — confirmed file and line.
</latent_space_scratchpad>

# Implementation Plan: PBAC UI Enforcement Fixes
**Plan ID:** `implementation_plan_20260509_190140_493220d8_pbac-ui-fix`
**Date:** 2026-05-09 | **Short ID:** `493220d8`

## Input Lineage
- **Source Report:** `C:\Users\HP\.gemini\antigravity\brain\37bc7901-3602-4f53-a712-70ab7635cfd8\pbac_contract_and_leaks_report.md`
- **Expected Behavior Contract:** `C:\Users\HP\.gemini\antigravity\brain\493220d8-99f2-4839-9729-5c0dc0748efe\pbac_expected_behavior_report.md`

---

## Executive Summary & Out of Scope

**Goal:** Synchronize the Flutter UI's `AppCapabilities` constants file with the backend, and patch 2 specific "leaky" UI components where buttons appear without capability guards. This prevents the `403 Forbidden` crash-on-click bug for restricted roles.

**In Scope:**
- `lib/_shared/constants/app_capabilities.dart` — add 8 missing constants and update `adminDomainCapabilities` set.
- `lib/features/templates/widgets/template_card.dart` — remove the `isAdmin` boolean prop; replace with direct `PolicyManager` lookups for `submissionsCreate`, `templatesUpdate`, and `templatesDelete` separately.
- `lib/features/templates/pages/template_list_page.dart` — remove the `isAdmin` local variable and the boolean passed into `TemplateCard`.

**Out of Scope (YAGNI):**
- No backend changes. No database migrations. No new API endpoints.
- Programs module UI — the Flutter screens for programs do not yet exist. We add the constants now so they are ready, but we do NOT add UI guards to pages that don't exist yet.
- Analytics UI — the capability string `analytics:view` is added to constants, but no UI patch is needed (analytics pages already use `analytics:admin` which works).

---

## System Context

- **Architecture:** Offline-first Flutter. Capabilities are loaded from `AuthManager` into memory on login. No network call is needed at the point of checking `PolicyManager.can(...)`.
- **RBAC Gate:** `PolicyManager.can(String capability)` is the single enforcement tool. `PermissionGuard` widget wraps it for the widget tree.
- **Logs:** No logging changes required.

---

## Lifecycle Context (4-State Matrix)

These changes do not affect Loading, Empty, or Error states. They only affect the **Success** state — specifically which buttons are rendered inside a successfully-loaded widget tree.

| State | Effect of This Change |
|---|---|
| Loading | No change |
| Empty | No change |
| Error | No change |
| Success | Fewer buttons are rendered for restricted roles. The "Quick Start" menu item disappears for roles without `submissions:create`. Template "Edit" and "Delete" items respect their specific capabilities independently. |

---

## Test Contracts

> **Testing Route:** Route 2 (Direct Build / Visual). No logic math is being changed. Only widget rendering conditions change. Manual verification by switching user roles is the correct gate.

| ID | Test Scenario | Expected Result | Why it fails before fix |
|---|---|---|---|
| TC-01 | Log in as a role with `submissions:create` = false. Navigate to Templates page, open the `...` menu on any card. | "Quick Start" menu item is NOT visible. | Currently visible to everyone regardless of capability. |
| TC-02 | Log in as a role with `submissions:create` = true. Navigate to Templates page, open the `...` menu on any card. | "Quick Start" is visible. | Correct behavior confirmed. |
| TC-03 | Log in as a role with `templates:update` = false but `templates:create` = true. Open `...` menu. | "Edit" and "Duplicate" are NOT visible. | Currently all 3 options appear if `templatesCreate` is true. |
| TC-04 | Log in as a role with `templates:delete` = false but `templates:create` = true. Open `...` menu. | "Delete" is NOT visible. | Currently all 3 options appear if `templatesCreate` is true. |
| TC-05 | Check `AppCapabilities.dart` in Flutter has same count as `AppCapabilities.cs` on backend. | Both have 18 constants (excluding the `adminDomainCapabilities` set). | Flutter currently has 11. |

---

## Tools & Commands

- **Skills needed:** None (pure UI changes, no architecture skill needed).
- **Verification command:** `cmd /c rtk flutter analyze lib/_shared/constants/app_capabilities.dart lib/features/templates/widgets/template_card.dart lib/features/templates/pages/template_list_page.dart`
- **Build check:** `cmd /c rtk flutter build apk --debug` (confirms no compile errors).
- **Manual test:** Run the app and log in with a restricted role account.

---

## Proposed Changes

| Change | File | Type |
|---|---|---|
| Add 8 missing constants + update adminDomainCapabilities | `lib/_shared/constants/app_capabilities.dart` | [MOD] |
| Replace `isAdmin` prop with direct `PolicyManager.can()` per capability | `lib/features/templates/widgets/template_card.dart` | [MOD] |
| Remove `isAdmin` local variable and prop passed to TemplateCard | `lib/features/templates/pages/template_list_page.dart` | [MOD] |

**Total blast radius: 3 files, ~30 lines changed. Complexity: LOW.**

---

## Concept Diagram

```
Before fix:
[Template Card] --> isAdmin? (templatesCreate) --YES--> [Show Edit, Duplicate, Delete, Quick Start]
                                                --NO --> [Show Quick Start only] ← STILL A LEAK

After fix:
[Template Card] --> PolicyManager.can(submissionsCreate)?  --YES--> [Show Quick Start]
                --> PolicyManager.can(templatesUpdate)?    --YES--> [Show Edit, Duplicate]
                --> PolicyManager.can(templatesDelete)?    --YES--> [Show Delete]
```

---

## Execution Slices

### Slice 1: Sync `AppCapabilities` Constants

- **Plain English Summary:** The Flutter "list of known permissions" is 7 constants behind the backend. This slice adds all the missing ones so the compiler knows about them. Without this, we cannot guard any new programs or admin buttons — we'd have to use naked strings.
- **Why this step now?** Every other fix depends on these constants existing. This must be Slice 1.
- **Scenario Focus:** Basic Scenario (foundational).
- **Value Delivered:** Dart compiler will catch future typos in permission strings. New `programs:*` and `global_risks:manage` capabilities are ready for use.
- **Entry State Required:** `app_capabilities.dart` exists and compiles cleanly.
- **Exit State Guaranteed:** `app_capabilities.dart` contains all 18 constants from the backend `AppCapabilities.cs`, and `adminDomainCapabilities` includes `globalRisksManage`.
- **Architectural Scope:** One file — `lib/_shared/constants/app_capabilities.dart`.
- **Complexity:** Low. Adding 8 string constants.
- **Acceptance Criteria:**
  - `programsList`, `programsExecute`, `programsManage`, `programsReview`, `programsAssignmentsMy`, `programsAssignmentsList`, `globalRisksManage`, and `analyticsView` constants exist.
  - `adminDomainCapabilities` set includes `globalRisksManage`.
  - `flutter analyze` returns no new warnings.

---

### Slice 2: Decouple `TemplateCard` from `isAdmin` Prop + Patch "Quick Start" Leak

- **Plain English Summary:** The Template card currently gets a single yes/no flag called `isAdmin` from its parent. This is too coarse — it either shows ALL actions (Edit, Duplicate, Delete, Quick Start) or none. This slice replaces that blunt flag with 3 separate, accurate permission checks directly inside the card. It also adds the missing `submissions:create` guard to the "Quick Start" button.
- **Why this step now?** Slice 1 must be complete so the new constants exist to reference.
- **Scenario Focus:** Basic Scenario — closing the active leaks.
- **Value Delivered:** A user with "view templates" permission but no "create submission" permission will no longer see "Quick Start". A user with "create templates" but no "delete templates" will no longer see "Delete".
- **Entry State Required:** Slice 1 is complete. `AppCapabilities.submissionsCreate`, `templatesUpdate`, and `templatesDelete` all exist as constants.
- **Exit State Guaranteed:** `TemplateCard` has no `isAdmin` prop. It resolves its own permissions. The popup menu renders only items the current user has capability for.
- **Architectural Scope:**
  - `lib/features/templates/widgets/template_card.dart` — remove `isAdmin` field, inject `PolicyManager` from `GetIt`.
  - `lib/features/templates/pages/template_list_page.dart` — remove `isAdmin` local variable and the named prop in `TemplateCard(template: t, isAdmin: isAdmin)`.
- **Complexity:** Low-Medium. No logic change — only changing *where* the policy check lives.
- **Pros/Cons:**

| Option | Pros | Cons |
|---|---|---|
| **A (Chosen): PolicyManager direct in TemplateCard** | Card is self-contained. No prop drilling. Clean. | Adds a `GetIt` call inside a widget. |
| B: Pass 3 booleans as props | Explicit, testable via constructor. | More props to maintain. Caller must know which caps to pass. |

**→ Option A is correct. The project already uses this pattern in `submission_row.dart` (line 268) and `history_list_view.dart` (line 40).**

- **Acceptance Criteria:**
  - TC-01: Restricted role cannot see "Quick Start".
  - TC-02: Permitted role can see "Quick Start".
  - TC-03: Role with `templatesCreate` but not `templatesUpdate` cannot see "Edit" or "Duplicate".
  - TC-04: Role with `templatesCreate` but not `templatesDelete` cannot see "Delete".
  - `flutter analyze` returns no warnings.
  - `TemplateCard` constructor no longer has an `isAdmin` parameter.

---

## Strict Implementation Constraints & Human Reminders

- **DO NOT** add logic inside `TemplateCard`'s `onSelected` action handler. The `if (isAdmin)` guard inside `case 'edit'`, `case 'duplicate'`, `case 'delete'` is now redundant — remove it. If the menu item is not shown, the action is never triggered.
- **DO NOT** modify the `adminDomainCapabilities` Set to include the new programs capabilities. They are store-manager/area-manager scope, not admin-domain.
- **DO NOT** change the router (`app_router.dart`). Route guards are not affected.
- **MATCH** the existing `PolicyManager` injection pattern: `final _di = GetIt.instance; ... _di<PolicyManager>().can(AppCapabilities.xxx)`.

---

<command_logs>
- grep_search: `app_capabilities.dart` — confirmed 11 constants, 42 lines.
- view_file: `AppCapabilities.cs` — confirmed 18 constants.
- grep_search: `isAdmin` in `lib/features/templates` — confirmed coupling in `template_card.dart` and `template_list_page.dart`.
- grep_search: `PolicyManager` in `lib/` — confirmed pattern used in `submission_row.dart`, `history_list_view.dart`, `history_page.dart`.
- grep_search: `global_risks` in server — confirmed `global_risks:manage` seeded for admin in `Program.cs` line 329.
</command_logs>

---

## Handoff Block

**Summary for next agent:**
Fix the PBAC UI enforcement in Flutter. 2 slices, 3 files, no backend changes.

**Slice 1 — Constants sync (no dependencies):**
> @[/implement] Execute build for Slice 1 (Sync AppCapabilities Constants): `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-ui-fix\implementation_plan_20260509_190140_493220d8_pbac-ui-fix.md`

**Slice 2 — UI patch (wait for Slice 1 to finish first):**
> @[/implement] Execute build for Slice 2 (Decouple TemplateCard + Patch Quick Start): `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-ui-fix\implementation_plan_20260509_190140_493220d8_pbac-ui-fix.md`

**Concurrency:** Run Slice 2 only AFTER Slice 1 is verified by `flutter analyze`.
