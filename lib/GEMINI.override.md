# Global Flutter/Dart Gotchas

- **Gotcha 17: GlobalKey Inline in `build()` Destroys Focus and BuildContext**
  - **Problem:** `?? GlobalKey()` inline creates a new key on every rebuild, causing Flutter to unmount/remount the element — breaks TextField focus and crashes `MediaQuery`.
  - **Fix:** Use `ObjectKey(model)` tied to the stable data object. Never inline `GlobalKey()` in `build()`.

- **Gotcha 22: Dart Lint: No Leading Underscores on Local Variables**
  - **Problem:** `no_leading_underscores_for_local_identifiers` lint fires on `_` prefixed local variables — `_` is class-private only.
  - **Fix:** Use unprefixed local names (`final showCcp`, not `final _showCcp`).

- **Gotcha 23: Mocktail `any()` on Custom Types Requires `registerFallbackValue`**
  - **Problem:** `when(() => mock.saveSession(any()))` throws `Bad state: A test tried to use any() on a parameter of type UserSession` in sound null safety mode.
  - **Fix:** Add `setUpAll(() { registerFallbackValue(const UserSession(userId: '', email: '', role: '', token: '')); });` to any test file using `any()` with `UserSession` or other custom non-nullable types.

- **Gotcha 24: `AuthManager` Interface Changes Break All `implements AuthManager` Test Stubs**
  - **Problem:** Adding a new getter/method causes compile errors in EVERY test file with `class _StubX extends ChangeNotifier implements AuthManager`.
  - **Fix:** After ANY `AuthManager` modification, run `grep_search` for `implements AuthManager` in the `test/` tree and add the missing no-op implementations. Return `ValueNotifier({})` for new `ValueListenable` getters.
