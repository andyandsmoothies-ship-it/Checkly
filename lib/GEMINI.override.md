# Global Flutter/Dart Gotchas

- **Gotcha 17: GlobalKey Inline in `build()` Destroys Focus and BuildContext**
  - **Problem:** `?? GlobalKey()` inline creates a new key on every rebuild, causing Flutter to unmount/remount the element — breaks TextField focus and crashes `MediaQuery`.
  - **Fix:** Use `ObjectKey(model)` tied to the stable data object. Never inline `GlobalKey()` in `build()`.

- **Gotcha 22: Dart Lint: No Leading Underscores on Local Variables**
  - **Problem:** `no_leading_underscores_for_local_identifiers` lint fires on `_` prefixed local variables — `_` is class-private only.
  - **Fix:** Use unprefixed local names (`final showCcp`, not `final _showCcp`).
