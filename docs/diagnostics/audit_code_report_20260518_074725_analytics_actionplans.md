# Code Audit Report
**Target**: Analytics Feature + Action Plan Widgets
**Date**: 2026-05-18
**Auditor**: Sentinel (Read-Only)

<latent_space_scratchpad>
Audit scope: 12 files across two features (analytics + action_plans).

Key questions to answer:
1. Does any file exceed 400 lines? → analytics_page.dart is exactly 410 lines. CRITICAL.
2. Are there duplicated widgets? → Two `SectionHeader` classes found — one in `_shared/widgets/`, one in `action_plans/widgets/`. They have different constructor APIs (positional vs named). DRY violation but not a blocker.
3. Are there dead stubs? → grep_search for `onPressed: () {}` returned zero results. Clean.
4. Are there hardcoded secrets? → grep_search on both lib/ and server/ returned zero raw keys. Only dynamic token injection patterns exist.
5. Are there print() calls? → Zero.
6. Are there TODOs/FIXMEs? → Zero across all 12 files.
7. Are there magic color values? → `const grey = Colors.grey` in `insights_radar_chart.dart` — not a design token.
8. Does the drift loader have tests? → AR-02 provides one smoke-test. No dedicated date-range or filter-chain tests exist.
9. Slice marker comment? → Line 151 in analytics_manager.dart contains `// ── Slice 3 Fix:` — a dev annotation, not production documentation.
10. Architecture drift? → All managers stay in manager/, all widgets in widgets/. No cross-layer imports detected.
</latent_space_scratchpad>

<forensic_evidence>
Commands executed during this audit:
1. `view_file`: All 12 target files read line-by-line.
   - analytics_page.dart: 410 lines (CRITICAL threshold exceeded)
   - submit_evidence_sheet.dart: 300 lines (within warning range)
   - action_plan_detail_list.dart: 228 lines (clean)
   - analytics_manager.dart: 204 lines (clean — dev comment found on L151)
   - analytics_drift_loader.dart: 186 lines (no dedicated test file)
   - action_timeline.dart: 191 lines (clean)
   - action_plan_action_bar.dart: 162 lines (clean)
   - insights_radar_chart.dart: 152 lines (magic grey color on L55)
   - analytics_data.dart: 95 lines (clean)
   - insight_card.dart: 86 lines (clean)
   - info_row.dart: 62 lines (clean)
   - section_header.dart: 22 lines (duplicate of _shared/widgets/section_header.dart)

2. `grep_search` (IsRegex=false): `TODO` in action_plans/widgets/ → 0 results
3. `grep_search` (IsRegex=false): `TODO` in analytics/ → 0 results
4. `grep_search` (IsRegex=false): `onPressed: () {}` in action_plans/widgets/ → 0 results
5. `grep_search` (IsRegex=false): `print(` in action_plans/widgets/ → 0 results
6. `grep_search` (IsRegex=false): `print(` in analytics/ → 0 results
7. `grep_search` (IsRegex=true): `sk_test|sk_live|password=|Bearer ` in lib/ → 3 results (all dynamic token injections via variables, not hardcoded values)
8. `grep_search` (IsRegex=true): `sk_test|sk_live|password=|Bearer ` in server/ → 0 results
</forensic_evidence>

## Executive Summary

| Severity | Count |
|---|---|
| 🔴 Critical | 1 |
| 🟡 Warning | 3 |
| 🟢 Optimization | 1 |

---

## 🔴 Critical Findings

### C-01 — `analytics_page.dart` Exceeds 400-Line Hard Limit
- **File**: `lib/features/analytics/pages/analytics_page.dart` (410 lines)
- **Rule**: Files >400 lines are a **mandatory split**.
- **Root Cause**: The file contains: (1) `_AnalyticsPageState` with filter logic, (2) the full chip bar UI, (3) the full KPI/Trend/Category/Insights/Radar section body, and (4) the private `_StaleBanner` widget. These are 4 distinct concerns in one file.
- **Complexity**: **Medium** — the split requires creating a new child widget file and passing state via callbacks or manager reference. No logic changes are needed — it is a pure structural move.
- **Proposed Decomposition**:
  ```
  analytics_page.dart        (keep — ~150 lines, just the scaffold + ListenableBuilder)
  analytics_filter_chips.dart (NEW — the scrollable chip bar, ~90 lines)
  analytics_body.dart         (NEW — KPI cards + Trend + Category + Insights + Radar, ~150 lines)
  ```
  The `_StaleBanner` private widget stays in `analytics_body.dart` since it is only used there.
- **Trade-offs**:
  - ✅ **Pro**: Each file is under 200 lines. AI tools and code reviews are significantly easier.
  - ✅ **Pro**: `analytics_filter_chips.dart` becomes independently testable.
  - ⚠️ **Con**: Adds 2 new files. The `_manager` reference must be passed explicitly via constructor injection.
  - **Decision Required**: You must approve before implementation.

---

## 🟡 Warning Findings

### W-01 — Duplicate `SectionHeader` Implementations (DRY Violation)
- **Files**:
  - `lib/features/action_plans/widgets/section_header.dart` (22 lines)
  - `lib/_shared/widgets/section_header.dart` (used by analytics_page.dart)
- **Root Cause**: The action plans feature has its own local `section_header.dart`. The analytics feature imports the shared one from `_shared/widgets/`. The two widgets have **different API signatures**:
  - Action Plans version: `SectionHeader({required String title})`
  - Shared version: `SectionHeader(String label)` (positional)
- **Complexity**: **Low** — Align both widgets to a single shared implementation with one named `title` parameter.
- **Fix**:
  1. Update `_shared/widgets/section_header.dart` to accept a named `title` parameter.
  2. Update all callers in analytics that use `SectionHeader('LABEL')` (positional) to `SectionHeader(title: 'LABEL')`.
  3. Delete `lib/features/action_plans/widgets/section_header.dart`.
- **Trade-offs**:
  - ✅ **Pro**: Single source of truth. No API drift between features.
  - ⚠️ **Con**: Requires touching all `analytics_page.dart` call sites (4 usages). Low risk.
  - **Decision Required**: You must approve before implementation.

### W-02 — Development Marker Comment in Production Code
- **File**: `lib/features/analytics/manager/analytics_manager.dart`, line 151
- **Comment**: `// ── Slice 3 Fix: Parse insights & radarData from API response ──────────`
- **Root Cause**: This was a development annotation written during implementation. Slice labels are not valid production documentation — they explain **when** the code was written, not **what it does or why**.
- **Complexity**: **Low** — Replace the comment with a meaningful docstring.
- **Fix**:
  ```dart
  // Parse optional server-driven insight cards and radar benchmarks.
  // These fields are only populated when the store has sufficient audit history (≥3 audits).
  ```
- **Trade-offs**:
  - ✅ **Pro**: Code is self-documenting and survives slice numbering being irrelevant in 6 months.
  - ⚠️ **Con**: None.

### W-03 — `analytics_drift_loader.dart` Has No Dedicated Unit Tests
- **File**: `lib/features/analytics/manager/analytics_drift_loader.dart` (186 lines)
- **Root Cause**: The offline `loadFromDrift()` function contains non-trivial date filtering logic (custom date ranges, multi-filter chaining, 6-month trend computation) with no dedicated test coverage. It is indirectly tested via `analytics_manager_test.dart` (AR-02) only at the happy-path level.
- **Complexity**: **Medium** — Requires an in-memory Drift database setup (already available in the test project).
- **Proposed Tests** (not yet written):
  - `loadFromDrift_withCustomDateRange_filtersCorrectly`
  - `loadFromDrift_withAreaFilter_excludesOtherStores`
  - `loadFromDrift_withEmptyDb_returnsZeros`
- **Trade-offs**:
  - ✅ **Pro**: The offline path is a critical fallback. If it breaks, the app silently shows stale data. Tests provide a regression net.
  - ⚠️ **Con**: 3 new test cases, moderate setup effort.
  - **Decision Required**: You must approve before implementation.

---

## 🟢 Optimization Findings

### O-01 — `insights_radar_chart.dart` Uses `const Colors.grey` (Magic Value)
- **File**: `lib/features/analytics/widgets/insights_radar_chart.dart`, line 55
- **Code**: `const grey = Colors.grey;`
- **Issue**: This is a raw Material color, not a design token. If `AppTheme` ever changes the grey palette, this legend dot will not update.
- **Complexity**: **Low** — Replace with `theme.colorScheme.onSurfaceVariant` which is already used 3 lines away.
- **Fix**:
  ```dart
  // Before
  const grey = Colors.grey;
  // After
  final grey = theme.colorScheme.onSurfaceVariant;
  ```
- **Trade-offs**:
  - ✅ **Pro**: Consistent with the theme system. Will adapt to dark mode correctly.
  - ⚠️ **Con**: None. Pure improvement.

---

## Clean Files (No Findings)
The following files passed all checks with zero findings:

| File | Lines | Status |
|---|---|---|
| `insight_card.dart` | 86 | ✅ Clean |
| `analytics_data.dart` | 95 | ✅ Clean |
| `analytics_drift_loader.dart` | 186 | ✅ Clean (W-03 is a coverage gap, not a code smell) |
| `action_plan_action_bar.dart` | 162 | ✅ Clean |
| `action_plan_detail_list.dart` | 228 | ✅ Clean |
| `action_timeline.dart` | 191 | ✅ Clean |
| `info_row.dart` | 62 | ✅ Clean |
| `section_header.dart` (AP) | 22 | ✅ Clean (see W-01) |

---

## Routing

Pass this report to Builder agent (@Forge) for `/implement (Track B)`.

> [!IMPORTANT]
> **Requires executive approval on C-01, W-01, and W-03 before implementation.** These involve creating new files, merging shared widgets, and writing tests.
