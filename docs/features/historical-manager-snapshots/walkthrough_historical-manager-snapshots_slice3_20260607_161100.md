# Walkthrough: Historical Manager Snapshots - Slice 3

This walkthrough details the changes made for Slice 3 (Flutter — Drift Schema & UI Integration).

## Diagrams

```
[Server DTO JSON] ---> [SubmissionDetailDto.fromJson] ---> [HeaderCard Widget (UI)]
```

## Changes

### 1. SubmissionDetailDto Extended
- **File**: `lib/features/audit/model/submission_detail_dto.dart`
- **Details**: Added nullable properties (`areaManagerId`, `areaManagerName`, `storeManagerId`, `storeManagerName`) to `SubmissionDetailDto` and updated the `fromJson` factory mapping to parse them from the JSON response. Added them as optional fields in the constructor to prevent breaking existing tests.

### 2. HeaderCard UI Integration
- **File**: `lib/features/audit/widgets/header_card.dart`
- **Details**: Added conditional rendering for historical `areaManagerName` and `storeManagerName` metadata rows below the completion date:
  - If `areaManagerName` is present, it renders a `MetaRow` with `Icons.supervised_user_circle_outlined` and the label `Area Manager: [Name]`.
  - If `storeManagerName` is present, it renders a `MetaRow` with `Icons.badge_outlined` and the label `Store Manager: [Name]`.

### 3. Widget & Unit Tests
- **File**: `test/features/audit/widgets/header_card_test.dart`
- **Details**: Added two new test cases:
  - `"Renders Area Manager and Store Manager info rows when present"`
  - `"Hides Area Manager and Store Manager info rows when they are null"`
