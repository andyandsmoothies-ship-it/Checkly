# Task: Refactoring Phases 2 & 3 (Hygiene + SRP)
Workflow: /implement | Track: A (No tests required — structural cleanup only)

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\consolidated_refactoring_plan.md`

## Upfront
- [x] Pre-Requisite: Consolidated Refactoring Plan (from /audit-code)
- [x] Baseline: `flutter analyze lib/` — 0 issues confirmed

## Active Slice: Phase 2 (Hygiene) + Phase 3 (SRP)

### Step 4 (CS-1) — main_shell.dart: Deduplicate _shellIndexFromLocation
- [ ] Add `app_router.dart` import
- [ ] Delete private `_shellIndexFromLocation` function (lines 13–21)
- [ ] Update call site to use `shellIndexFromLocation` (public)

### Step 5 (CF-6) — template_builder_page_logic.dart: Delete empty addPostFrameCallback
- [ ] Delete the empty `addPostFrameCallback` block in `_addSection()` (lines 311-313)

### Step 6 (CS-3) — sync_api_adapter.dart: Document pullDeltas() stub
- [ ] Add explicit doc comment explaining it is a synthetic stub

### Step 7 (CF-3) — schedule_audit_page.dart: Extract ScheduleAuditForm widget
- [ ] Create `lib/features/admin/widgets/schedule_audit_form.dart`
- [ ] Move `ScheduleAuditForm` + `_ScheduleAuditFormState` classes to new file
- [ ] Add import to `schedule_audit_page.dart`
- [ ] Verify schedule_audit_page.dart stays under 400 lines

### Step 8 (CF-4) — template_builder_page_logic.dart: Flatten validateGroups closure
- [ ] Extract `validateGroups` closure into a private static method
- [ ] Update call site inside `_validate()`

### Verify
- [ ] `rtk flutter analyze lib/` — 0 issues

## Wrap Up
- [ ] Phase 2: Self-Review
- [ ] Phase 3: Handoff -> Terminate session

## Artifact Inventory
| Status | File Path | Type |
|---|---|---|
| [NEW] | .agents/active_tasks/refactoring_hygiene_srp/walkthrough_20260503_123500_baca184a_refactoring_hygiene_srp.md | Result |
