---
name: Project Gotchas & Lessons
description: Continuous log of critical project-specific lessons, gotchas, and patterns.
trigger: always_on
---

# Project Gotchas & Lessons — Checkly

## CRITICAL GOTCHAS

| # | Category | Description |
|---|----------|-------------|
| 1 | Layout | **Nested Scaffold + FAB invisibility:** `_MainShell` (ShellRoute) wraps pages in a Scaffold with `extendBody: true` and a 96px bottom nav bar. Child pages have their OWN inner Scaffold. Any `floatingActionButton` in the inner Scaffold MUST have `Padding(bottom: 80)` or it renders behind the nav bar and is invisible. |
| 2 | Gesture | **FloatingActionButton inside PopupMenuButton:** Do NOT wrap a `FloatingActionButton(onPressed: ...)` inside `PopupMenuButton.child`. The FAB's InkResponse absorbs tap events. Use `showMenu()` programmatically from the FAB's `onPressed` instead. |
| 3 | Routing | **Route registration order matters:** Specific routes (e.g., `/api/submissions/survey-results`) MUST be registered BEFORE catch-all routes (e.g., `/api/submissions/{id}`), otherwise the catch-all swallows the request and tries to parse `survey-results` as a GUID. |
| 4 | EF Core | **Explicit `HasColumnName` required:** This project uses explicit `HasColumnName("snake_case")` in `AppDbContext` for ALL columns. EF will NOT auto-map `ScoringMode` → `scoring_mode`. Forgetting this causes silent column mismatches. |
| 5 | Scoring | **Survey mode = null TotalScore:** Survey submissions intentionally have `TotalScore = null`. Any analytics query averaging scores MUST filter `WHERE scoring_mode != 'survey'` or `WHERE total_score IS NOT NULL` to avoid division errors. |
| 6 | Sync | **New DTO fields must flow through sync pipeline:** When adding a field to Template or Submission, you must update: (1) Entity, (2) DbContext mapping, (3) Server DTO record, (4) ALL endpoint projections, (5) Sync endpoint projection, (6) Flutter DTO class + fromJson. Missing any one causes the field to silently drop during offline sync. Verified pattern: `ScoringLogicConfig`, `DisplayNoun`. |
| 7 | Snapshot | **Denormalized fields need dual writes:** Snapshot fields (e.g., `TemplateTitle`, `DisplayNoun`) must be written in BOTH `CreateSubmission` AND `FinalizeSubmission`. Missing either causes null snapshots for draft-then-finalize flows vs direct-complete flows. |
| 8 | Analytics | **SectionScores is jsonb, not relational:** `Submission.SectionScores` stores `{"Section": {"score": 82, "maxScore": 100}}` as jsonb. Cannot use EF `GroupBy` on dynamic keys — must load the jsonb strings and parse in C#. GIN index (`jsonb_path_ops`) enables future raw SQL queries. |
| 9 | Migration | **EF migration generator picks up all pending changes:** Running `dotnet ef migrations add` captures ALL unmigrated model changes, not just the one you intended. Review the generated migration file before committing — remove unrelated changes or split into separate migrations. |
| 10 | Bottom Nav | **Bottom nav label is template-agnostic:** The bottom nav tab cannot change per-template because the user isn't viewing a template context when they see the nav. Label must be generic (e.g., `'ACTIVITY'`), not mode-specific. |
