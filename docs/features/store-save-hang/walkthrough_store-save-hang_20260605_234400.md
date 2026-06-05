# Walkthrough: Store Saving Hang Fix

Workflow: /implement | Track: B1

## Input Lineage
- **Source Input**: `lib/features/admin/pages/widgets/store_form_save_logic.dart`
- **Implementation Plan**: `docs/features/store-save-hang/task_store-save-hang_20260605_164000.md`

## Decision Log
- **Proposed Design**: Wrap `isDirty = false` and `isSaving = false` mutations in `setState` before popping the route.
- **Implemented Design**: Wrapped both state mutations inside `setState` to ensure the view stops showing the progress indicator. In addition, wrapped the `Navigator.maybePop(context)` call inside a `WidgetsBinding.instance.addPostFrameCallback` callback. This ensures that the page does not attempt to pop until the next frame runs and rebuilds the `PopScope` route guard widget with `isDirty = false` (which dynamically sets `canPop` to `true`). This solves the route popping block cleanly without triggering the "Discard changes?" warning dialog.

## Verification Handoff
To manually verify:
1. Launch the Checkly Admin UI and navigate to Store Management.
2. Click the Floating Action Button to Add Store, or click edit on an existing store.
3. Enter or modify a field (making the form dirty).
4. Tap the "Create Store" or "Save Changes" button.
5. Notice that the saving animation finishes, and the bottom sheet closes immediately without any warning dialog or hang.

## Gotcha Protocol
Added the following to `lib/GEMINI.md` under state management or routing section:
- **Gotcha: Route Pop Hangs in Forms with Unsaved Changes Guard**
  - **Fix:** When saving forms protected by `UnsavedChangesGuard`, always clear `isDirty` and `isSaving` inside `setState()`, and defer calling `Navigator.maybePop(context)` using `WidgetsBinding.instance.addPostFrameCallback`. This ensures the `PopScope` has rebuilt and updated `canPop` to `true` before navigation is triggered.

## Forensic Evidence
<forensic_evidence>
Ran the following checkly verification scripts:
- PBAC UI scan: `cmd /c python .agents/scripts/verify_pbac_ui.py --advisory` (Advisory success)
- DB/API sync contract scan: `cmd /c python .agents/scripts/verify_sync_contracts.py` (Success)
</forensic_evidence>

## Test Trace
<test_trace>
```text
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/store_management_page_test.dart
00:00 +0: renders search input, status filter pill, and store cards
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
│ 💡 flutter_map
│ 💡 flutter_map wants to help keep map data available for everyone.
│ 💡 We use the OpenStreetMap public tile servers in our code examples & demo app,
│ 💡 but they are NOT free to use by everyone. Please review whether OSM's tile
│ 💡 servers are appropriate and the best choice for your app.
│ 💡 See:
│ 💡  * https://operations.osmfoundation.org/policies/tiles (OSM Tile Usage Policy)
│ 💡  * https://docs.fleaflet.dev/osm-warn for more information about this warning
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
00:07 +12: Map tap on un-addressable region preserves coordinates and shows warning SnackBar
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
│ 💡 flutter_map
│ 💡 flutter_map wants to help keep map data available for everyone.
│ 💡 We use the OpenStreetMap public tile servers in our code examples & demo app,
│ 💡 but they are NOT free to use by everyone. Please review whether OSM's tile
│ 💡 servers are appropriate and the best choice for your app.
│ 💡 See:
│ 💡  * https://operations.osmfoundation.org/policies/tiles (OSM Tile Usage Policy)
│ 💡  * https://docs.fleaflet.dev/osm-warn for more information about this warning
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
00:08 +13: All tests passed!
```
</test_trace>
