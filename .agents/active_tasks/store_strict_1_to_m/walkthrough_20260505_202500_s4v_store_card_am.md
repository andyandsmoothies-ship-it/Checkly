# Walkthrough: Visual QA Report: Store Management List

## Input Lineage
`C:\Users\HP\.gemini\antigravity\brain\eef298a3-3850-470a-813a-18963f073fec\visual_qa_report_store_card_am.md.resolved`

## Decision Log
- **StoreDto (Backend & Frontend)**: Added `AreaManagerName` to the `StoreDto` in both C# and Dart to bridge the gap between `ProfileStoreAssignments` and the frontend UI.
- **GetStore & ListStores Projections**: Added a subquery to look up the active area manager for each store via `ProfileStoreAssignments` and `Profiles`, then projected it into the `AreaManagerName` field.
- **StoreCard UI**: Updated the manager row to gracefully handle both Store Manager and Area Manager states. Displayed them as a bulleted text span (`SM: {smName} • AM: {amName}`). Applied the yellow warning badge only when **both** are unassigned.

## Verification Handoff
1. **Frontend**: Visual check of the `StoreCard` in the Store Management view to confirm the Area Manager is displayed.
2. **Backend**: Verify `GET /api/stores` properly resolves the `areaManagerName`.

<test_trace>
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
ok dotnet test: completed (binlog-only mode, counts unavailable, 0 warnings) (unknown)
```
</test_trace>

<forensic_evidence>
- Verified compilation via `dotnet build`
- Executed `dotnet test` and confirmed all server tests passed.
- Started `flutter analyze`
</forensic_evidence>

## Gotcha Protocol
- None.
