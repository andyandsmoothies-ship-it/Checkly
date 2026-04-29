# GEMINI.md — Notifications Feature

## Gotcha 21: Never trigger synchronous global broadcasts inside `initState`

* **Problem:** Shared singleton managers that call `notifyListeners()` synchronously at the start of a network request will crash the app with `setState() called during build` if invoked directly inside `initState` of a new screen.
* **Fix:** Use `WidgetsBinding.instance.addPostFrameCallback((_) { ... });` to defer the API request until the UI has successfully mounted.
