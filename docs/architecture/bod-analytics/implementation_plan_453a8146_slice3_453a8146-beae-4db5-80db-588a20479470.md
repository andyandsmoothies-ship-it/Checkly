<latent_space_scratchpad>
- Layout Safety is paramount: infinite height list views within `Column` inside a bottom sheet will crash the UI.
- Use `Flexible` or `Expanded` around list views with proper constraints or use `shrinkWrap: true` and `NeverScrollableScrollPhysics` within a scrollable column.
- The bottom sheet height is restricted to 85% of screen height (`MediaQuery.of(context).size.height * 0.85`). Ensure the outer container is wrapped in a `ConstrainedBox` matching this limit.
- Support Gotcha 34 (Reduced Motion Compliance): the `_SkeletonItem` must check `MediaQuery.disableAnimationsOf(context)` and snap without interpolation to prevent motion sickness.
- Keep the new files small and modular (<400 lines) to align with standard clean architecture rules.
</latent_space_scratchpad>

# Implementation Plan: BOD Analytics - Slice 3 New Flutter Sheets

**Workflow:** /analyze-feature | **ShortID:** 453a8146 | **ConversationID:** 453a8146-beae-4db5-80db-588a20479470
**Date:** 2026-05-25T11:58:00+07:00

---

## Input Lineage

**Source Requirements:** `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\analysis_epic_20260525_105400_453a8146_bod_drilldown_453a8146-beae-4db5-80db-588a20479470.md` (Slice 3 functional definitions).

---

## Executive Summary & Out of Scope

Slice 3 builds the two new modal bottom sheets: `BodStoreDetailSheet` and `BodCategoryDetailSheet`. These sheets display rich, pre-computed analytical detail metrics for stores and categories respectively.

### Out of Scope:
- Gestures or routing links in dashboard cards to trigger opening these sheets (Slice 4).
- Server-side modifications or DTO changes (Slice 1).
- Overdue action plan lookup modification (Slice 2).

---

## System Context

- **APIs Consumed**:
  - `loadStoreDetail(storeId)` from `BodAnalyticsManager`
  - `loadCategoryDetail(categoryName)` from `BodAnalyticsManager`
- **Widgets Integrated**:
  - Uses existing design primitives: `StrokeCard`, `UniversalListCard`, and `PillChip`.
- **Dependency Injection**: Standard `BodAnalyticsManager` instance is passed down explicitly, and its reactive states are observed via `AnimatedBuilder`.

---

## Lifecycle Context

4-State Matrix for `BodStoreDetailSheet` and `BodCategoryDetailSheet`:
- **Success**: Displays populated data.
- **Loading**: Renders animated `_SkeletonItem` lists conforming to reduced motion settings.
- **Error**: Shows an error banner or fallback text description.
- **Empty**:
  - For store: Shows empty banner "No audit history available".
  - For category: Shows empty banner "No store data for this category".

---

## Constraint Traceability

| Source Constraint | Target Test ID | Verification Method |
|---|---|---|
| Sheet height ≤ 85% of screen height | C3-TEST-08 | Widget test checks constraints on outer container |
| Shows live data timestamp note | C3-TEST-03 | Search for text containing "Live data as of" |
| Respects reduced motion compliance | C3-TEST-02 | Widget test with `disableAnimationsOf(context) == true` |
| Store detail empty state handled | C3-TEST-04 | Mock manager with empty store list -> verify empty text |
| Store detail data loads audits correctly | C3-TEST-03 | Mock manager with 2 audits -> verify lists exist |
| Category detail empty state handled | C3-TEST-07 | Mock manager with empty category -> verify empty text |
| Category detail sorted ASC with score | C3-TEST-06 | Verify score progress bar renders ASC values |

---

## Test Contracts

### C3-TEST-01: Store Detail Mount & Loader Initiation
- **Description**: Verifies that mounting `BodStoreDetailSheet` fires the correct manager command.
- **Assertion**: When sheet is built with `storeId="s-1"`, verify mock manager `loadStoreDetail("s-1")` is called exactly once.

### C3-TEST-02: Skeleton Shimmer & Motion Compliance
- **Description**: Verifies that skeleton loading is shown and honors reduced motion setting.
- **Assertion**: When manager `isStoreDetailLoading` is true:
  - If `MediaQuery.disableAnimationsOf(context)` is true -> animation controller does not repeat/animate.
  - Renders skeleton layout cleanly.

### C3-TEST-03: Store Detail Success Rendering
- **Description**: Verifies UI formatting when store data is returned.
- **Assertion**: Displays "Live data as of [timestamp]" caption. Displays store name header. Displays universal list card for each audit history item with correct score.

### C3-TEST-04: Store Detail Empty State
- **Description**: Verifies store has no completed audits.
- **Assertion**: When `storeDetail.recentAudits` is empty list, verify "No audit history available" empty state text is rendered.

### C3-TEST-05: Category Detail Mount & Loader Initiation
- **Description**: Verifies that mounting `BodCategoryDetailSheet` triggers the category search.
- **Assertion**: When sheet is built with `categoryName="Food Safety"`, verify mock manager `loadCategoryDetail("Food Safety")` is called exactly once.

### C3-TEST-06: Category Detail Worst-Store Sorting
- **Description**: Verifies category data layout and scores.
- **Assertion**: Displays stores with worst scores first. Renders compliance score progress bar cleanly.

### C3-TEST-07: Category Detail Empty State
- **Description**: Verifies category has no store data.
- **Assertion**: When `categoryDetail` is empty, verify "No store data for this category" empty state text is rendered.

### C3-TEST-08: Max Height Constraint Guard
- **Description**: Verifies the sheet conforms to layout bounds.
- **Assertion**: Verify the sheet's height is constrained to `MediaQuery.of(context).size.height * 0.85`.

---

## Test Fixture & Payloads

### Mock Store Summary Payload:
```json
{
  "storeName": "Airport Express",
  "recentAudits": [
    {
      "id": "11111111-2222-3333-4444-555555555555",
      "score": 58.4,
      "completedAt": "2026-05-24T14:30:00Z"
    }
  ],
  "categoryBreakdown": [
    {
      "categoryName": "Food Safety",
      "score": 62.5
    }
  ]
}
```

---

## Tools & Commands

- **Skills**: `flutter-architecture`, `testing-strategy`, `ui-visual-validator`
- **Verification Commands**:
  - Run the newly created widget tests:
    `cmd /c rtk flutter test test/features/analytics/widgets/bod_drilldown_sheets_test.dart`

---

## Proposed Changes

### 1. `lib/features/analytics/widgets/bod_store_detail_sheet.dart` [NEW]
- Statefully trigger `manager.loadStoreDetail(storeId)` inside `initState`.
- Wrap outer container in `ConstrainedBox` with `BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85)`.
- Use `AnimatedBuilder` to rebuild dynamically when manager triggers changes.
- Implement animated `_SkeletonItem` conforming to reduced motion checks.
- Render header with `"Live data as of ${DateTime.now().toLocal()}"`.
- Render the list of `recentAudits` using `UniversalListCard`.
- Render category weaknesses list showing scores.

### 2. `lib/features/analytics/widgets/bod_category_detail_sheet.dart` [NEW]
- Statefully trigger `manager.loadCategoryDetail(categoryName)` inside `initState`.
- Wrap outer container in `ConstrainedBox` with `BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85)`.
- Use `AnimatedBuilder` to rebuild dynamically.
- Implement animated `_SkeletonItem` conforming to reduced motion checks.
- Render header with `"Live data as of ${DateTime.now().toLocal()}"`.
- Render worst-performing stores sorted ASC with progress bars representing average category section scores.

### 3. `test/features/analytics/widgets/bod_drilldown_sheets_test.dart` [NEW]
- Implement comprehensive widget tests asserting `C3-TEST-01` through `C3-TEST-08` using `mocktail` and `testWidgets`.

---

## Concept Diagram

```
[BOD Dashboard Card Tap] ──► showModalBottomSheet() 
                                   │
         ┌─────────────────────────┴─────────────────────────┐
         ▼                                                   ▼
 [BodStoreDetailSheet]                              [BodCategoryDetailSheet]
   ├─► OnInit: loadStoreDetail()                      ├─► OnInit: loadCategoryDetail()
   ├─► Shimmer / Skeleton Loading                     ├─► Shimmer / Skeleton Loading
   ├─► 85% Height Constraint Box                      ├─► 85% Height Constraint Box
   ├─► "Live data as of [timestamp]"                  ├─► "Live data as of [timestamp]"
   └─► Renders Audits List & Category Weakness         └─► Renders Store Compliance Progress Bars
```

---

## Execution Slices

### Slice 1: Store Detail Bottom Sheet
- **Summary**: Build `BodStoreDetailSheet` mapping `StoreBodSummary` response structures.
- **Value**: Renders deep historical audit metrics and section weaknesses for any selected retail store.
- **Entry State**: Slice 2 builds cleanly.
- **Exit State**: Store detail sheet compiled successfully.
- **Scope**: `lib/features/analytics/widgets/bod_store_detail_sheet.dart` (1 file).

### Slice 2: Category Detail Bottom Sheet
- **Summary**: Build `BodCategoryDetailSheet` mapping worst-performing stores.
- **Value**: Visualizes which stores represent compliance liabilities for a selected category section.
- **Entry State**: Slice 1 builds cleanly.
- **Exit State**: Category detail sheet compiled successfully.
- **Scope**: `lib/features/analytics/widgets/bod_category_detail_sheet.dart` (1 file).

### Slice 3: Sheet Widget Test Suite
- **Summary**: Implement comprehensive widget/sheet tests validating all test contracts under mock manager settings.
- **Value**: Guarantees visual resilience, motion compliance, and proper lifecycle mappings.
- **Entry State**: Slices 1 and 2 build cleanly.
- **Exit State**: Complete unit test suite runs and passes cleanly.
- **Scope**: `test/features/analytics/widgets/bod_drilldown_sheets_test.dart` (1 file).

---

## Handoff Block

- **Implementation Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\implementation_plan_453a8146_slice3_453a8146-beae-4db5-80db-588a20479470.md`

### Action Sequence:
- **Slice 1**: Plan -> Build -> Test
  - Target: Execute Route 1 (Direct Build) since this covers pure UI/Visual components rendering manager reactive states. Build the sheets first, then build the widget test suite to verify.

**Please execute slices ONE AT A TIME.** Do not combine slices.
