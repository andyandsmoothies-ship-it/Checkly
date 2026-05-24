<latent_space_scratchpad>
## Latent Space Scratchpad

### Problem Framing
This is Slice 7: Visual Reskin for Admin, Analytics, and Stores screens. No backend logic is modified. No database modifications are made. No sync behaviors are changed.
However, we must be exceptionally careful about:
1. Retaining `ActionGuard` wrappers on any buttons/actions we modify to ensure that the hybrid entity-driven UI (HATEOAS) allowedActions permissions stay fully functional.
2. Confirming that all replaced widgets (e.g. standard Cards with `StrokeCard`, ElevateButtons with `BubblyButton`, PillChip, PastelAvatar) exactly conform to the visual rules.
3. Keeping file sizes below 400 lines (GEMINI.md rule).
4. Providing detailed instructions for replacing core visual elements in all 14 affected pages.

Let's check the affected pages and their lengths:
- `lib/features/admin/pages/admin_dashboard_page.dart` (314 lines) - Safe.
- `lib/features/admin/pages/audit_approval_page.dart` (272 lines) - Safe.
- `lib/features/admin/pages/schedule_audit_page.dart` (72 lines) - Safe.
- `lib/features/admin/pages/store_management_page.dart` (144 lines) - Safe.
- `lib/features/admin/pages/user_management_page.dart` (272 lines) - Safe.
- `lib/features/admin/pages/role_list_page.dart` (84 lines) - Safe.
- `lib/features/admin/pages/role_detail_page.dart` (96 lines) - Safe.
- `lib/features/admin/pages/global_risk_management_page.dart` (160 lines) - Safe.
- `lib/features/admin/pages/system_logs_page.dart` (215 lines) - Safe.
- `lib/features/admin/pages/system_log_detail_page.dart` (187 lines) - Safe.
- `lib/features/admin/pages/system_pivot_logs_page.dart` (145 lines) - Safe.
- `lib/features/stores/pages/store_dashboard_page.dart` (297 lines) - Safe.
- `lib/features/stores/pages/store_selector_page.dart` (220 lines) - Safe.
- `lib/features/analytics/pages/analytics_page.dart` (78 lines) - Safe.

Let's review the required reskins per screen:
1. `AdminDashboardPage`:
   - Replace generic Lists with `StrokeCard` for menus.
   - Refactor `_MenuItem` to use the new gamified look, rounded shapes, and clean pastels.
2. `AuditApprovalPage`:
   - Wrap submission items in `StrokeCard`.
   - Swap status actions with `BubblyButton` and status tags with `PillChip`.
3. `ScheduleAuditPage`:
   - Use `StrokeCard` and a primary `BubblyButton` for delegation.
4. `StoreManagementPage`:
   - Redesign lists to use modern `StrokeCard` cards.
   - Use `PillChip` for status.
5. `UserManagementPage`:
   - Replace standard ListTiles and User cards with gamified cards.
   - Use `PastelAvatar` and `PillChip` badges.
6. `RoleListPage`:
   - Redesign standard list items as high-contrast `StrokeCard` cards.
7. `RoleDetailPage`:
   - Style capability listings in modern grids wrapped in `StrokeCard`.
8. `GlobalRiskManagementPage`:
   - Redesign risk tables/lists using `StrokeCard`.
9. `SystemLogsPage` & `SystemPivotLogsPage` & `SystemLogDetailPage`:
   - Redesign dense logs using modern high-contrast cards.
   - Highlight warnings or errors using vibrant Cardinal Red accents.
10. `StoreDashboardPage`:
    - KPI cards reskinned using `StrokeCard`.
11. `StoreSelectorPage`:
    - Selection grid refactored into a high-contrast list of interactive `StrokeCard` tiles.
12. `AnalyticsPage`:
    - Ensure page uses clean polar backgrounds and standard dashboard layouts.
</latent_space_scratchpad>

# Implementation Plan - Slice 7: Admin + Analytics + Stores screens

This implementation plan outlines the visual reskin of the administrative, analytics, and store management interfaces to fully adopt the gamified Duolingo theme.

## In Scope
- Refactoring the following 14 page files:
  - `lib/features/admin/pages/admin_dashboard_page.dart`
  - `lib/features/admin/pages/audit_approval_page.dart`
  - `lib/features/admin/pages/schedule_audit_page.dart`
  - `lib/features/admin/pages/store_management_page.dart`
  - `lib/features/admin/pages/user_management_page.dart`
  - `lib/features/admin/pages/role_list_page.dart`
  - `lib/features/admin/pages/role_detail_page.dart`
  - `lib/features/admin/pages/global_risk_management_page.dart`
  - `lib/features/admin/pages/system_logs_page.dart`
  - `lib/features/admin/pages/system_log_detail_page.dart`
  - `lib/features/admin/pages/system_pivot_logs_page.dart`
  - `lib/features/stores/pages/store_dashboard_page.dart`
  - `lib/features/stores/pages/store_selector_page.dart`
  - `lib/features/analytics/pages/analytics_page.dart`
- Preserving all capability checks and security gates (like `PolicyManager` or `ActionGuard`).
- Adhering to the 400-line limit per file.

## Out of Scope
- Any changes to business logic, API requests, database queries, or routing.
- Dark mode custom page styling (global fallbacks handle this).

## Constraint Traceability

| ID | Design Constraint | Mapping to Test Contract ID | Technical Verification Strategy |
|:---|:---|:---|:---|
| **C1** | Nunito bold typography | `TC-07-TYPO` | Ensure all screens use Nunito fonts via global ThemeData or explicit styling |
| **C2** | High-contrast StrokeCards | `TC-07-STROKECARD` | Replace generic Cards with StrokeCard (2px Swan border, R: 16px) |
| **C3** | Solid BubblyButtons | `TC-07-BUBBLYBUTTON` | Replace generic ElevatedButton or text/icon action buttons with BubblyButton |
| **C4** | Pastels & PillChips | `TC-07-PILLCHIP` | Use PillChip for badges and PastelAvatar for avatars |
| **C5** | ActionGuard Preservation | `TC-07-ACTIONGUARD` | Ensure ActionGuard wrappers are untouched and functional |
| **C6** | Strict File Size Constraint | `TC-07-FILESIZE` | Keep all 14 files below 400 lines |

## Verification Plan
1. **Compilation Check**: Run `rtk flutter analyze` to guarantee 0 compiler warnings/errors.
2. **Automated Tests**: Run `rtk flutter test` to verify zero functional regression across all features.
3. **Manual Visual Auditing**: Review each screen manually to ensure consistent margins, rounded corners, pastel hues, and solid button styles.
