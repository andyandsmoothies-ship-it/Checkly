# Implementation Plan: UI PBAC Capability Mapping

**Date:** 2026-05-10
**Epic:** UI Capability Mapping (PBAC)
**ADR Reference:** `decision_record_20260510_173420_15a74aa9_uicaps.md`

This plan details the exact files, line-level strategies, and scripts required to execute the PBAC UI hiding strategy safely. 

---

## Slice 0: Core Infrastructure & Enforcement

### 1. `[MOD]` `lib/_shared/widgets/permission_guard.dart`
**Objective:** Support `showAsDisabled` and handle the SQLite loading state so buttons don't "flash".
- **Action:** Add `final bool showAsDisabled;` to the constructor (default `false`).
- **Action:** Inside the `ValueListenableBuilder` for `AuthManager().capabilities`, check if the capabilities list is in a definitive "loaded" state. If still loading, return `const SizedBox.shrink()` (or a skeleton loader).
- **Action:** If the user lacks the capability:
  - If `showAsDisabled == false`: return `const SizedBox.shrink()`.
  - If `showAsDisabled == true`: return `Opacity(opacity: 0.5, child: IgnorePointer(child: child))`.

### 2. `[NEW]` `.agents/scripts/verify_pbac_ui.py`
**Objective:** Prevent regressions by failing the build if developers add unguarded buttons.
- **Action:** Write a Python script that traverses `lib/features/**/*.dart`.
- **Action:** Use regex to find `FloatingActionButton(` or `ElevatedButton(`.
- **Action:** Check if the preceding lines contain `PermissionGuard(`. If not, output an error with the file path and line number, and exit with code `1`.
- *Note: This script will be run by the `/verify` workflow in the future.*

---

## Slice 1: Submissions ("Tracer Bullet")

### 1. `[MOD]` `lib/features/audit/pages/audit_list_page.dart` (or equivalent Submissions root page)
**Objective:** Guard the "Start Audit" / "New Submission" Floating Action Button.
- **Action:** Locate the FAB.
- **Action:** Wrap it in `PermissionGuard(capability: AppCapabilities.submissionsCreate, showAsDisabled: true, child: ...)`. We use `showAsDisabled` here because it's the primary action of the screen.

---

## Slice 2: Shell Navigation (Dynamic Tabs)

### 1. `[MOD]` `lib/_shared/router/main_shell.dart`
**Objective:** Prevent index-out-of-bounds crashes when removing tabs.
- **Current State:** The tabs are hardcoded in a `Row`, and `currentIndex` is derived from `GoRouter`. `canViewActivity` is already dynamically hiding the "ACTIVITY" tab (`if (canViewActivity) _NavItem(...)`). But `currentIndex == 1` breaks if the tab isn't there!
- **Action:** Refactor the `children` of the `Row` to be dynamically built into a `List<_NavItem>`. 
- **Action:** Compute the `currentIndex` based on the *visible* tabs list, not the absolute index. 
- **Action:** Wrap the `TEMPLATES` tab generation with `_di<PolicyManager>().can(AppCapabilities.templatesRead)`.
- **Action:** Wrap the `PLANS` tab generation with `_di<PolicyManager>().can(AppCapabilities.programsRead)`.

---

## Slice 3: Programs & Templates

### 1. `[MOD]` `lib/features/templates/pages/template_list_page.dart`
- **Action:** Wrap the "New Template" FAB in `PermissionGuard(capability: AppCapabilities.templatesCreate, showAsDisabled: false)`.

### 2. `[MOD]` `lib/features/programs/pages/program_list_page.dart`
- **Action:** Wrap the "Create Program" FAB in `PermissionGuard(capability: AppCapabilities.programsCreate, showAsDisabled: false)`.

### 3. `[MOD]` `lib/features/programs/pages/program_assignment_page.dart` (or similar)
- **Action:** Ensure the dropdown for "Assign Auditor" calls a backend endpoint that supports filtering (e.g., `PolicyApiService.getEligibleAuditors()`) rather than fetching all users and filtering locally. 
- *Note: If the backend endpoint does not exist yet, the Builder must halt and report this as a blocked dependency.*

---

## Handoff to Builder
> **Builder Instructions:** Execute **Slice 0** and **Slice 1** ONLY, then yield back to the user to visually verify the "Tracer Bullet" works in the emulator. Do not proceed to Slices 2/3/4 until S0/S1 are confirmed.
