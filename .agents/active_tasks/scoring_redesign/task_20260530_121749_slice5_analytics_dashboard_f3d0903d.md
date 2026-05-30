# Task Tracker: Scoring Redesign — Slice 5: Analytics Dashboard Filter

Topic: `scoring_redesign`
Conversation ID: `f3d0903d-1b05-4a39-813d-fee3d9016fa7`
Status: COMPLETED

## ASCII Flowchart of Data Flow
```text
[User opens Filters] ──► [AnalyticsFilterSheet displays Category Tag dropdown]
                                        │
                                        ▼ (manager.selectedCategoryTag = 'compliance')
                               [AnalyticsManager.load()]
                                        │
                    ┌────────────────────┴────────────────────────┐
                    │ ONLINE                                        │ OFFLINE
                    ▼                                               ▼
        [AnalyticsApiService.getAnalytics(               [analytics_drift_loader.dart]
          categoryTag: 'compliance')]                    filter CachedSubmissions by
                    │                                    templateId in templates where
                    ▼                                    categoryTag == 'compliance'
        [GET /api/analytics?categoryTag=compliance]
                    │
                    ▼
        [GetAnalytics.cs] filter:
          query.Where(s => s.CategoryTag == categoryTag)
                    │
                    ▼
        [AnalyticsResponse adds categoryTagNames list]
                    │
                    ▼
        [Flutter renders chip + count updates]
```

## Task Checklist

### Slice 1 (Happy Path): Backend Filter + Legacy Cleanup
- [x] Fix syntax/compilation errors in the QA-provided test file `ScoringRedesignSlice5Tests.cs` (change `SubmittedAt` to `CompletedAt`, cast `TotalScore` to decimal)
- [x] Add `categoryTagNames` distinct non-null string list to `AnalyticsResponse` in `server/Features/Analytics/Dtos.cs`
- [x] Replace `scoringMode` filter query param with `categoryTag` in `server/Features/Analytics/GetAnalytics.cs`
- [x] Clean up legacy `ScoringMode` string checks in `server/Features/Analytics/GetAnalytics.cs` (scored query, survey count checks)
- [x] Run backend tests using `rtk dotnet test` to ensure all C# tests are green (TC-01 through TC-04)

### Slice 2: Flutter State + API + Offline Integration
- [x] Update `lib/features/analytics/manager/analytics_data.dart` to include `categoryTagNames`
- [x] Update `lib/features/analytics/services/analytics_api_service.dart` to support optional `categoryTag` parameter
- [x] Update `lib/features/analytics/manager/analytics_manager.dart` to handle `selectedCategoryTag` and parse `categoryTagNames` from the response
- [x] Update `lib/features/analytics/manager/analytics_drift_loader.dart` to filter cached templates by categoryTag and cascade to submissions
- [x] Verify Flutter offline loaders with unit/widget tests

### Slice 3: Visual Resiliency (UI Dropdown & Chips)
- [x] Update `lib/features/analytics/widgets/analytics_filter_sheet.dart` to add the Category Tag dropdown
- [x] Update `lib/features/analytics/pages/analytics_filter_chips.dart` to add the dismissible InputChip for selectedCategoryTag
- [x] Update `lib/features/analytics/pages/analytics_page.dart` to count selectedCategoryTag in `_activeFilterCount`
- [x] Run full `rtk flutter analyze` and `rtk flutter test` to ensure everything is structurally sound

## Artifact Inventory
| Status | File Path | Type |
|---|---|---|
| [NEW] | docs/architecture/scoring_redesign/walkthrough_20260530_121749_slice5_f3d0903d.md | Walkthrough |
| [NEW] | docs/qa/gates/scoring_redesign/green_test_log_20260530_121749_slice5_f3d0903d.md | Test Log |
