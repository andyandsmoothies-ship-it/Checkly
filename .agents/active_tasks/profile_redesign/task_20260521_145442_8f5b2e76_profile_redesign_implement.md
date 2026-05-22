# Task: Profile Page Redesign — Implementation
Workflow: /implement | Track: A (Direct Implementation)

## Input Lineage
- **ADR**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\profile_redesign\decision_record_20260521_132954_e9416519_profile_redesign.md`
- **V2 Research**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_112140_c4f8a203_profile_redesign_v2.md`
- **UX Eval**: `C:\Users\HP\.gemini\antigravity\brain\e9416519-66e9-4247-9c80-313989293476\ux_heuristic_eval_profile_redesign.md`

## Upfront
- [x] Pre-Requisite: Implementation Plan (ADR + V2 research)
- [x] Pre-Requisite: Existing tests audited (3 tests in app_router_test.dart go RED after Slice 1)

## UX Fixes Applied
- [x] H2 (Jargon): ProfileCapabilitiesSection already uses CapabilityDictionary.getLabel() — no code change needed
- [x] H10 (Dead ends): Remove Documentation + Help tiles from Settings zone (approved)
- [x] H1 (Offline): Avatar initials fallback implemented in ProfileIdentityCard

## Slices

- [x] Slice 1: `shell_tab.dart` — Remove TEMPLATES tab + add `/templates`+`/admin` → PROFILE fallback
       `test/_shared/router/app_router_test.dart` — Update 3 failing tests
- [x] Slice 2: `profile_header.dart` → Upgrade to `ProfileIdentityCard` (102 lines)
- [x] Slice 3: `settings_section_group.dart` — Add `String? sectionLabel` param
- [x] Slice 4: NEW `lib/features/profile/widgets/admin_command_card.dart` (89 lines)
- [x] Slice 5: NEW `lib/features/profile/widgets/profile_workspace_section.dart` (142 lines)
- [x] Slice 6: `profile_page.dart` — 5-zone rebuild (158 lines)
       `test/features/profile/pages/profile_page_test.dart` — 4 contracts updated to match ADR (9/9 GREEN)

## Wrap Up
- [x] Phase 2: Self-Review (flutter analyze ZERO issues, arch boundaries clean, all files < 400 lines, no orphan stubs)
- [x] Phase 3: Handoff (global flutter test exit code 0, walkthrough written, verify_workflow.py pending)

## Artifacts
| Status | File Path | Type |
|---|---|---|
| [DONE] | `.agents/active_tasks/profile_redesign/task_20260521_145442_8f5b2e76_profile_redesign_implement.md` | Task |
| [DONE] | `.agents/active_tasks/profile_redesign/walkthrough_20260521_151700_8f5b2e76_profile_redesign_implement.md` | Result |
