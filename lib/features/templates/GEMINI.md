# Templates Feature — Gotchas & Architecture Notes

## Gotcha T-01: Template `CriterionRow` is Preview-Only (STRICT BOUNDARY)
- **Problem:** There are two `criterion_row` widgets in the project: one in `templates/pages/widgets/` (preview) and one in `audit/widgets/` (full form). They must never be merged or cross-pollinated.
- **Rule:** `templates/.../criterion_row.dart` MUST NOT render descriptions, interactive inputs (ChoiceChip, etc.), or action buttons.
- **Fix:** Keep rubrics, pass/fail inputs, and info icons exclusively in `audit/widgets/audit_criterion_sheet.dart` and `audit/widgets/audit_inputs.dart`.

## Gotcha T-02: `SectionCard` Depth 0 is Now Semantically Dead in Preview
- **Context:** After the Tab Pagination refactor (March 2026), `SectionCard` is only called with `depth >= 1`. Top-level groups are rendered as `TabBar` tabs in `template_detail_page.dart`.
- **Rule:** Do NOT call `SectionCard(depth: 0)` from `template_detail_page.dart` — the weight badge and full-width styling it renders at depth 0 will never appear.
- **Future work:** If the Tab layout is ever reverted, restore `depth: 0` calls and set `initiallyExpanded: true` for root sections.
