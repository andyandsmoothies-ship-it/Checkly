# Implementation Plan - Analytics UI Decomposition & Modularity

- **Epic/Feature**: UI Cleanliness & Modularity Sweep
- **Conversation ID**: `99faccbc-6112-4ccd-aea4-306dbdfd3452`
- **Date**: 2026-06-02

---

## 1. Architectural Structure

```
[BodStoreDetailSheet]                     [AreaBodStoreDetailSheet]
   |                                         |
   +---> [RegionalBenchmarkingCard] <--------+ (Extracted widget)
   +---> [SlaOverdueActionPlansCard] <-------+ (Extracted widget)
   +---> [StoreDetailSkeleton] <-------------+ (Extracted widget)
```

Both `BodStoreDetailSheet` and `AreaBodStoreDetailSheet` contain massive UI building blocks that exceed file size and method length constraints. This plan extracts those blocks into shared, stateless widgets.

---

## 2. Failure Mode & Flop-Catcher Analysis

1. **State Inconsistency on Unmounted Contexts**: If callbacks trigger state updates after sheets are dismissed or popped, runtime exceptions will occur.
   - *Mitigation*: Ensure parent widget callbacks are safely invoked using proper lifecycle checks.
2. **Missing Design System Custom Tokens**: The extracted widgets rely on `Theme.of(context)` and `ChecklyThemeTokens` via high-contrast primitives like `StrokeCard` and `PillChip`.
   - *Mitigation*: Inherit dynamic theme parameters correctly, and provide fallbacks to prevent unit testing from failing if extensions are null.

---

## 3. Detailed Modularity Strategy

### Step 1: Create Shared `StoreDetailSkeleton`
- **Target File**: `lib/features/analytics/widgets/store_detail_skeleton.dart`
- **Content**: Moves the pulse skeleton item widget logic out of both detail sheets.
- **Benefit**: Removes redundant stateful animation controller boilerplate from both files.

### Step 2: Create Shared `RegionalBenchmarkingCard`
- **Target File**: `lib/features/analytics/widgets/regional_benchmarking_card.dart`
- **Content**: Builds the `Regional Benchmarking` card, displaying regional average differences and top/bottom quartile pill chips. Handles dark/light mode text colors dynamically.

### Step 3: Create Shared `SlaOverdueActionPlansCard`
- **Target File**: `lib/features/analytics/widgets/sla_overdue_action_plans_card.dart`
- **Content**: Builds the `SLA Overdue Action Plans` count segment row. Uses warning colors depending on bucket segments (e.g. `31+` vs `8-30` days).

### Step 4: Refactor `bod_store_detail_sheet.dart`
- **Refactoring**: Updates the sheet to use the new decomposed widgets, reducing the file size under 300 lines and keeping build methods short.

### Step 5: Refactor `area_bod_store_detail_sheet.dart`
- **Refactoring**: Updates the sheet to use the new decomposed widgets, reducing the file size under 300 lines and keeping build methods short.

---

## 4. Verification Flow

We will run the following checks synchronously:
1. `rtk flutter test` (verifies full widget and unit testing suite passes).
