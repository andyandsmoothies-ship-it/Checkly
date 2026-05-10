# Walkthrough: Audits/Activity Page Visual UX Refinement (Chunk 2)

## Input Lineage
`C:\Users\HP\.gemini\antigravity\brain\493220d8-99f2-4839-9729-5c0dc0748efe\visual_qa_report_chunk2.md.resolved`

## Decision Log
- **Depth & Consistency (`audit_card.dart`)**:
  - *Proposed*: Remove default flat card border, apply subtle drop shadow (`blurRadius: 10`, `alpha: 0.05`).
  - *Implemented*: Replaced `Card` with a `Container` featuring a white surface background, rounded border, and the requested `BoxShadow` to match the dashboard aesthetics. Added a `Material` wrapper inside to ensure `InkWell` ripple effects still function properly without breaking the corners.
- **Category Badges (`audit_card.dart`)**:
  - *Proposed*: Soften to `BorderRadius.circular(6)`, increase horizontal padding, adjust color contrast slightly.
  - *Implemented*: Changed padding from `horizontal: 6` to `horizontal: 10`. Softened border radius to `6`. Lowered background opacity to `0.5` to make it visually less dominant.
- **Action Buttons (`audit_card.dart`)**:
  - *Proposed*: Upgrade bare red `IconButton` to `IconButton.filledTonal` using `cancel_outlined` with a soft red tint.
  - *Implemented*: Wrapped the block icon button in an `IconButton.filledTonal` widget, utilizing `theme.colorScheme.error.withValues(alpha: 0.1)` for the background, and swapped `Icons.block` for `Icons.cancel_outlined`.
- **Status Badges (`audit_card.dart`)**:
  - *Proposed*: Increase font weight for EXPIRED/COMPLETED chips.
  - *Implemented*: Changed the status badge font weight from `FontWeight.w600` to `FontWeight.w800` to match the bolder aesthetic without losing accessibility.
- **Group Headers (`store_group.dart`)**:
  - *Proposed*: Increase top/bottom padding around the header.
  - *Implemented*: Added `tilePadding: const EdgeInsets.symmetric(vertical: 8)` to the `ExpansionTile`.

## Verification Handoff
1. Open the **Audits/Activity** page on any device.
2. Verify that the list of audits are separated into distinct "floating" cards with soft shadows.
3. Check the "Qc" category badges; they should appear softer and wider than before.
4. If a scheduled or draft audit exists, ensure the Void button is a light-red circle with an outlined X rather than a bare dark-red block icon.
5. Check store group headers ("CHECKLY D10 - SU VAN HANH"). They should have more vertical breathing room than before.

<test_trace>
```
00:04 +59: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:04 +60: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:04 +61: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:04 +62: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:04 +63: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: (tearDownAll)
00:04 +63: All tests passed!
```
*Note: The global test suite reported 4 failures unrelated to this UI change (in `photo_queue_service_test.dart`). A targeted `flutter test test/features/audit` was run to verify zero blast radius in the active module.*
</test_trace>

<forensic_evidence>
```
> flutter test
> flutter test test/features/audit
```
</forensic_evidence>

## Gotcha Protocol
No new gotchas identified during this UI iteration.
