# Implementation Plan - UI Decomposition & Method Size Reductions

- **Epic/Feature**: UI Cleanliness & Modularity Sweep
- **Conversation ID**: `eff00973-14e1-4499-8eb8-460c7cb83703`
- **Date**: 2026-06-02

---

## 1. Architectural Structure

```
[SystemLogsPage]
   |
   +---> [DropdownFilterPill] (Shared in widgets/)
   +---> [LogLevelFilterSheet] (Extracted widget)
   +---> [LogDateFilterSheet] (Extracted widget)

[UserManagementPage]
   |
   +---> [DropdownFilterPill] (Shared in widgets/)
   +---> [UserRoleFilterSheet] (Extracted widget)

[BodKpiGrid]
   |
   +---> Rows of [BodKpiCard] (Extracted to widgets/bod_kpi_card.dart)

[ReviewValidationBanner] ---> Maps errors to list of [_ValidationErrorTile]
[ReviewQualityBanner]    ---> Returns [_QualityValidBanner] or [_QualityWarningBanner]

[TemplateManager]
   |
   +---> loadTemplateTree() -> Calls [_updateDriftCache()] (Extracted method)
```

---

## 2. Failure Mode & Flop-Catcher Analysis

Before implementing, we identify two potential edge-case failures:

1. **State Inconsistency on Filter Callback**: If a bottom sheet tries to change the state of a parent page and the context is no longer mounted (e.g., the user navigated away), calling callbacks could trigger exceptions.
   - *Mitigation*: Ensure parent widget callbacks are safely invoked using proper lifecycle checks.
2. **Missing Token-Driven Style Inheritances**: When UI cards are extracted, they must retain their dependencies on design system tokens (`ChecklyThemeTokens`) and verify the theme extension fallback values are safe to avoid widget test crashes.
   - *Mitigation*: Properly import custom primitives (like `StrokeCard` and `PillChip`) and assert default parameters.

---

## 3. Detailed Modularity Strategy

### Step 1: Create Shared `DropdownFilterPill`
- **Target File**: `lib/features/admin/pages/widgets/dropdown_filter_pill.dart`
- **Content**: Move the duplicate `DropdownFilterPill` widget here.
- **Reference**: Clean up imports and remove duplicate definitions from `system_logs_page.dart` and `user_management_page.dart`.

### Step 2: Extract bottom sheets from `system_logs_page.dart`
- **LogLevelFilterSheet File**: `lib/features/admin/pages/widgets/log_level_filter_sheet.dart` containing `showLogLevelFilterSheet`.
- **LogDateFilterSheet File**: `lib/features/admin/pages/widgets/log_date_filter_sheet.dart` containing `showLogDateFilterSheet`.

### Step 3: Extract bottom sheet from `user_management_page.dart`
- **UserRoleFilterSheet File**: `lib/features/admin/pages/widgets/user_role_filter_sheet.dart` containing `showUserRoleFilterSheet`.

### Step 4: Refactor `bod_kpi_grid.dart`
- **BodKpiCard File**: `lib/features/analytics/widgets/bod_kpi_card.dart` containing `BodKpiCard` extracted from `_buildKpiCard`.
- **Refactoring**: Update `BodKpiGrid` to render rows of `BodKpiCard` widgets, keeping the `build` method under 30 lines.

### Step 5: Refactor `review_banners.dart`
- **Refactoring**: Extract sub-components `_ValidationErrorTile`, `_QualityValidBanner`, and `_QualityWarningBanner` as private stateless widgets inside the same file to keep their build methods under 30 lines.

### Step 6: Refactor `template_manager.dart`
- **Refactoring**: Extract Drift cache updating inside `loadTemplateTree` into a private helper method `_updateDriftCache`, bringing the primary method size under 30 lines.

---

## 4. Verification Flow

We will run the following checks synchronously:
1. `rtk flutter test` (verifies full widget and unit testing suite).
2. UI verification if needed.
