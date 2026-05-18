# Task: Infrastructure Audit — Analytics Backend
Workflow: /audit-infra | Role: Sentinel | Track: A

## Input Lineage
- **Target Files (from image)**:
  - `server/Program.cs`
  - `server/Features/Analytics/Dtos.cs`
  - `server/Common/Persistence/AppDbContext.cs`
  - `server/Features/Analytics/GetAnalytics.cs`
  - `server/Features/Analytics/AreaBenchmarkWorker.cs`
  - `server/Features/Analytics/AreaBenchmarkCalculator.cs`
  - `server/Features/Analytics/InsightGeneratorService.cs`
  - `server/Common/Persistence/Entities/AreaBenchmarkSnapshot.cs`
  - `server/Common/Persistence/Migrations/AppDbContextModelSnapshot.cs`
  - `server/Common/Persistence/Configuration/AreaBenchmarkSnapshotConfiguration.cs`
  - `server/Common/Persistence/Migrations/20260517094059_AddAreaBenchmarkSnapshot.cs`
  - `server/tests/Checkly.Api.Tests/Features/Analytics/InsightGeneratorTests.cs`
  - `server/tests/Checkly.Api.Tests/Features/Analytics/AreaBenchmarkWorkerTests.cs`
  - `server/tests/Checkly.Api.Tests/Features/Analytics/InsightsIntegrationTests.cs`

## Phases
- [x] Phase 1: Scope & Skills
- [x] Phase 2: Database & Query Audit
- [x] Phase 3: Security & Data Integrity
- [x] Phase 4: API Completeness
- [x] Phase 4.5: Telemetry & NFR Check
- [x] Phase 5: Assessment Payload
- [x] Phase 6: Deliverable Handoff

## Artifact Inventory
| Status | File Path | Type |
|--------|-----------|------|
| [NEW]  | docs/diagnostics/audit_infra_report_20260518_075030_analytics_backend.md | Audit Report |
