# Walkthrough: Dashboard UX Refinement

## Input Lineage
C:\Users\HP\.gemini\antigravity\brain\493220d8-99f2-4839-9729-5c0dc0748efe\implementation_plan.md.resolved

## Decision Log
**Proposed**:
- Use subtle drop shadows for depth.
- Fix typographic hierarchy in header.
- Darken warning banner text for WCAG compliance.
- Remove green bar from feed header and make text bolder.
- Add pill styling for "Survey" trailing statuses.

**Implemented**:
- **`dashboard_page.dart`**: Increased padding before "Store Overview" and set font weight to `w800` (extra bold).
- **`hero_card.dart`**: Replaced standard border with a subtle drop shadow (`blurRadius: 10`, `offset: 0,4`, `alpha: 0.05`).
- **`deadline_banner.dart`**: Replaced standard warning color with `Colors.deepOrange.shade800` for both text and icon to ensure high contrast against the `alpha: 0.1` background.
- **`submission_feed_section.dart` & `section_header.dart`**: Stripped the green vertical container from the feed header. Strengthened `SectionHeader` across the app by increasing opacity to 0.85 and weight to `w800`.
- **`submission_row.dart`**: Redesigned the card layout. Dropped the default `Card` wrapper in favor of a custom `Container` possessing the same soft drop shadow as the `HeroCard`. Placed the "SURVEY" label inside a custom pill box to prevent it from looking like floating text.

## Verification Handoff
1. **QA/User**: Navigate to the Home page.
2. Observe the "Store Overview" text is bold and separated nicely.
3. Observe the top action cards have a soft drop shadow without harsh borders.
4. If there is a deadline banner, the text should be a darker orange that is easily readable.
5. The "RECENT ACTIVITY" header should no longer have a vertical green bar and should appear bold.
6. Survey audits in the feed should have a small background chip labeled "SURVEY".

<test_trace>
00:49 +467: All tests passed!
Exit code: 0
</test_trace>

<forensic_evidence>
- `flutter analyze`: 0 issues found.
</forensic_evidence>

## Gotcha Protocol
No new architectural or testing gotchas were discovered during this visual styling exercise.
