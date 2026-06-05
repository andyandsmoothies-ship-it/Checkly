# Frontend Baseline Rules (Flutter)
> **Scope**: Flutter state/routing architecture, UI rendering guidelines, widget testing constraints, and custom design tokens.
> **Out of Scope**: Backend endpoints, SQL migrations, or global project governance.

## Architecture

### Patterns
- **PFA Pattern**: Services (API calls), Managers (State/Logic), Pages (UI).
- **Gotcha 20: DAO/API Leakage**: UI Layers (Widgets/Pages) must NEVER import `database/dao/` or `services/api/` directly. All UI-to-Data communication MUST route through a `Manager` or `SyncEngine`.
- **Gotcha 21: UI File Size Limits**: Never place a complex `Form` or standalone widget in the same file as a `Page` Scaffold if combined lines > 200. Split into `pages/` and `widgets/` early to avoid the 400-line hard cap.
- **Gotcha 22: Logic Nesting**: Keep logic flat. Do not define complex recursive closures inside methods like `build()` or `validate()`. Extract them to private helpers.
- **DTO Pattern**: DTOs are plain Dart classes. Server JSON uses `camelCase`. Add new fields as nullable.

### Offline-First Sync
- **Delta Sync**: Sync changes via `GET /api/sync/templates?since={timestamp}`.
- **Gotcha 17**: Offline-First Sync Requires Full-Stack Checks. Backend endpoints must support receiving out-of-order offline data.

## UI & Navigation Gotchas

### Routing
- **Gotcha 15: Navigation Outside ShellRoute**: `context.go('/route')` outside a ShellRoute drops the bottom menu. 
  - **Fix:** Grab `GoRouter.of(context)`, go to `/shell-root`, wait a microtask, then `push('/target')`.
- **Gotcha 18: Notification Deep-Links**: Do not hardcode deep-link strings blindly. Use `grep_search` on `app_router.dart` to verify the route actually exists.

### Rendering
- **Gotcha 19: PopScope / Route Guard Pop Block**: Mutating form dirty/saving state right before popping the route can cause the page to hang or show unsaved changes dialogs if the route guard is not rebuilt.
  - **Fix:** Wrap state mutations in `setState` and defer the pop call using `WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.maybePop(context));`.

## State & Payload Gotchas
- **Gotcha 23: Direct Store Assignment UI**: The backend API allows sending an array of `assignedStoreIds` for Area Managers. 
  - **Fix:** The UI MUST provide a Multi-Store Picker component when editing an Area Manager. The Virtual Area dropdown is only a macro shortcut, and should be explicitly labeled to avoid confusing users who expect 1-to-1 hierarchy.

## Testing Gotchas
- **Gotcha 24: Widget Testing Lazy Lists**: Flutter's `ListView` and `CustomScrollView` are lazy. Widgets off-screen do not exist in the widget tree.
  - **Fix:** You MUST use `tester.drag` or `tester.scrollUntilVisible` to bring hidden elements into view before asserting their existence.
- **Gotcha 25: UI Library Constraints in Tests**: Third-party UI constraints (e.g., `fl_chart` requiring >= 3 categories for a RadarChart) apply even in tests.
  - **Fix:** Test mock data MUST respect these constraints. Do not bypass manager guards by injecting faulty mock data directly into widgets.
- **Gotcha 31: Automated Golden UI Verification**: Manual screen checking is highly error-prone. All new custom widgets or primary design updates must build a Golden test to lock in layout and look.
  - **Fix:** Reference images must live in `test/goldens/`. Always run `flutter test --update-goldens` to lock your changes.

## Primitives & Reskin Gotchas
- **Gotcha 26: BubblyButton Constraints**: Always wrap `BubblyButton` in layout constraints or specify container boundaries, as it defaults to `width: double.infinity` to align with the core grid.
- **Gotcha 27: QuestProgressBar Scale Clamp**: Value parameter is clamped internally. Do not write manual clamping layers outside it.
- **Gotcha 28: PillChip and PastelAvatar Theme Preservation**: These primitives utilize predefined color maps instead of arbitrary gray or dark presets to maintain the gamified, vibrant aesthetic. Do not inject custom style overrides that bypass the predefined enums or theme classes.
- **Gotcha 34: BubblyButton Solid vs. Outline Standard**: Primary page-level goals use a **Solid 3D BubblyButton** for high visual contrast. Inline repeating lists, cards, or item-level actions use **Outline 3D BubblyButton** (`isOutline: true`) with a white face to maintain a clean interface and prevent visual clutter.

## Diagnostic & Layout Stability
- **Gotcha 29: Unregistered Global Singletons (DI Crashes)**: `GetIt.instance<T>()` crashes the app if `T` isn't registered. Always verify `locator.dart` registers global services before consuming them. Never mock missing dependencies in tests if they don't exist in production.
- **Gotcha 30: Infinite Layout Freezes in Rows**: Widgets defaulting to `double.infinity` width (like `ElevatedButton`, `TextFormField`) cause infinite layout loops inside an unconstrained horizontal `Row`. Always wrap them in `Expanded`, `Flexible`, or apply a bounded `minimumSize`.
- **Gotcha 32: Mobile-First Layout Focus**: The Checkly app is designed exclusively for mobile viewports. Do not duplicate widgets across mobile-only views (e.g. rendering TemplateLinterPanel both inside a form and as a separate tab). Always prioritize clean, single-column scrollable forms and clear tab structures.
- **Gotcha 33: Drift `read<dynamic>` Type Mapping Crash**: When reading database query rows dynamically (e.g., asserting metadata or defaults returned from PRAGMA table_info in unit tests), never use `row.read<dynamic>('column_name')`. Drift's internal mapping system does not support runtime dynamic types, which throws a runtime exception. Always use concrete nullable types like `row.read<String?>('dflt_value')` to ensure safe database inspections.
- **Gotcha 35: Enterprise-Grade Design System & Spirit Swapping**: UI layouts and widgets must never hardcode visual tokens (corner radius, outline weights, 3D depths). Instead, query `ChecklyThemeTokens` via `Theme.of(context).extension<ChecklyThemeTokens>()`. Ensure headless widget test resilience by always using a safe fallback (e.g. `tokens?.cardRadius ?? 16.0`). Swapping theme spirits dynamically must follow the state notifier pattern rather than static mutations. Refer to `C:\Users\HP\.gemini\antigravity\brain\dcbfac81-a3e9-4fad-af42-bc281b403b75\architecture_design-system-governance_20260602_063500.md` for full implementation guidelines.
