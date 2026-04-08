# Shared Flutter Rules & Gotchas

# Shared Flutter Rules & Gotchas

> [!IMPORTANT]
> **Drift OOM — Every DAO Query Must Be Bounded**
> **Problem:** Unbounded `.select().get()` loads entire tables, causing Out-Of-Memory.
> **Fix:** DAO queries MUST use `selectOnly + count()/avg()`, `..limit(n)`, or `customSelect` raw SQL.

> [!WARNING]
> **Nested Scaffold FAB Renders Behind Bottom Nav**
> **Problem:** `extendBody: true` in `_MainShell` causes inner Scaffold FABs to hide behind the 96px nav bar.
> **Fix:** Wrap the inner FAB with `Padding(padding: EdgeInsets.only(bottom: 80))`.

> [!WARNING]
> **FAB Inside PopupMenuButton Absorbs Taps**
> **Problem:** An `InkResponse` in a FAB inside a `PopupMenuButton` absorbs the tap, breaking the menu toggle.
> **Fix:** Call `showMenu()` programmatically from `FAB.onPressed`.

> [!WARNING]
> **Bottom Nav Label Context Scope**
> **Problem:** Context-sensitive labels like "AUDIT" are wrong when outside that specific loop.
> **Fix:** Use generic template-agnostic labels like `'ACTIVITY'`.
