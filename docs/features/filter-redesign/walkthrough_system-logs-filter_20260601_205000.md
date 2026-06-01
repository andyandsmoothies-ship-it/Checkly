---
conversation_id: "dcbfac81-a3e9-4fad-af42-bc281b403b75"
---

# Walkthrough: System Logs Filter Redesign

We have successfully refactored the filtering UI of the **System Logs** page to match Checkly's premium mobile design system. 

```
[System Logs Page]
      │
      ├── [Date Filter Pill] ──> Opens [Date Bottom Sheet (All / Custom Range)]
      │
      └── [Level Filter Pill] ──> Opens [Level Bottom Sheet (All / INFO / WARN / ERROR)]
```

## 1. Context & Rationale
Previously, `SystemLogsPage` used a horizontal row of `FilterChip` widgets for log level selection alongside a simple `TextButton.icon` for selecting date ranges. This layout suffered from the following issues:
* **Cluttered UI**: Horizontal rows of multiple chips take up vital screen real estate and cause horizontal scrolling overflow issues on smaller device screens.
* **Inconsistent Aesthetics**: Unaligned filter controls disrupted the premium "Duolingo-style" layout guidelines of the platform.
* **Accessibility**: Small buttons and chips made touch targets tight on mobile screens.

## 2. Refactored Solutions
We completely unified these controls under a single scrollable row utilizing:
1. **`DropdownFilterPill`**: An interactive, rounded container with animated borders that shifts colors dynamically when filters are active.
2. **`showLogLevelFilterSheet`**: A native bottom sheet containing explicit, comfortable options representing each log level with custom semantic color indicators:
   * **ALL**: Neutral (`AppColors.eel`)
   * **INFO**: Macaw Blue (`AppColors.macaw`)
   * **WARN**: Fox Orange (`AppColors.fox`)
   * **ERROR**: Cardinal Red (`AppColors.cardinal`)
3. **`showLogDateFilterSheet`**: A native bottom sheet allowing the auditor to select a custom range via the calendar popup or quickly purge date-range configurations.

---

## 3. Implementation Summary

### `lib/features/admin/pages/system_logs_page.dart`
* **Imports**: Added `import '../../../_shared/theme/app_colors.dart';`
* **Toolbar Design**: Removed `TextButton.icon` and raw `FilterChip` map rendering, replacing them with a single `SingleChildScrollView` row containing two `DropdownFilterPill` widgets.
* **State Operations**: Wire the pill `onTap` triggers to modern asynchronous modal bottom sheets, allowing selected parameters to bubble back to `_onLevelChanged` and state refreshes automatically.
* **Removed Dead Code**: Deleted unused static private field `_levels` to keep the module clean and light.
* **Modernized API**: Replaced deprecated `withOpacity(0.1)` method calls with `.withValues(alpha: 0.1)` on `AppColors.featherGreen` for zero precision loss.
