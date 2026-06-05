---
ConversationID: 43a6d3be-90b3-4a93-b845-d4413b14705f
---

# Code Audit Report: Line Count & Modularity Optimization

[C# Endpoint / Flutter UI] --> [Modularity Sweep] --> [Extracted Sub-components / Shared DTOs]

This report presents findings from an on-demand codebase analysis of Checkly, specifically targeting file size thresholds, monolithic method footprints, and architectural modularity to reduce the total line count and improve maintainability.

---

## Executive Summary

The Checkly codebase has very high engineering hygiene:
- **0 compiler warnings** on the C# backend (`dotnet build`).
- **0 analysis issues** on the Flutter frontend (`flutter analyze`).
- **0 stale `TODO` or `FIXME` comments** in both projects.
- **0 hardcoded credentials/secrets** detected in safety scans.

However, several files and methods violate the strict size limits (max 400 lines per file, max 150 lines per method). To reduce overall line count and keep files simple, we can decompose monolithic widget build paths and extract data contracts (DTOs) from handler classes.

---

## Severity Matrix

| Severity | Category | File / Component | Issue Description |
| :--- | :--- | :--- | :--- |
| `🔴 Critical` | File Size | `program_dashboard_page.dart` (455 lines) | Exceeds the 400-line threshold due to inline helper widgets. |
| `🔴 Critical` | File Size | `GetAreaBodReport.cs` (451 lines) | Exceeds the 400-line threshold due to inline DTO records. |
| `🔴 Critical` | File Size | `audit_form_page.dart` (433 lines) | Exceeds the 400-line threshold due to long nested build logic. |
| `🔴 Critical` | File Size | `GetBodReport.cs` (429 lines) | Exceeds the 400-line threshold due to inline query projections. |
| `🔴 Critical` | File Size | `BodReportCalculator.cs` (428 lines) | Exceeds 400-line limit; holds 6 distinct database reports. |
| `🔴 Critical` | Method Size | `store_form_body.dart` (`build` method: 280 lines) | Violates the 150-line method limit; extremely deep layout tree. |
| `🔴 Critical` | Method Size | `read_only_criterion_row.dart` (`_isScored`: 261 lines) | Contains overly complex inline layout/conditional logic. |
| `🟡 Warning` | File Size | `SaveTemplateTree.cs` (386 lines) | Approaching 400 lines (currently 386 lines). |
| `🟡 Warning` | File Size | `CreateSubmission.cs` (385 lines) | Approaching 400 lines (currently 385 lines). |
| `🟢 Optimization` | Modularity | `GetAreaBodReport.cs` | DTO structures are declared inline rather than segregated. |

---

## Proposed Refactoring Opportunities & Actionable Fixes

Below are specific refactoring packages to optimize lines of code (LOC) and split large classes.

### 1. C# Feature Cleanups (DTO & SQL Projection Extraction)

#### [MODIFY] [GetAreaBodReport.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/GetAreaBodReport.cs)
- **Problem**: 60 lines are dedicated to inline DTO record declarations (`AreaBodResponse`, `AreaBodKpiDto`, etc.).
- **Action**: Extract these records to a new file `AreaBodReportDtos.cs` within the same folder.
- **Complexity**: **Low**. Involves moving plain-old C# records without touching execution logic.
- **Pros**: Brings `GetAreaBodReport.cs` down to ~392 lines (under the 400-line limit), aligning it with the pattern established by `BodReportDtos.cs` for the global report.
- **Cons**: Adds a new DTO file to the directory.

#### [MODIFY] [GetBodReport.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/GetBodReport.cs) & [BodReportCalculator.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/BodReportCalculator.cs)
- **Problem**: Both files execute long, multi-stage database aggregations inline, making them exceed 420 lines.
- **Action**:
  1. Extract common SQL query helper expressions (e.g. active store filtering and completed submissions filters) into a shared database extension class or query specification.
  2. Split `BodReportCalculator.cs`'s long calculations into structured private helper methods for each distinct report block (KPIs, Trend, Store Ranking, Category Weaknesses, Aging, Productivity).
- **Complexity**: **Medium**. Requires careful preservation of EF Core tracking configurations and async query cancellation tokens.
- **Pros**: Reduces the massive length of `ComputeDailyReportWithTimezoneAsync` (currently ~395 lines) down to short, testable segments.
- **Cons**: Requires running regression integration tests to confirm the output SQL queries don't change behavior.

---

### 2. Flutter UI Component Decomposition

#### [MODIFY] [program_dashboard_page.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/programs/pages/program_dashboard_page.dart)
- **Problem**: The file contains three distinct UI definitions: the page state layout, `DropdownFilterPill`, and the `showProgramAssignmentStatusFilterSheet` modal dialog.
- **Action**: Extract `DropdownFilterPill` and `showProgramAssignmentStatusFilterSheet` into a separate file under the `widgets` directory: `lib/features/programs/pages/widgets/program_dashboard_widgets.dart`.
- **Complexity**: **Low**. Pure widget extraction.
- **Pros**: Cuts page size by ~177 lines, reducing `program_dashboard_page.dart` to ~279 lines. Makes the filter pill reusable for other campaign/program views.
- **Cons**: Slightly increases import footprint in the main page.

#### [MODIFY] [store_form_body.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/admin/pages/widgets/store_form_body.dart)
- **Problem**: The `build` method is 280 lines long, rendering a multi-field administrative store editor form inline.
- **Action**: Break down the large build method by extracting individual form section layouts (e.g., General Information card, Location Details card, Geofence configuration card) into private helper methods (like `_buildGeneralCard`, `_buildLocationCard`) or standalone StatelessWidgets.
- **Complexity**: **Medium**. Form state validations and text controller bindings must remain cleanly in-scope.
- **Pros**: Improves scannability of the form body and reduces the `build` method size from 280 lines to ~40 lines.
- **Cons**: Increases private helper method counts in the state class.

---

## Verification Plan

### Automated Verification
After making any code changes, we must run the full test suite to guarantee zero regression:
- **C# Tests**:
  `rtk proxy dotnet test` in `server/` directory.
- **Flutter UI Tests**:
  `rtk flutter test` in the project root.
- **Modularity Scanner**:
  Re-run the modularity index script to verify that file and method sizes fall below warning limits.

### Manual Verification
Ensure that visual layouts, forms, and pages render correctly in the emulator/browser with no visual regressions.
