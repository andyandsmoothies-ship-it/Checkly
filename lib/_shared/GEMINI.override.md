# Shared Flutter Rules & Gotchas

- **Gotcha 14: Drift OOM — Every DAO Query Must Be Bounded**
  - **Problem:** Unbounded `.select().get()` loads an entire table into memory.
  - **Fix:** Every DAO query MUST use (1) `selectOnly + count()/avg()`, (2) `..limit(n)`, or (3) a comment justifying the bounded result. Use `customSelect` raw SQL for `GROUP BY ... HAVING AVG()`.

- **Gotcha 1: Nested Scaffold FAB Renders Behind Bottom Nav Bar**
  - **Problem:** `_MainShell` uses `extendBody: true` with a 96px nav bar — an inner Scaffold FAB renders behind it invisibly.
  - **Fix:** Wrap the FAB with `Padding(padding: EdgeInsets.only(bottom: 80))`.

- **Gotcha 2: FAB Inside PopupMenuButton Absorbs Tap Events**
  - **Problem:** `FloatingActionButton` inside `PopupMenuButton.child` — the FAB's InkResponse absorbs all taps, the menu never opens.
  - **Fix:** Call `showMenu()` programmatically from the FAB's `onPressed` instead.

- **Gotcha 10: Bottom Nav Label Must Be Template-Agnostic**
  - **Problem:** Context-sensitive bottom nav labels are wrong because the user has no template context outside a specific audit.
  - **Fix:** Use a generic label (e.g., `'ACTIVITY'`). Never use `'AUDIT'` or `'SURVEY'`.
