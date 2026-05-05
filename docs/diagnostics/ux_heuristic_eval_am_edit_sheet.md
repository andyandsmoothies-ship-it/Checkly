# UX Heuristic Evaluation: Admin Area Manager Edit Sheet

## Summary
The UI implements the requested features (Virtual Area Batching + Direct Store Checkboxes), but introduces a critical layout flaw that breaks the bottom sheet on smaller devices. Furthermore, the cognitive disconnect between the Batch Dropdown and the individual checkboxes creates ambiguity about what will actually happen when the user clicks Save.

## Scorecard
| Heuristic | Status |
|---|---|
| H1: Visibility of system status | ⚠️ Minor Violation |
| H2: Match between system and real world | ✅ Pass |
| H3: User control and freedom | ✅ Pass |
| H4: Consistency and standards | ❌ Critical Violation |
| H5: Error prevention | ✅ Pass |
| H6: Recognition rather than recall | ❌ Major Violation |
| H7: Flexibility and efficiency of use | ✅ Pass |
| H8: Aesthetic and minimalist design | ✅ Pass |
| H9: Help users recognize errors | ✅ Pass |
| H10: Help and documentation | ✅ Pass |

## Sorted Findings

### H4: Consistency & Standards (Missing Scrollable Wrap)
- **Severity**: 4 (Catastrophe)
- **Location**: `UserEditSheet` Layout (Line 128)
- **Issue**: Unlike `UserCreateSheet`, the main `Column` in `UserEditSheet` is not wrapped in a `SingleChildScrollView`. Because you added a `maxHeight: 200` container for the new store list, this bottom sheet is now too tall. When the keyboard opens to edit the Full Name, or on smaller mobile devices, the sheet will immediately throw a `RenderFlex overflowed` exception and break the UI.
- **Recommendation**: Wrap the main `Column` (inside the `Padding`) with a `SingleChildScrollView`.

### H6: Recognition rather than recall (Decoupled Form State)
- **Severity**: 3 (Major)
- **Location**: "Batch Assign" Dropdown vs "Direct Store" Checkboxes
- **Issue**: When an Admin selects an area from the "Batch Assign" dropdown, the checkboxes in the "Direct Store Assignments" list do NOT visually update to show which stores are inside that area. The Admin is forced to guess/recall what the Area encompasses. Additionally, if the Admin selects an Area AND manually checks/unchecks stores, the UI does not explain how the backend merges these conflicts (usually `virtualAreaId` overrides the list on the backend).
- **Recommendation**: Add helper text below the dropdown: *"Note: Selecting an area will override the individual store selections below upon saving."* Or, disable the `ListView` checkboxes when an Area is selected.

### H1: Visibility of System Status (Missing Loading State)
- **Severity**: 2 (Minor)
- **Location**: `DIRECT STORE ASSIGNMENTS` list container
- **Issue**: When the role is switched to `area_manager`, `_loadStores()` fires. Because there is no `isLoadingStores` boolean flag in the state, the `ListView` container briefly shows *"No active stores found."* before the network request finishes and populates the list. This creates a confusing flash of incorrect empty state.
- **Recommendation**: Add a `bool _isLoadingStores` state. Show a `CircularProgressIndicator` inside the container while `true`.

## Top 3 Fix Priorities
1. **[SEV 4] Add `SingleChildScrollView`**: This is a blocking bug. The sheet will crash on text input without it.
2. **[SEV 3] Clarify the State Conflict**: Disable the checkboxes if `selectedAreaId != null`, or add helper text explaining the override behavior so users aren't confused about why their manual checkboxes were ignored.
3. **[SEV 2] Add Loading Spinner**: Prevent the false "No active stores found" flash.

## Tradeoffs
- **Vertical Space vs UX**: Using a 200px constrained `ListView` inside a BottomSheet is a known tradeoff (nested scrolling). However, given that Checkly stores can number in the dozens, an inline scrolling list is vastly preferable to navigating to a separate screen just to pick stores, keeping the edit flow centralized.

## Handoff
Route fixes through `/analyze-feature` -> `/implement` using this exact path: `docs/diagnostics/ux_heuristic_eval_am_edit_sheet.md`
