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

### Rendering & Layout
- **Gotcha 19: PopScope / Route Guard Pop Block**: Mutating form dirty/saving state right before popping the route can cause the page to hang or show unsaved changes dialogs if the route guard is not rebuilt.
  - **Fix:** Wrap state mutations in `setState` and defer the pop call using `WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.maybePop(context));`.
- **Gotcha: UnsavedChangesGuard Navigation Race Condition**
  - **Fix:** When programmatically popping a screen or sheet wrapped in an `UnsavedChangesGuard` after a successful operation (such as user creation, edit, or risk form submission), you must set the form's `isDirty` state to `false` first, then schedule the navigation callback (`Navigator.maybePop` or parent callback) using a post-frame callback logic checking `WidgetsBinding.instance.schedulerPhase`. If the scheduler is not `idle`, you must wrap the callback in a nested `addPostFrameCallback` or execute it directly if `idle`. This prevents the `PopScope` from reading the stale `isDirty = true` state before the widget rebuild completes.
- **Gotcha: Boardroom Analytics List View Modularization**
  - **Fix:** Do not implement inline widget mappings for `categoryBreakdown` or `recentAudits` lists inside bottom sheets like `BodStoreDetailSheet` or `AreaBodStoreDetailSheet`. Always use `CategoryPerformanceSection` and `RecentAuditsSection` to keep files modular, readable, and compliant with standard styling guidelines.
- **Gotcha: Double-Padding and Nested Grid Layout Spacing**
  - **Fix:** Never wrap sub-headers or individual greeting widgets in custom `SafeArea` inside nested scroll views or columns when the parent root layout already wraps the page. Always lift `SafeArea` to the scaffold body root level once (`SafeArea(bottom: false, child: Column(...))`) so nested components see `padding.top = 0`. Additionally, always set `padding: EdgeInsets.zero` explicitly on nested `GridView.count` widgets to override default inherited non-zero vertical grid paddings, preventing ugly empty white spaces.

## State & Payload Gotchas
- **Gotcha 23: Direct Store Assignment UI**: The backend API allows sending an array of `assignedStoreIds` for Area Managers. 
  - **Fix:** The UI MUST provide a Multi-Store Picker component when editing an Area Manager. The Virtual Area dropdown is only a macro shortcut, and should be explicitly labeled to avoid confusing users who expect 1-to-1 hierarchy.
- **Gotcha: Hardcoded Role Filtering in UI Lists**
  - **Fix:** Do not hardcode role string checks (e.g., `u['role'] == 'auditor'`) in the frontend to filter dropdowns or UI lists, especially when migrating to PBAC. If the UI arbitrarily excludes roles like `area_manager`, dropdowns will appear empty and lead to silent null-reference validation errors. Always prefer backend-driven capability lists or PBAC-aware filtering.
- **Gotcha: Flutter SQLite Array Serialization (categoryTags)**
  - **Fix:** SQLite does not natively support array types. `TemplateDao` serializes `List<String>? categoryTags` into a comma-separated String when saving to SQLite. When reading, it splits by comma and sanitizes the result using `.where((t) => t.isNotEmpty).toList()` to prevent empty strings from polluting the output. Ensure any test models or frontend widgets handle empty/whitespace strings gracefully and never assume index-based access on un-sanitized comma values.
- **Gotcha: Bimodal Geofence Proximity Validation Flow**
  - **Fix:** Geofence checks must run synchronously before GPS is resolved for final audit outbox pinning, preventing race conditions or premature submissions before geofence warning/blocking dialogs are rendered.
- **Gotcha: Geofence Count Semantics**
  - **Fix:** Geofence warning alerts trigger in the frontend only when `geofenceBypassCount > 0`. The card renders next to `Total Auditors` in Row 4 of `BodKpiGrid`.

## Testing Gotchas
- **Gotcha 24: Widget Testing Lazy Lists**: Flutter's `ListView` and `CustomScrollView` are lazy. Widgets off-screen do not exist in the widget tree.
  - **Fix:** You MUST use `tester.drag` or `tester.scrollUntilVisible` to bring hidden elements into view before asserting their existence.
- **Gotcha 25: UI Library Constraints in Tests**: Third-party UI constraints (e.g., `fl_chart` requiring >= 3 categories for a RadarChart) apply even in tests.
  - **Fix:** Test mock data MUST respect these constraints. Do not bypass manager guards by injecting faulty mock data directly into widgets.
- **Gotcha 31: Automated Golden UI Verification**: Manual screen checking is highly error-prone. All new custom widgets or primary design updates must build a Golden test to lock in layout and look.
  - **Fix:** Reference images must live in `test/goldens/`. Always run `flutter test --update-goldens` to lock your changes.
- **Gotcha: Flutter Testing Framework (Mocktail vs Mockito)**
  - **Fix:** Checkly uses `mocktail` exclusively for Flutter tests. Never import `mockito` or use `@GenerateMocks` code generation. Always use `class MockMyService extends Mock implements MyService {}`.
- **Gotcha: Card-Count Layout Assertions in Widget Tests**
  - **Fix:** When refactoring components that are expected to render as Card widgets by standard unit tests (specifically verified via `find.byType(Card)` assertions), make sure the outer widget is a `Card` widget rather than a `Container` with rounded borders to satisfy the test assertions and layout contracts.
- **Gotcha: Widget-Type Assertions in Create Wizard Tests (BubblyButton vs ElevatedButton)**
  - **Fix:** When refactoring interactive buttons in forms/wizards that are verified in existing unit or widget tests using precise class searches (specifically casting to `ElevatedButton`), make sure to render an `ElevatedButton` wrapped or styled rather than using a custom non-Material button like `BubblyButton` to prevent type cast exception failures.
- **Gotcha: TextFormField length-limiting validation testing**
  - **Fix:** In Flutter widget testing, when a `TextFormField` has `maxLength` specified, `tester.enterText()` will be constrained by the input formatter and cannot enter text longer than `maxLength`. To test validation logic asserting text exceeds this maximum limit, you must set the text value directly on the `TextEditingController` (e.g. `field.controller!.text = 'a' * 201`), then call `tester.pump()` to trigger the validation check on submission.
- **Gotcha: Asynchronous Timer pending in widget tests**
  - **Fix:** Stateful widgets that instantiate delayed futures or Timers for staggered entrance animations (such as BouncyListWrapper or StaggeredListItem) must store references to their underlying timers/controllers and explicitly call `.cancel()` inside `dispose()`. This guarantees that all active timers are discarded when the widget tree is torn down at the end of a test run, preventing the framework from throwing a "A Timer is still pending even after the widget tree was disposed" exception.
- **Gotcha: Public State Naming for Animation Testing**
  - **Fix:** When implementing custom animated widgets whose internal controller states or animation status needs to be verified during widget testing (e.g. `isAnimating`), name the `State` class publicly (e.g. `class ChecklyEmptyStateState extends State<ChecklyEmptyState>` instead of using a private `_` prefix). This allows the widget testing framework to access it directly via `tester.state<ChecklyEmptyStateState>(find.byType(ChecklyEmptyState))`.
- **Gotcha: Card Title Flex Overflow in Headless Tests**
  - **Fix:** In narrow headless testing environments or mobile layouts, horizontal `Row` components containing `Icon` and `Text` (like card header layouts) will throw layout overflow exceptions. Always wrap the header `Text` widget in an `Expanded` or `Flexible` widget to allow elegant text wrapping and guarantee test robustness.
- **Gotcha: Golden UI Asset Path Mapping**
  - **Fix:** Golden test images must be saved under the `test/goldens/` directory. Do not check in full device screenshots; only assert against the target widget or isolated component viewports to keep reference images small, lightweight, and clean.
- **Gotcha: Widget-Type Switch Finder Collisions**
  - **Fix:** In Flutter widget testing, when using `find.byType(Switch).first` to retrieve the first question's toggle, ensure that other simulation switches (e.g., Global Risk Override switches) are placed at the bottom of the list or use unique widgets/keys so they do not collide with the question's toggle selection.
- **Gotcha: Viewport Off-Screen Test Failure**
  - **Fix:** If a newly added list/grid item pushes other elements off-screen in widget tests, the lazy-loading widgets (like GridView/ListView) will not build them, causing finders to fail. Always set `tester.view.physicalSize` to a larger size (e.g. `const Size(800, 1200)`) and restore it inside `addTearDown` to ensure all elements fit in the test viewport.

## Primitives & Reskin Gotchas
- **Gotcha 26: BubblyButton Constraints**: Always wrap `BubblyButton` in layout constraints or specify container boundaries, as it defaults to `width: double.infinity` to align with the core grid.
- **Gotcha 27: QuestProgressBar Scale Clamp**: Value parameter is clamped internally. Do not write manual clamping layers outside it.
- **Gotcha 28: PillChip and PastelAvatar Theme Preservation**: These primitives utilize predefined color maps instead of arbitrary gray or dark presets to maintain the gamified, vibrant aesthetic. Do not inject custom style overrides that bypass the predefined enums or theme classes.
- **Gotcha 34: BubblyButton Solid vs. Outline Standard**: Primary page-level goals use a **Solid 3D BubblyButton** for high visual contrast. Inline repeating lists, cards, or item-level actions use **Outline 3D BubblyButton** (`isOutline: true`) with a white face to maintain a clean interface and prevent visual clutter.
- **Gotcha: Admin Duolingo Reskin Aesthetic**
  - **Fix:** All administrative pages (Dashboard, User, Store, Audit, Risk, and Logs) must utilize the custom `StrokeCard` and `PillChip` design primitives rather than raw standard cards or custom styled containers to ensure aesthetic consistency and visual excellence across the platform.
- **Gotcha: Reduced Motion Compliance**
  - **Fix:** All highly active micro-animations (such as bouncy button squashes, list cascades, empty state jiggles, and elastic checkbox pops) must explicitly verify and respect reduced motion settings via `MediaQuery.disableAnimationsOf(context)`. If active, transitions must immediately snap to target boundaries without delay, curve interpolation, or ticker activity, to avoid triggering motion sensitivity issues for accessibility users.

## Diagnostic & Layout Stability
- **Gotcha 29: Unregistered Global Singletons (DI Crashes)**: `GetIt.instance<T>()` crashes the app if `T` isn't registered. Always verify `locator.dart` registers global services before consuming them. Never mock missing dependencies in tests if they don't exist in production.
- **Gotcha 30: Infinite Layout Freezes in Rows**: Widgets defaulting to `double.infinity` width (like `ElevatedButton`, `TextFormField`) cause infinite layout loops inside an unconstrained horizontal `Row`. Always wrap them in `Expanded`, `Flexible`, or apply a bounded `minimumSize`.
- **Gotcha 32: Mobile-First Layout Focus**: The Checkly app is designed exclusively for mobile viewports. Do not duplicate widgets across mobile-only views (e.g. rendering TemplateLinterPanel both inside a form and as a separate tab). Always prioritize clean, single-column scrollable forms and clear tab structures.
- **Gotcha 33: Drift `read<dynamic>` Type Mapping Crash**: When reading database query rows dynamically (e.g., asserting metadata or defaults returned from PRAGMA table_info in unit tests), never use `row.read<dynamic>('column_name')`. Drift's internal mapping system does not support runtime dynamic types, which throws a runtime exception. Always use concrete nullable types like `row.read<String?>('dflt_value')` to ensure safe database inspections.
- **Gotcha 35: Enterprise-Grade Design System & Spirit Swapping**: UI layouts and widgets must never hardcode visual tokens (corner radius, outline weights, 3D depths). Instead, query `ChecklyThemeTokens` via `Theme.of(context).extension<ChecklyThemeTokens>()`. Ensure headless widget test resilience by always using a safe fallback (e.g. `tokens?.cardRadius ?? 16.0`). Swapping theme spirits dynamically must follow the state notifier pattern rather than static mutations. Refer to `C:\Users\HP\.gemini\antigravity\brain\dcbfac81-a3e9-4fad-af42-bc281b403b75\architecture_design-system-governance_20260602_063500.md` for full implementation guidelines.
- **Gotcha 36: UI Page Helper Widget Isolation**: Keep page files under 400 lines by extracting sub-widgets (such as list cards and modal sheets) into a `widgets/` folder. Extracted widgets must be stateless and receive all data and click callback handlers via parameters.
- **Gotcha 37: Resilient Non-blocking Sync Loops**: Background sync execution loops (like `SyncEngine`) must run each sync module in an isolated try-catch block. A failure in one module must not block subsequent modules from executing. Accumulate exceptions and throw a single combined error at the end of the sync cycle.
