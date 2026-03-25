# 🚀 Frontend Stack Rules (Flutter & Dart)

> [!IMPORTANT]
> The rules in this file apply ONLY when writing or modifying Dart code in the `lib/` directory.

## 1. Architecture Constraints (PFA)
- **Framework**: Flutter via the flutter_it construction set.
- **State Management**: MUST use the Pragmatic Flutter Architecture (PFA) involving `get_it`, `watch_it`, `command_it`, and `listen_it`.
- **ViewModels/BLoC/Provider**: Strictly FORBIDDEN. Use Services + Managers.
- **Proxy Pattern**: UI Widgets listen to Managers (using `watch_it`), which interact with Repositories. Do not bypass managers.

## 2. Infrastructure & Offline Sync
- **Local Database**: IndexedDB/Dexie (web) or Drift/SQLite (mobile).
- **Sync Methodology**: Rely on the V3 'Battle-Tested' Background Sync Pipeline. Do not build manual HTTP caching for core entities.
- **DTOs**: Data Transfer Objects must be plain Dart classes with `final` fields, `const` constructors, and `fromJson` serialization.
- **Drift Query Safety (OOM Invariant)**: Every query in a DAO (`*_queries.dart`) MUST use either `selectOnly` with `count()/avg()`, or have an explicit `.limit(n)`. **Bare `.get()` without limits are automatic OOM violations** and are strictly forbidden on entity tables.

## 3. Shared Presentation & UI
- **Mobile First**: All layouts must default to mobile viewport optimization.
- **Scroll Restoration**: Use PageStorageKeys when implementing tabs containing ListViews so scroll position is preserved.
- **FAB Rules**: Any `FloatingActionButton` placed directly inside a nested scaffold must apply a `Padding(bottom: 80)` spacer so it does not render identically underneath the Bottom Navigation Bar.
- **Cinematic Themes**: When modifying UI colors, you MUST respect the multi-theme architecture (Dark Mode, Sakura Zen, Festive Red). Do not hardcode static Hex colors if a semantic theme token exists.

## 4. Anti-MacGyver Logic
- Before writing a new UI widget, you MUST run a search on `lib/_shared/` to verify a standard component does not already exist (e.g., standard buttons, inputs).

## 5. Development Gotchas
- **Drift Types**: Drift does not natively support `.having()` clauses on custom selects in version 2.x. Write raw SQL `customSelect` if `HAVING` bounds are required.
