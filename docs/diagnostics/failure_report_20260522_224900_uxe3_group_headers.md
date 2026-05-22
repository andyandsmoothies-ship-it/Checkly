# Failure Report: Inconsistent Store Group Headers

## Input Lineage
- Source Input: User provided screenshots comparing the "Activity (Audits)" tab and "Action Plans" tab group headers.

## Root Cause
The inconsistency is caused by **Duplicate Code with Drifted Styling**. 

When we implemented the `UniversalListCard` in the previous step, we standardized the *cards themselves* (the children of the list). However, we did not touch the `ExpansionTile` wrappers that group these cards by store. 

Currently, the app has two completely separate implementations of a `StoreGroup` widget:
1. `lib/features/audit/widgets/store_group.dart`
2. `lib/features/action_plans/widgets/store_group.dart`

**Explicit Code Trace (Premises + Proof)**
*   **Audit's `StoreGroup`**:
    *   **Typography**: Uses `AppFonts.displayStyle(...)` with `fontWeight: FontWeight.w700`, `letterSpacing: 3`, and `color: onSurface.withValues(alpha: 0.65)`.
    *   **Badge**: A borderless container colored with `theme.colorScheme.primary.withValues(alpha: 0.1)`.
    *   **Padding**: `tilePadding: const EdgeInsets.symmetric(vertical: 8)`.
*   **Action Plan's `StoreGroup`**:
    *   **Typography**: Bypasses the theme and hardcodes `fontFamily: 'Nunito'`, `fontWeight: FontWeight.w900`, `letterSpacing: 2`, and `color: AppColors.wolf`.
    *   **Badge**: A container with `AppColors.seaSponge`, a 2px border of `AppColors.turtle`, and `AppColors.macaw` text.
    *   **Padding**: `tilePadding: EdgeInsets.zero`.

This explains why Image 1 (Audits) looks light grey and heavily letter-spaced, while Image 2 (Action Plans) looks dark, thicker, tighter, and uses a green-bordered badge.

## Proposed Scope-Limited Fix
We need to apply the exact same "Universal Primitive" strategy we used for the cards to the headers.

1. **Create `StoreGroupHeader` Primitive**: Create `lib/_shared/widgets/primitives/store_group_header.dart`. This widget will act as a standard wrapper for `ExpansionTile`.
2. **Apply the "Deep Spirit" Style**: The `StoreGroupHeader` will strictly define the typography (e.g., `letterSpacing: 2`, `w900`, matching the "Action Plans" style which feels more "Deep Spirit" gamified) and use a standard `PillChip` or a custom badge for the count.
3. **Delete Duplication**: Replace both `lib/features/audit/widgets/store_group.dart` and `lib/features/action_plans/widgets/store_group.dart` with this single primitive.

**Trade-offs / Pros & Cons:**
*   **Pros**: Zero visual drift in the future. Fixing the header in one place fixes it for the entire app. It also deletes redundant duplicated code, which is a key architectural rule.
*   **Cons**: Slight layout shifts may occur in the audit tab since it will adopt the new unified padding/spacing rules.

<forensic_evidence>
```bash
# Searched for "class.*Group" and "class.*Header" in lib/features/action_plans
grep_search Query="class.*Group" SearchPath="lib/features/action_plans"
# Found lib/features/action_plans/widgets/store_group.dart
view_file AbsolutePath="lib/features/action_plans/widgets/store_group.dart"
view_file AbsolutePath="lib/features/audit/widgets/store_group.dart"
```
</forensic_evidence>

## Handoff Block
1. **Final Diagnostic Verdict**: The Store Group headers are inconsistent because they are duplicated components (`features/audit/widgets/store_group.dart` vs `features/action_plans/widgets/store_group.dart`) with drifted, hardcoded styling. 
2. **Fix & Blast Radius**: We must create a `StoreGroupHeader` shared primitive and refactor both features to use it. Blast radius is low to medium (affects list views on Action Plans and Audits screens).
3. **AI Agent Mission Brief**: Implement the `StoreGroupHeader` primitive in `_shared/widgets/primitives`, then delete the two duplicated `StoreGroup` widgets and map their consumers to the new shared primitive to enforce 100% visual consistency.
4. **Execution Queue**:
- [ ] Execute Build Phase: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260522_224900_uxe3_group_headers.md`
