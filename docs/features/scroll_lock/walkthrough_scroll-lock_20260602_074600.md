---
ConversationID: dcbfac81-a3e9-4fad-af42-bc281b403b75
---

# Walkthrough: Bottom Sheets Scrolling Refactoring (Option B)

This document describes the architectural changes implemented to resolve the scroll lock issue on the Aging Buckets bottom sheets (`BodApBucketDetailSheet` and `AreaBodApBucketDetailSheet`).

## 1. Problem Description & Diagnostic

Under the initial implementation, the bottom sheets had their content structured as follows:
- A non-scrollable header area containing metadata and filters.
- An `Expanded` widget wrapping the actual lists of Action Plans (`ListView.separated`).
- This created two scroll view contexts: the bottom sheet itself, and the nested `ListView`.
- Due to nesting constraints in Flutter bottom sheets, scroll gestures over the header were ignored/locked, and the viewport was unable to roll dynamically.

## 2. Implementation: Option B (Unified Scrolling Viewport)

To match the premium feel of `BodStoreDetailSheet`, we implemented **Option B** which merges the entire sheet into a single scrollable viewport.

```
[BottomSheet Viewport (SingleChildScrollView)]
   └── [Column]
        ├── [Metadata Header]
        ├── [Aging Filters Row]
        └── [ListView.separated (NeverScrollableScrollPhysics)]
```

### Refactored Files

1. **`lib/features/analytics/widgets/bod_ap_bucket_detail_sheet.dart`**
   - Removed the nested scrolling boundaries.
   - Wrapped the list area in `Flexible` + `SingleChildScrollView` + `Column`.
   - Set the nested `ListView.separated` scroll physics to `NeverScrollableScrollPhysics()` and `shrinkWrap: true`.

2. **`lib/features/analytics/widgets/area_bod_ap_bucket_detail_sheet.dart`**
   - Applied identical refactoring to match the Area Manager's bucket sheet structure.

### Benefits of Option B
- **Dynamic Header Roll**: Tapping and dragging anywhere (including the title, summary, or filters) scrolls the whole bottom sheet smoothly.
- **Micro-Animations Compliance**: Works seamlessly with Checkly's tactile design tokens and reduced motion settings.
- **Consistent Layout**: Matches the design language of other premium details views.

## 3. Test Alignment

- **Analytics Sheet Widget Tests**: Updated the scroll physics assertions in `test/features/analytics/widgets/bod_ap_bucket_detail_sheet_test.dart` to assert that `listView.physics` is indeed `isA<NeverScrollableScrollPhysics>()` and that the parent `SingleChildScrollView` is present.
- **Notification Manager Wiring Tests**: Fixed a `GetIt` lifecycle test failure in `test/features/notifications/manager/notification_wiring_test.dart` by registering the required `ThemeSpiritNotifier` singleton.
