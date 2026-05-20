# Walkthrough: Split store_form_sheet.dart into 3 files

```
store_form_sheet.dart (424 lines → BEFORE)
│
├── [EXTRACT] _saveStore() + _loadProvinces() + markDirty()
│             → store_form_save_logic.dart  (mixin StoreFormSaveLogic)
│
├── [EXTRACT] build() widget tree (entire Column children)
│             → store_form_body.dart  (stateless StoreFormBody)
│
└── [KEEP]    shell: StoreFormSheet + showStoreFormSheet() + controller init
              → store_form_sheet.dart  (~140 lines AFTER)
```

## Input Lineage

`C:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\pages\widgets\store_form_sheet.dart`

## Decision Log

| Proposed | Implemented | Reason |
|---|---|---|
| Extract save logic as plain functions | Extracted as `mixin StoreFormSaveLogic` | Mixin allows `setState()` calls and `mounted` checks without passing BuildContext manually |
| Remove `_markDirty` | Renamed to `markDirty()` on the mixin | Makes it a public contract that `StoreFormBody` callbacks can invoke |
| Move `_provinces`, `_provincesLoading`, `_isSaving`, `_isDirty` to mixin | Done — mixin owns these fields | State that the save logic reads/writes lives next to the logic that mutates it |
| `StoreFormBody` imports StoreApiService | Rejected — it imports only `flutter_map`, `latlong2`, `StoreLocationMapWidget` | Arch boundary: UI files must not import API/DB layers |
| Single `onSaved` callback name in mixin | Kept as `onSaved` getter | Mixin must declare a getter contract; host overrides it with `widget.onSaved` |

## Verification Handoff

1. **Build check**: Run `flutter analyze` from the project root or `lib/`. Expect **No issues found**.
2. **Test regression**: Run `flutter test` from project root. Expect **539 passed, 0 failed**.
3. **Manual smoke test**: Open the app as Admin → Store Management → tap **Add Store** or **Edit**. The modal must open, all fields must be present and editable, Save must work.
4. **Import unchanged**: `store_management_page.dart` still imports only `widgets/store_form_sheet.dart` — no change needed there.

## Gotcha Protocol

**No new gotchas.** One note to consider adding to `lib/GEMINI.md`:

> **Mixin-based State Decomposition**: When a `State<T>` class exceeds 400 lines due to mixed UI/logic, prefer extracting logic into a `mixin … on State<T>` rather than a helper class. The mixin can access `setState()`, `mounted`, and `context` directly without BuildContext threading.

<test_trace>
## flutter analyze
```
Analyzing lib...
No issues found! (ran in 99.4s)
```

## flutter test (global suite)
```
00:00 +0: loading ...
...
01:07 +539: All tests passed!
Exit code: 0
```
</test_trace>

<forensic_evidence>
## Files read before editing
- `view_file(store_form_sheet.dart)` → 424 lines confirmed, full content read
- `grep_search(store_form_sheet, lib/*.dart)` → 1 importer: `store_management_page.dart:16`
- `dir /s /b "*store_form*"` (test/) → no existing tests found

## Files written
- [NEW] `lib/features/admin/pages/widgets/store_form_save_logic.dart` (~120 lines)
- [NEW] `lib/features/admin/pages/widgets/store_form_body.dart` (~230 lines)
- [MOD] `lib/features/admin/pages/widgets/store_form_sheet.dart` (424 → ~140 lines)

## Importer unchanged
- `store_management_page.dart` import `'widgets/store_form_sheet.dart'` — no change needed
</forensic_evidence>
