# Frontend Baseline Rules (Flutter)

## Architecture

### Patterns
- **PFA Pattern**: Services (API calls), Managers (State/Logic), Pages (UI).
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
- **Gotcha 19: PopScope Trap**: Calling `Navigator.pop()` right after `setState()` freezes the UI.
  - **Fix:** Wait for the frame using `WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));`.
