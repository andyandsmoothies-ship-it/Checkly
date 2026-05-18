# Walkthrough: Analytics Insight Generator (Slice 2)

## Overview
This walkthrough summarizes the completion of Slice 2 for the Analytics Rewire. We implemented the `InsightGeneratorService` to generate AI-like actionable insights based on mathematical heuristics and integrated it into the `GetAnalytics` API endpoint, fully resolving the requirements in the Slice 2 plan.

## Changes Made

### 1. Extended DTOs (`Dtos.cs`)
- Added `ActionableInsight` record to map insight structure (`Id`, `Type`, `Title`, `Description`).
- Added `RadarData` record to map categorized spider-chart data comparing Store vs Area scores.
- Extended the existing `AnalyticsResponse` record with `Insights`, `RadarData`, and `InsightsStale` fields.

### 2. Insight Generator Service (`InsightGeneratorService.cs`)
- Created a pure, stateless `static` service to encapsulate heuristic rules.
- Implemented **Guard 1 (Sparsity)**: Suppresses Radar charts and standard insights when `< 3` total audits, generating a single "Insufficient Data" info insight.
- Implemented **RadarData Logic**: Intersects the Store and Area category dictionaries and generates ordered series lists, conditionally suppressed if `< 3` categories are matched.
- Implemented **Rule 1 (SCORE_DROP_WARNING)**: Fires if store is 1.5 standard deviations below area average.
- Implemented **Rule 2 (SCORE_POSITIVE)**: Fires if store is 1 standard deviation above area average.
- Implemented **Rule 3 (CATEGORY_WEAK)**: Fires if any specific category score drops > 10 points below the area average.
- Implemented **Rule 4 (CATEGORY_STRONG)**: Fires if any specific category score exceeds > 10 points above the area average.
- Implemented **Rule 5 (OAP_HIGH)**: Fires if there are > 0 overdue action plans.
- Implemented **Capping Logic**: Applies a `.Take(3)` limit to the aggregated insights to prevent UI overload.

### 3. API Integration (`GetAnalytics.cs`)
- Retrieved the pre-computed `AreaBenchmarkSnapshot` from the local database.
- Resolved `areaId` correctly regardless of whether the caller is a Store Manager or Area Manager.
- Parsed the JSONB `CategoryAverages` field into a generic Dictionary.
- Injected `InsightGeneratorService.Generate()` right before endpoint termination, avoiding any side-effects on existing SQL queries or KPI math.
- Added `insightsStale` flag logic for benchmarking data older than 2 hours.

## What Was Tested
- The pre-existing TDD unit tests (`InsightGeneratorTests`) and integration tests (`InsightsIntegrationTests`) were successfully resolved and transitioned from RED to **GREEN**.
- `InsightGeneratorTests` strictly validated that:
  - High scores trigger positive insights (IG-02).
  - Low scores trigger warnings (IG-03).
  - Multi-rule violations trigger the capping limit of 3 (IG-08).
  - The sparsity guard fires cleanly (TotalAudits < 3).

## Validation Results
All code compiled correctly with zero warnings. Tests have been executed and the executed tests artifact was updated successfully. The Backend API is now structurally compliant with the requirements and ready for the upcoming Flutter UI frontend (Slice 3).

---
> [!TIP]
> The `InsightGeneratorService` was purposely designed as static and stateless, ensuring this domain logic remains 100% testable via unit tests. No mocked databases or scoped dependencies are required to validate insight math.
