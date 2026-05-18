# Task: am2 Analytics 403 — Wrong Tenancy Scope (AreaId vs ProfileStoreAssignment)
Workflow: /diagnose | Track: B1

## Input Lineage
- **Source Input**: User report: am2 (area_manager role) gets 403 on GET /api/analytics. Server log: `HTTP GET /api/analytics responded 403 in 2.3ms`.
- **Context**: User confirmed AMs are scoped by **direct store assignments** (ProfileStoreAssignment junction table) — NOT by an Area foreign key on the Profile. AreaId is intentionally NULL.

## Hypotheses (Falsifiable)
1. `GetAnalytics.cs` guards AM access via `profile.AreaId != null` → fails when AreaId is NULL → 403. ✅ **CONFIRMED** (line 58-59).
2. All other AM-scoped endpoints use `ProfileStoreAssignments` junction table instead → CONFIRMED (ListActionPlans, GetAreaCampaignProgress, GetStoreDashboard, SyncProfile all use junction).
3. The fix is to swap the AM block in `GetAnalytics.cs` to use `ProfileStoreAssignments` (same pattern as ListActionPlans L48-54).

## Phases
- [x] Phase 1: Symptom Isolation
- [x] Phase 2: Skill & Rule Discovery
- [x] Phase 3: Resolution Plan
- [x] Phase 4: Deliverable Handoff

## Artifact Inventory
| Status | File Path | Type |
| [DONE] | c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260518_164958_am2_analytics_area_scope.md | Report |
| [PENDING] | c:\Users\HP\Documents\GitHub\Checkly\server\Features\Analytics\GetAnalytics.cs | Fix |

