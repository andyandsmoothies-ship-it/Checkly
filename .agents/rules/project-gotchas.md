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
| 11 | Templates | **Non-scored input types need explicit exclusion:** `text`, `single_choice`, and `multi_choice` are data-collection only. Every location that checks `pointsWeight` or shows points MUST exclude these types. Pattern appeared in 4 places: V6 save guard, criterion badge, template detail badge, save payload. When adding new UI that references `pointsWeight`, always check `inputType` first. |
| 12 | Testing | **Every [NEW] handler requires at least 2 tests before handoff:** A new endpoint is NOT done until there is a passing test for (1) the happy path and (2) the primary error path (404, 403, 409, or 400). The existing test suite going green does NOT count — it only proves you didn't break old behavior. Applies even for "Track B1" slices. Learned: Infra Slices 2&3, `GetStore.cs` and `DeleteArea.cs` were shipped green but untested. |
| 13 | Audit | **AuditSectionCard lazy-section rendering:** `audit_form_page.dart` renders exactly ONE `AuditSectionCard` at a time (`template.groups[_currentSection]`). Only a single section is ever in the widget tree. Do NOT "optimize" this by rendering all sections with `Visibility` or `IndexedStack` — that would build and hold all criterion rows simultaneously, destroying the perf model. The swipe/nav bar updates `_currentSection` via `setState` which swap-renders the one active card. |
| 14 | Drift/Performance | **Drift Query OOM Invariant:** Every function in a `*_queries.dart` or `*_manager.dart` DAO MUST satisfy one of: (1) use `selectOnly + count()/avg()`, (2) have an explicit `..limit(n)`, or (3) have a comment explicitly justifying why the result set is bounded. Any bare `.select().get()` without one of these three is an automatic OOM violation. For `GROUP BY ... HAVING AVG()`, use `customSelect` raw SQL — Drift 2.x does not expose `.having()` on `selectOnly()` results. The Verification gate MUST grep for bare `.get()` in DAO files before approving. |
| 15 | Routing | **Navigating from outside the ShellRoute to a Shell-child route:** Pages rendered outside the `ShellRoute` (e.g., Wizard, on-boarding) MUST NOT use `context.go('/templates/:id')` directly — this renders the target as a top-level route, bypassing the shell (no bottom nav, no back button). **Safe pattern**: `final router = GoRouter.of(context); router.go('/templates'); Future.microtask(() => router.push('/templates/$id'));` — restores the shell first, then pushes the detail page. Always capture `router` before the microtask to satisfy `use_build_context_synchronously`. |



