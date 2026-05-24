<latent_space_scratchpad>
HARD CONSTRAINTS from GEMINI files:
1. templates/GEMINI.md Gotcha T-01: CriterionRow in templates/pages/widgets MUST NOT be merged with audit/widgets CriterionRow. DO NOT touch inner criterion content.
2. audit/GEMINI.md Gotcha 13: AuditSectionCard renders ONE section at a time via setState. Do not change this swap-render pattern.

FINDINGS — three categories of remaining inconsistency:

CATEGORY A: TypeSection (HIGH PRIORITY - exact same bug as deleted store_group)
- File: lib/features/templates/widgets/type_section.dart
- Problem: Hardcodes raw TextStyle(fontFamily: 'Nunito', color: AppColors.wolf...) and a
  manual green Container badge — identical code to the deleted action_plans/store_group.dart
- Fix: Replace with UniversalStoreGroup (already created!) — it is the EXACT right primitive

CATEGORY B: Programs module — list items NOT using UniversalListCard
- Files: program_list_page.dart, area_campaign_list_page.dart, program_assignment_list_page.dart
- Problem: Use StrokeCard + ListTile/Column inline, no standardization. Different leading icons
  (circle container vs Icon), different typography, different empty states (raw Center Text).
- Fix: Migrate to UniversalListCard. Empty states to ChecklyEmptyState.

CATEGORY C: AuditSectionCard vs SectionCard header styling
- AuditSectionCard: uses Material Card + theme.textTheme.titleMedium (default typography)
- SectionCard: uses Container with custom border + AppFonts.displayStyle (gamified typography)
- CONSTRAINT from GEMINI: Cannot merge inner content. But we CAN unify the header tile styling.
- Decision: Unify the header styling only. Both should use AppFonts.displayStyle for the title.
  This is a low-risk targeted edit, not a structural merge.

SKIP — SectionEditor: This is an admin/editor-facing tool. It has complex validation state
and error highlighting logic embedded in its tile. Touching it risks breaking the template
builder's error highlighting. YAGNI — skip until user explicitly asks.

SKIP — profile_capabilities_section.dart ExpansionTile: This is a standalone non-grouped list,
not a store-group pattern. Its styling is acceptable as-is.

SKIP — review_banners.dart TypeSection: review_banners uses ExpansionTile for banners,
not for grouping items. Different semantic purpose.
</latent_space_scratchpad>

## Input Lineage
- c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260522_224900_uxe3_group_headers.md
- c:\Users\HP\Documents\GitHub\Checkly\lib\features\templates\GEMINI.md (Gotcha T-01 constraint)
- c:\Users\HP\Documents\GitHub\Checkly\lib\features\audit\GEMINI.md (Gotcha 13 constraint)

## Executive Summary & Out of Scope

After a full codebase sweep, three categories of remaining visual inconsistency were found after the `UniversalListCard` and `UniversalStoreGroup` migrations.

**In Scope:**
1. **`TypeSection` group header** (`templates/widgets/type_section.dart`) — hardcoded raw `TextStyle` and custom badge; identical to the already-deleted `action_plans/store_group.dart`. Fix: swap to `UniversalStoreGroup`.
2. **Programs module list cards** (`program_list_page.dart`, `area_campaign_list_page.dart`, `program_assignment_list_page.dart`) — inline `StrokeCard + ListTile` patterns, not using `UniversalListCard`. Empty states use raw `Center(Text(...))`, not `ChecklyEmptyState`.
3. **`AuditSectionCard` title typography** — uses default `theme.textTheme.titleMedium`. The matching `SectionCard` uses gamified `AppFonts.displayStyle`. Fix: apply `AppFonts.displayStyle` to `AuditSectionCard`'s title only — NOT its score/weight badge logic.

**Hard Out of Scope (GEMINI rule blocks):**
- `templates/GEMINI.md` Gotcha T-01: `CriterionRow` inner content **MUST NOT** be merged between template/audit. Do not touch.
- `audit/GEMINI.md` Gotcha 13: `AuditSectionCard`'s single-section swap-render pattern **MUST NOT** be changed. Do not touch the rendering logic.
- `SectionEditor`: Admin editor with complex validation error state. YAGNI — skip.
- `ProfileCapabilitiesSection` ExpansionTile: Different semantic purpose (roles/capabilities display), not a store-group pattern.

## System Context
- **Offline/Online**: UI-only, N/A.
- **APIs**: N/A.
- **RBAC**: N/A.
- **Logs**: N/A.

## Lifecycle Context
- **Success**: Cards render with unified typography, standardized leading icons, and `ChecklyEmptyState` empty states.
- **Error**: Programs pages show `ChecklyEmptyState` with emoji + retry button.
- **Empty**: Programs pages show `ChecklyEmptyState` with friendly message.
- **Loading**: Existing `CircularProgressIndicator` unchanged.

## Constraint Traceability
| Constraint | Source | Test Contract ID |
| --- | --- | --- |
| CriterionRow inner content must NOT be merged across template/audit | templates/GEMINI.md T-01 | Out of scope — enforced by plan boundary |
| AuditSectionCard swap-render pattern must NOT be changed | audit/GEMINI.md Gotcha 13 | Out of scope — enforced by plan boundary |
| TypeSection must use UniversalStoreGroup | Diagnosis report | AP-UX-01 |
| Programs cards must use UniversalListCard | Audit sweep | AP-UX-02 |
| Programs empty states must use ChecklyEmptyState | Audit sweep | AP-UX-03 |
| AuditSectionCard title must use AppFonts.displayStyle | Visual parity | AP-UX-04 |

## Test Contracts
| ID | Contract | Why it fails first |
| --- | --- | --- |
| AP-UX-01 | `TypeSection` must not contain any hardcoded `TextStyle` or manual badge `Container` | Still has raw `TextStyle(fontFamily: 'Nunito', ...)` |
| AP-UX-02 | `ProgramListPage`, `AreaCampaignListPage`, `ProgramAssignmentListPage` must use `UniversalListCard` | Currently use inline `StrokeCard + ListTile` |
| AP-UX-03 | Programs error/empty states must use `ChecklyEmptyState`, not raw `Center(Text(...))` | Currently raw `Center` widget |
| AP-UX-04 | `AuditSectionCard` title must use `AppFonts.displayStyle(fontWeight: w700)` | Currently uses `theme.textTheme.titleMedium?.copyWith(...)` |

## Test Fixture & Payloads
- Standard Flutter widget test environment. No seeds needed.

## Tools & Commands
- `flutter test`
- `flutter analyze`

## Risk Assessment
- **Risk**: Low across all three slices. All are pure widget-layer refactors.
- **Mitigation Slice 1 (TypeSection)**: `UniversalStoreGroup` is already built and tested. Simple import swap.
- **Mitigation Slice 2 (Programs)**: `UniversalListCard` is already built and tested. Programs list items need their `children` widget mapped and passed to the primitive. Empty state migration follows the exact same pattern as the 11 previously migrated components.
- **Mitigation Slice 3 (AuditSectionCard)**: Single line typography change. Must not touch the score/weight badge logic or children rendering pattern (Gotcha 13).

## Verification Plan
1. `flutter analyze` — 0 issues.
2. `flutter test` — all tests pass.
3. Manually verify: `TypeSection` group header in the Template Builder matches the Audit/Action Plans group header style.
4. Manually verify: Programs list items use the same card anatomy (leading icon slot, title, subtitle, trailing).
5. Manually verify: Active Audit section title font weight matches Template Preview section title.

## Proposed Changes
| Action | File | Slice |
| --- | --- | --- |
| `[MOD]` | `lib/features/templates/widgets/type_section.dart` | 1 |
| `[MOD]` | `lib/features/programs/pages/program_list_page.dart` | 2 |
| `[MOD]` | `lib/features/programs/pages/area_campaign_list_page.dart` | 2 |
| `[MOD]` | `lib/features/programs/pages/program_assignment_list_page.dart` | 2 |
| `[MOD]` | `lib/features/audit/widgets/audit_section_card.dart` | 3 |

### UI Component Map
| Component | Truncation | Overflow | Route |
| --- | --- | --- | --- |
| `TypeSection` title | 1 line | Ellipsis | N/A |
| `ProgramListPage` item title | 1 line | Ellipsis | `/programs/review/{id}` |
| `AreaCampaignListPage` item title | 1 line | Ellipsis | N/A (read-only) |
| `ProgramAssignmentListPage` item title | 1 line | Ellipsis | `/programs/{id}` |
| `AuditSectionCard` section title | 1 line | Ellipsis | N/A (in-page expansion) |

## Concept Diagram
```
TypeSection (BEFORE)          TypeSection (AFTER)
hardcoded TextStyle    →→→    UniversalStoreGroup
custom Container badge        PillChip (standard)

Programs List (BEFORE)        Programs List (AFTER)
StrokeCard + ListTile  →→→    UniversalListCard
Center(Text) empty            ChecklyEmptyState

AuditSectionCard (BEFORE)     AuditSectionCard (AFTER)
titleMedium.copyWith() →→→    AppFonts.displayStyle(w700)
[score badge UNCHANGED]       [score badge UNCHANGED]
[render logic UNCHANGED]      [render logic UNCHANGED]
```

## Execution Slices

### Slice 1: Fix TypeSection Group Header
- **Plain English**: `TypeSection` in `lib/features/templates/widgets/type_section.dart` has hardcoded raw `TextStyle` and a manual green badge — identical to the deleted `action_plans/store_group.dart`. Replace the entire widget body with `UniversalStoreGroup`.
- **Value**: Eliminates the third duplicate group header pattern.
- **Entry State**: `TypeSection` has hardcoded `TextStyle`.
- **Exit State**: `TypeSection` wraps `UniversalStoreGroup`. No raw `TextStyle` remains.
- **Scope**: 1 file.
- **Acceptance Criteria**: `type_section.dart` imports `UniversalStoreGroup`; no `TextStyle(` literal in file.
- **Complexity**: **Low**. Exact same pattern as the store_group deletions.

### Slice 2: Migrate Programs List Cards
- **Plain English**: The three Programs list pages each render `StrokeCard + ListTile` inline. Migrate them to `UniversalListCard`. Replace raw `Center(Text(...))` empty/error states with `ChecklyEmptyState`.
- **Value**: Closes the visual gap between Programs and all other list screens.
- **Entry State**: Programs pages use inline card patterns.
- **Exit State**: All three use `UniversalListCard` with correct `leadingIcon`, `title`, `subtitle`, `trailingIcon`. Error/empty states use `ChecklyEmptyState`.
- **Scope**: 3 files, ~35 lines changed each.
- **Acceptance Criteria**:
  - No `StrokeCard(child: ListTile(...))` pattern in any `programs/pages/` file.
  - No `Center(child: Text('...'))` for empty/error states in those files.
  - All three pages use `ChecklyEmptyState`.
- **Complexity**: **Low**. `UniversalListCard` is already built. The migration is mechanical.

### Slice 3: Fix AuditSectionCard Title Typography
- **Plain English**: `AuditSectionCard` uses `theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)` for its section title. Replace with `AppFonts.displayStyle(fontSize: ..., fontWeight: FontWeight.w700, ...)`. Score badges and weight badges are NOT touched.
- **Value**: When an auditor looks at a section in the Audit form, the section title font matches what they saw in the Template Preview — consistent visual language across the full workflow.
- **Entry State**: `AuditSectionCard` title uses default Material typography.
- **Exit State**: `AuditSectionCard` title uses `AppFonts.displayStyle`.
- **Scope**: 1 file, ~3 lines changed.
- **Acceptance Criteria**: `audit_section_card.dart` title text uses `AppFonts.displayStyle`. Score/weight badges unchanged. `flutter analyze` passes.
- **Complexity**: **Low**. Targeted single-line typography fix. Governed by GEMINI constraints — must not touch rendering logic.

<command_logs>
- grep_search "ExpansionTile" → lib/ (found TypeSection, SectionCard, AuditSectionCard, etc.)
- grep_search "ChecklyEmptyState" → lib/ (confirmed Programs module missing)
- grep_search "UniversalListCard" → lib/ (confirmed Programs module NOT migrated)
- grep_search "StrokeCard" → lib/ (confirmed Programs inline patterns)
- view_file type_section.dart (confirmed hardcoded TextStyle — exact bug as deleted store_group)
- view_file program_list_page.dart (confirmed StrokeCard+ListTile, raw empty state)
- view_file area_campaign_list_page.dart (confirmed pattern)
- view_file program_assignment_list_page.dart (confirmed pattern)
- view_file audit_section_card.dart (confirmed titleMedium)
- view_file audit/GEMINI.md (extracted Gotcha 13 constraint)
- view_file templates/GEMINI.md (extracted Gotcha T-01 constraint)

## Handoff Block
All three slices are pure UI refactors. Route 1: Direct Build for all.

Execute ONE AT A TIME:
- **Slice 1**: Build — fix `TypeSection` → `UniversalStoreGroup`.
- **Slice 2**: Build — migrate Programs list pages to `UniversalListCard` + `ChecklyEmptyState`.
- **Slice 3**: Build — fix `AuditSectionCard` title typography.

Absolute Path: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260522_233100_uxe5_section_card_sweep.md`
