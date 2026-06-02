# Code Cleanliness and UI Quality Audit Report

This report documents the structural, modularity, and cleanliness audit conducted against the Checkly repository. The scope includes Flutter UI feature pages, shared design system primitives, and backend code hygiene sweeps.

---

## Executive Summary
- **Modularity & File Sizes**: Scanned `lib/features` and `server/Features`. Found 14 files exceeding the strict 400-line modularity limit, and additional files in warning status (>250 lines). All other files adhere to clean sizing limits.
- **Method Lengths**: Identifed methods exceeding the 30-line limit, primarily due to complex widget `build` trees and manual data mapping logic in Dart/C#.
- **Design System & Theme Compliance**: Audited `lib/_shared/widgets/primitives/`. Widgets like `StrokeCard` and `BubblyButton` are fully compliant with token-driven design principles. They query `ChecklyThemeTokens` via `Theme.of(context).extension` and provide robust null-safe fallback values.
- **Architectural & Layer Boundaries**: Confirmed strict separation between Business Language (UI) and Technical Language (DB). No illegal cross-ring imports were found.
- **TODO/FIXME Sweeps**: Verified 0 active/stale `TODO` or `FIXME` comments in the C# and Dart source code.
- **Secrets Scan**: Verified 0 hardcoded credentials, Bearer tokens, or private keys across the entire codebase.
- **Build & Test Baseline**: 
  - **Backend**: 100% build success and all integration tests passed.
  - **Frontend**: Successfully compiled with 842 passing unit/widget tests. Identified 1 pre-existing failure (`AC9: PhotoQueue_MissingLocalFile_SkipsBackoff` in offline backoff tests).

---

## First Principles Assessment

### 1. File Size & Modularity Violations (>400 lines)

The following files exceed the 400-line warning threshold and should be refactored by splitting widgets or managers into dedicated smaller files:

| File Path | Total Lines | Status |
|---|---|---|
| `lib/features/admin/pages/system_logs_page.dart` | 580 | CRITICAL |
| `lib/features/analytics/manager/bod_analytics_data.dart` | 523 | CRITICAL |
| `lib/features/admin/pages/user_management_page.dart` | 518 | CRITICAL |
| `lib/features/analytics/widgets/bod_store_detail_sheet.dart` | 514 | CRITICAL |
| `lib/features/admin/pages/admin_dashboard_page.dart` | 493 | CRITICAL |
| `lib/features/analytics/widgets/area_bod_store_detail_sheet.dart` | 485 | CRITICAL |
| `lib/features/programs/pages/program_dashboard_page.dart` | 455 | CRITICAL |
| `server/Features/Analytics/GetAreaBodReport.cs` | 451 | CRITICAL |
| `lib/features/audit/pages/audit_form_page.dart` | 433 | CRITICAL |
| `server/Features/Analytics/GetBodReport.cs` | 429 | CRITICAL |
| `server/Features/Analytics/BodReportCalculator.cs` | 428 | CRITICAL |
| `lib/features/templates/pages/template_builder_page.dart` | 411 | CRITICAL |
| `lib/features/audit/manager/audit_manager.dart` | 407 | CRITICAL |
| `lib/features/templates/pages/template_list_page.dart` | 400 | CRITICAL |

### 2. Method Size Violations (>30 lines)

Key method size violations were identified in widget building logic:
- `bod_kpi_grid.dart`: `SizedBox` build method
- `review_banners.dart`: `build` method
- `template_manager.dart`: `loadTemplateTree` method

*Refactoring Recommendation*: Extract long nested widget trees into stateless, focused sub-widgets instead of relying on giant build methods.

### 3. Design System Token Compliance

Primitives in `lib/_shared/widgets/primitives/` encapsulate visual tokens elegantly:
- **StrokeCard**: High-contrast 2px borders, dynamic card shape using `ChecklyThemeTokens`, and smooth tap squash micro-animations.
- **BubblyButton**: 3D button faces shifting physically when tapped. Dynamically scales animations to 0 when reduced motion settings are enabled, preventing accessibility issues.

### 4. Hygiene & Credentials Scan

A comprehensive regex scan was run for standard leak signatures:
- **`TODO` / `FIXME` comments**: 0 found.
- **`sk_live` / `sk_test` / `Bearer`**: 0 hardcoded strings found.

---

## SRE Flop Catcher & Failure Mode Analysis

1. **OLAP Aggregate Calculations on Primary DB**: 
   - *Risk*: Monolithic analytics endpoints like `GetBodReport` query Postgres aggregates on-the-fly, which could degrade transactional performance under high load.
   - *Mitigation*: Ensure boarding-room rollups are pre-computed in background jobs and cached in `jsonb` snapshot tables with transaction advisory locks.
2. **Offline Outbox Overflow**:
   - *Risk*: A lack of memory boundaries in SQLite Drift outbox queue could cause OOM crashes if a user accumulates thousands of submissions offline.
   - *Mitigation*: Keep outbox scans bounded and batch network pushes with backoff limits.

---

## Actionable Recommendations
1. **System Log & User Management UI Decomposition**: Extract user dialogs and log list rows into separate files in `lib/features/admin/pages/widgets/`.
2. **Bod Analytics Decomposition**: Break down analytics sheets into separate files targeting individual KPI panels.
