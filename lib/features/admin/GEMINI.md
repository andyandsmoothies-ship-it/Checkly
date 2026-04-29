# GEMINI.md — lib/features/admin/

## Gotcha A: Mocktail Stub Isolation in Sequential Widget Tests
**Context:** `role_management_atdd_test.dart` — multiple `testWidgets` sharing one `MockAdminApiService`.  
**Problem:** `when(() => mock.getRoles()).thenAnswer((_) async { counter++; })` — the local `counter` variable captures state across test ordering when the same mock object is reused in `setUp`. Produces non-deterministic failures where later tests see stale state.  
**Fix:** Use a boolean flag (`var granted = false`) that the stub sets on invocation, then assert `expect(granted, isTrue)`. Never use an incrementing counter inside a `thenAnswer` closure that spans multiple mocked calls.  
**Verified:** 3 successful test suite runs post-fix. Status: CONFIRMED.

---

## Gotcha B: Online-Only Mandate — No Offline Cache in Role Management
**Context:** `role_list_page.dart`, `role_detail_page.dart`, `role_manager.dart`  
**ADR Decision (Option A):** Role Management is **strictly online-only**. If `ConnectivityService.isOnline == false`, both pages MUST render the full-page `_OfflineLockView`. No stale data, no Drift tables, no `ValueNotifier` cache across connection drops.  
**Why:** A demoted admin whose device was offline could still see their old capabilities — the "Ghost State" security vulnerability.  
**Implementation:** `StreamBuilder<bool>` on `ConnectivityService.onConnectivityChanged` — reacts synchronously to drops. Do NOT replace with `ListenableBuilder` — `ConnectivityService` is not a `Listenable`.

---

## Gotcha C: RoleCommand Uses .execute() Not .run()
**Context:** `role_manager.dart` — `RoleCommand` class.  
**Why `.execute()` not `.run()`:** The Sentinel-generated TDD tests (`role_manager_test.dart`) use `grantCommand.execute(params)`. Using `command_it`'s `.run()` would break the test contract and trigger the Mirror Function Trap. `RoleCommand` is a deliberately lightweight wrapper — do NOT replace it with `command_it`'s `Command` class without updating both the tests and the ATDD widget tests.

---

## Architecture: Role Management Files
```
lib/features/admin/
  model/
    role_dto.dart           — RoleDto(role, capabilities) + fromJson
  manager/
    role_manager.dart       — RoleManager + RoleCommand (online-only state)
  services/
    admin_api_service.dart  — +getRoles, +getCapabilityCatalog, +grantCapability, +revokeCapability
  pages/
    role_list_page.dart     — /admin/roles
    role_detail_page.dart   — /admin/roles/:role

test/features/admin/
  manager/
    role_manager_test.dart  — TC-01..08 (inner-loop TDD, mocktail)
  pages/
    role_management_atdd_test.dart — AT-01..05 (ATDD widget tests, GetIt scope isolation)
```

---

## Gotcha D: C# Record DTO Wraps Arrays — Never Cast response.data Directly to List
**Context:** `admin_api_service.dart` — `getCapabilityCatalog()`.
**Problem:** `GetCapabilityCatalog.cs` returns `TypedResults.Ok(new CatalogResponse(Catalog))` where `CatalogResponse` is a C# record. Dart receives `{"capabilities": [...]}` as a `Map<String, dynamic>`. Naively casting `response.data as List<dynamic>` throws a `TypeError` that the manager's catch block silently suppresses, leaving `catalog.value == null`. The fallback `catalog ?? assigned` then renders only the already-assigned capabilities — making the bug invisible for the `admin` role (which has all caps) but catastrophic for `auditor`/`store_manager`.
**Fix:** Always extract the named key: `final data = response.data as Map<String, dynamic>; final list = data['capabilities'] as List<dynamic>;`
**Rule:** When a C# endpoint returns a `record` or `class` wrapper DTO, the Dart client MUST cast to `Map<String, dynamic>` first, then extract the payload field. Never assume a C# endpoint returns a bare array.
**Verified:** Fix confirmed via `flutter analyze` — 0 issues. Status: CONFIRMED.
