<!--
latent_space_scratchpad:
  CONSTRAINTS:
  - C1: Snapshot must happen INSIDE the existing db.SaveChangesAsync transaction in FinalizeSubmission (atomic with audit completion).
  - C2: ActionPlanService.AutoCreateAsync is already called BEFORE SaveChangesAsync - so AM lookup must happen BEFORE or IN that call.
  - C3: ActionPlanService already snapshots StoreManagerId/Name. We need to add AreaManagerId/Name to the SAME lookup block (lines 53-61).
  - C4: FinalizeSubmission already does a store_manager lookup POST-commit for notifications (lines 298-302) — we CANNOT reuse that; we need a pre-commit lookup inside the transaction.
  - C5: SyncSubmissions (mobile delta sync DTO) does NOT include manager snapshot fields. Extending it adds mobile Drift table migration.
  - C6: CachedSubmissions Drift table (tables.dart) has no areaManagerName/storeManagerName columns → needs migration.
  - C7: CachedActionPlans Drift table HAS storeManagerName but NOT areaManagerName → needs one new column.
  - C8: Backfill strategy for old completed submissions: NULL is acceptable because we're adding new nullable columns. Old data = NULL. New completions = populated.
  - C9: NO UI changes are required in Slice 1. The display logic is purely optional in Slice 3.
  - C10: StoreManagerId is missing from Submission entity. ActionPlan has it but Submission does not. Both AM and SM fields need to be added to Submission.

  SCOPE BOUNDARY (YAGNI):
  - Do NOT build a "Who was the manager?" report page.
  - Do NOT backfill old data (NULL is fine for historical records).
  - Do NOT change the RBAC access control logic — that stays dynamic.
  - Do NOT add UI label rendering in this plan (reserved for Slice 3).

  ARCHITECTURE LABEL: "Event-Driven Snapshot / Denormalization Pattern"
  
  BLAST RADIUS:
  - FinalizeSubmission.cs: HIGH RISK — it's the core audit finalization endpoint. Any bug here breaks audit submission for all users.
  - ActionPlanService.cs: MEDIUM — adding two fields to existing struct.
  - Database migration: LOW — adding nullable columns, no default values needed, zero-downtime compatible.
  - Flutter tables.dart: MEDIUM — Drift schema change requires `schemaVersion` bump and migration step.
  
  FIRST PRINCIPLES:
  Q1: Physics Limit — the system loses historical manager context at the moment of store reassignment because the dynamic lookup (ProfileStoreAssignments) reflects the CURRENT state, not past state.
  Q2: Simplest path — read the AM at finalization time and store it. The simplest version is adding 4 nullable columns and 1 DB query at finalization. We should do this.
  Q3: Blast Radius — if FinalizeSubmission fails due to our change, ALL audit submissions fail globally for ALL users.
  Q4: Observability — after deploying, query `SELECT area_manager_name, COUNT(*) FROM submissions WHERE status='completed' AND completed_at > NOW()-INTERVAL '1 day' GROUP BY area_manager_name` to confirm new submissions have the snapshot.
-->

---
conversation_id: "b94d1673-00ee-4f82-9a9f-6ec46444aa69"
---

# Implementation Plan: Historical Manager Snapshots (Double-Layered Design)

**Workflow**: /analyze-feature
**Created**: 2026-06-07T19:05:00+07:00

---

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\reports\design\historical-manager-snapshots_20260607_190500.md`

---

## Executive Summary & Out of Scope

**Goal**: When an audit (`Submission`) is finalized, snapshot the name and ID of the **Area Manager currently assigned to that store** onto the `Submission` and `ActionPlan` records. This makes historical accountability immutable even after store reassignments.

```text
[Audit Finalized]
      │
      ├─► Lookup current SM from Profiles WHERE StoreId == submission.StoreId
      ├─► Lookup current AM from ProfileStoreAssignments WHERE StoreId == submission.StoreId
      │
      ├─► submission.AreaManagerId = am.Id         (NEW)
      ├─► submission.AreaManagerName = am.FullName  (NEW)
      ├─► submission.StoreManagerId = sm.Id         (NEW on Submission — already exists on ActionPlan)
      ├─► submission.StoreManagerName = sm.FullName (NEW on Submission)
      │
      └─► ActionPlan.AreaManagerId = am.Id         (NEW)
          ActionPlan.AreaManagerName = am.FullName  (NEW)
          (StoreManagerId/Name already written by ActionPlanService)
```

**Out of Scope (YAGNI)**:
- No backfill of old completed submissions (nullable columns, NULL is acceptable).
- No UI label changes to display the historical manager name (Slice 3 only).
- No changes to RBAC dynamic access control.
- No new API endpoint — this is a write-time enrichment only.
- No admin report page showing "who managed this store at audit time".

---

## First Principles Gate

| Question | Answer |
|---|---|
| **Physics & Limit** | Dynamic lookups in `ProfileStoreAssignments` always reflect the CURRENT state. When an AM is reassigned, old audits appear under the new AM. This is because no point-in-time manager ID was written to the `submissions` table at finalization. |
| **Simplicity Check** | Simplest fix: add 4 nullable columns, add 1 DB query inside `FinalizeSubmission`, copy results. We SHOULD do exactly this — no over-engineering. |
| **Blast Radius** | `FinalizeSubmission.cs` is the global single point of audit completion. A bug here prevents ALL audit submissions from ALL users. This file must be edited with extreme care and tested. |
| **Observability** | After deploy: query `SELECT area_manager_name, COUNT(*) FROM submissions WHERE status='completed' AND completed_at > NOW()-INTERVAL '1 hour'` to confirm new rows carry the snapshot. |

---

## Six-Dimensional Impact Assessment

| Dimension | Impact |
|---|---|
| **1. Technical & Regression** | `FinalizeSubmission.cs` (HIGH) — core path. `ActionPlanService.cs` (MEDIUM). EF migration (LOW, nullable). Flutter `tables.dart` Drift schema (MEDIUM — needs `schemaVersion` bump). |
| **2. Functional — Report & Math** | No score calculation changes. Snapshot fields are informational only. |
| **2. Functional — Legacy State** | Old completed submissions get NULL for all 4 new fields. This is acceptable. No migration of old data. |
| **3. Operational & Cost** | One additional DB query per audit finalization (lookup ProfileStoreAssignments). Negligible performance cost. |
| **4. User Friction** | Zero friction change for users — purely a data enrichment at write time. |
| **5. Business Operations** | Enables compliance/accountability reporting by Operations teams who need historical "who owned this store". |
| **6. Regulatory & Security** | Positive compliance improvement. Immutable audit trail now includes manager context. No new security risk. |

---

## System Context

- **Pattern**: Denormalization / Write-time Snapshot (same pattern as `AuditorName`, `StoreName` already on `Submission`).
- **Transaction boundary**: Snapshot must be written INSIDE `strategy.ExecuteAsync` transaction in `FinalizeSubmission.cs` (before `db.SaveChangesAsync` at line 260).
- **Offline first**: Mobile receives snapshot fields via API response. These need to flow into `CachedSubmissions` Drift table.
- **RBAC**: No changes. Access control stays dynamic via `ProfileStoreAssignments`.

---

## Lifecycle Context (4-State Matrix)

| State | Behavior |
|---|---|
| **Success** | New submission has `areaManagerName` and `storeManagerName` populated. |
| **Empty** | Store has no AM assigned → `AreaManagerId = null`, `AreaManagerName = null`. System must NOT fail — graceful null. |
| **Error** | AM lookup fails (e.g., DB timeout) → transaction rolls back. Submission is NOT marked completed. |
| **Loading** | N/A — this is a backend write-time operation, no loading state. |

---

## Constraint Traceability

| Constraint | Source | Test Contract |
|---|---|---|
| C1: Snapshot is atomic with audit completion | FinalizeSubmission.cs transaction | TC-1: Submit audit → verify DB row has areaManagerName |
| C2: Snapshot captures the manager at completion time, not after reassignment | Design doc | TC-2: Reassign AM AFTER completion → old submission still shows original AM |
| C3: Missing AM gracefully defaults to null | Empty assignment scenario | TC-3: Submit audit with no AM assigned → submission saved with null fields, no error |
| C4: ActionPlans also get the AM snapshot | ActionPlanService | TC-4: Failed criterion → action plan has areaManagerName = same as submission |
| C5: Old submissions are unaffected (NULL) | Backfill strategy | TC-5: Query old submission row → areaManagerName IS NULL |

---

## Test Contracts

### TC-1: Happy Path — AM snapshot written at finalization
- **Given**: AM user assigned to Store A. Auditor creates and finalizes an audit for Store A.
- **When**: `PUT /api/submissions/{id}/finalize`
- **Then**: `Submission` row in DB has `area_manager_id = am.Id`, `area_manager_name = "AM Full Name"`.

### TC-2: Snapshot Immutability — reassignment does not mutate old records
- **Given**: AM1 assigned to Store A. Auditor completes audit → snapshotted. Admin reassigns Store A to AM2.
- **When**: Read the completed submission.
- **Then**: `submission.area_manager_name` still equals AM1's name, not AM2's.

### TC-3: Graceful null — no AM assigned
- **Given**: Store A has no AM assigned. Auditor finalizes audit for Store A.
- **When**: `PUT /api/submissions/{id}/finalize`
- **Then**: Returns `200 OK`. `area_manager_id = null`, `area_manager_name = null`. No error thrown.

### TC-4: ActionPlan propagation — AM name flows to action plan
- **Given**: AM1 assigned to Store A. Audit has a failing criterion.
- **When**: `PUT /api/submissions/{id}/finalize`
- **Then**: `ActionPlan` row has `area_manager_name = AM1.FullName`.

---

## Test Fixture & Payloads

**Required Fixture State**:
- One registered `area_manager` user.
- One `Store` seeded with a `ProfileStoreAssignment` linking the AM to the store.
- One completed `Submission` in `draft` status for finalization.
- Template with at least one failing criterion for TC-4.

**No new API request/response payload changes for Slice 1** — the snapshot is internal DB enrichment only. `SubmissionDto` will be extended in Slice 2.

---

## Tools & Commands

- **Skills needed**: `ef-core` (migration), `dotnet-scaffolding` (test setup)
- **Test command**: `cmd /c rtk proxy dotnet test tests\Checkly.Api.Tests --filter "HistoricalManager" --logger "console;verbosity=detailed"`
- **Build command**: `cmd /c rtk dotnet build server\Checkly.Api.sln`
- **Flutter build**: `cmd /c flutter analyze lib` (to verify Drift schema change)

---

## Proposed Changes

| Order | Action | File | Reason |
|---|---|---|---|
| 1 | [MOD] | `server/Common/Persistence/Entities/Submission.cs` | Add `AreaManagerId`, `AreaManagerName`, `StoreManagerId`, `StoreManagerName` nullable fields |
| 2 | [MOD] | `server/Common/Persistence/Entities/ActionPlan.cs` | Add `AreaManagerId`, `AreaManagerName` nullable fields |
| 3 | [NEW] | `server/Migrations/XXXX_AddManagerSnapshots.cs` | EF Core migration for new nullable columns |
| 4 | [MOD] | `server/Common/Services/ActionPlanService.cs` | Accept and pass `areaManagerId`/`areaManagerName` into new `ActionPlan` rows |
| 5 | [MOD] | `server/Features/Submissions/FinalizeSubmission.cs` | After SM lookup block, add AM lookup from `ProfileStoreAssignments`; write all 4 fields to `submission` |
| 6 | [MOD] | `server/Features/Submissions/Dtos.cs` | Add `AreaManagerId`, `AreaManagerName`, `StoreManagerId`, `StoreManagerName` to `SubmissionDto` |
| 7 | [MOD] | `lib/_shared/database/tables.dart` | Add `areaManagerName` to `CachedActionPlans`; add `areaManagerName` + `storeManagerName` to `CachedSubmissions` |
| 8 | [MOD] | `lib/_shared/database/app_database.dart` | Bump `schemaVersion`, add Drift migration step for new columns |

---

## Concept Diagram

```text
FinalizeSubmission.cs
        │
        ├─ [1] Load submission
        ├─ [2] Verify score
        ├─ [3] Lookup Store Manager (already done for notifications)
        ├─ [4] Lookup Area Manager ◄─── NEW: query ProfileStoreAssignments
        │       └─ am = db.ProfileStoreAssignments
        │               .Where(a => a.StoreId == submission.StoreId)
        │               .Join(db.Profiles, ...)
        │               .FirstOrDefault()
        ├─ [5] Write snapshot onto submission ◄──── NEW
        │       submission.AreaManagerId   = am?.Id
        │       submission.AreaManagerName = am?.FullName
        │       submission.StoreManagerId  = sm?.Id
        │       submission.StoreManagerName = sm?.FullName
        │
        ├─ [6] AutoCreateAsync(... areaManagerId, areaManagerName) ◄── NEW params
        │       ActionPlan.AreaManagerId   = areaManagerId
        │       ActionPlan.AreaManagerName = areaManagerName
        │
        └─ [7] db.SaveChangesAsync() ── all written atomically
```

---

## Execution Slices

### Slice 1: Backend Snapshot — Happy Path
**Complexity**: Medium
**Entry State**: Clean passing build. No `AreaManagerId` columns exist anywhere.
**Exit State**: Audit finalization atomically writes AM + SM snapshots to DB.

**Scope**:
- Modify `Submission.cs` and `ActionPlan.cs` entities.
- Create EF Core migration.
- Modify `ActionPlanService.cs` to accept and write AM fields.
- Modify `FinalizeSubmission.cs` to look up and pass AM details.

**Acceptance Criteria**:
- [TC-1] Finalizing an audit for a store with an assigned AM writes `area_manager_name` to the `submissions` DB row.
- [TC-3] Finalizing an audit for a store with NO AM writes `null` — no exception thrown.
- [TC-4] Action plans generated by the same audit also have `area_manager_name`.

**Route**: Route 4 — Double-Loop (DB changes + business logic)

---

### Slice 2: API Contract — DTO & Sync Extension
**Complexity**: Low
**Entry State**: Slice 1 complete and merged. DB columns exist.
**Exit State**: `SubmissionDto` exposes the new fields. Mobile sync includes them.

**Scope**:
- Extend `SubmissionDto` and `SubmissionDetailDto` with 4 new optional fields.
- Update all `SubmissionDto(...)` constructor call sites to pass the new fields.

**Acceptance Criteria**:
- [TC-2] GET `/api/submissions/{id}` returns `areaManagerName` on a completed submission.
- After AM reassignment, GET still returns the historical manager name (not the new AM).

**Route**: Route 3 — Acceptance Tests First

---

### Slice 3: Flutter — Drift Schema + Optional UI Label
**Complexity**: Medium
**Entry State**: Slice 2 complete. API returns `areaManagerName`.
**Exit State**: Mobile caches the new fields. Audit detail screen can optionally display them.

**Scope**:
- Add `areaManagerName` to `CachedSubmissions` and `CachedActionPlans` in `tables.dart`.
- Bump `schemaVersion` in `app_database.dart` and add Drift migration.
- Update `submission_dao.dart` to map the new fields.
- (Optional) Add a read-only info row in the audit detail screen: `"Area Manager: [Name]"`.

**Acceptance Criteria**:
- After sync, `CachedSubmissions.areaManagerName` is populated for new audits.
- App does not crash on devices with old schema (migration handles null default).

**Route**: Route 1 — Direct Build (schema is wiring, no business logic)

---

<command_logs>
- `cmd /c "python .agents/scripts/verify_sync_contracts.py && python .agents/scripts/verify_pbac_ui.py --advisory"` → Sync contracts: PASS. PBAC: pre-existing warnings only.
- Searched `ProfileStoreAssignments` references across server → 30+ files.
- Read `FinalizeSubmission.cs` (338 lines) → identified snapshot insertion point at lines 192-209 (step 5 update block).
- Read `ActionPlanService.cs` (130 lines) → SM lookup at lines 58-61. AM lookup is MISSING. This is the exact gap.
- Read `Submission.cs` → No `AreaManagerId`, `AreaManagerName`, `StoreManagerId`, `StoreManagerName` fields exist.
- Read `ActionPlan.cs` → Has `StoreManagerId`, `StoreManagerName` but NO `AreaManagerId`, `AreaManagerName`.
- Read `tables.dart` → `CachedActionPlans` has `storeManagerName` but NOT `areaManagerName`. `CachedSubmissions` has NEITHER manager snapshot field.
- Read `Dtos.cs` → `SubmissionDto` has no manager snapshot fields.
</command_logs>

---

## Handoff Block

**Plan path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\historical-manager-snapshots\implementation_plan_historical-manager-snapshots_20260607_190500.md`

Execute slices **ONE AT A TIME** in order:

- **Slice 1 (Backend DB + Logic)**: Write Acceptance Tests first (`/atdd`) → then Build (`/implement`)
- **Slice 2 (DTO Contract)**: Write Acceptance Tests first → then Build
- **Slice 3 (Flutter Drift)**: Direct Build (`/implement`)

> [!IMPORTANT]
> Slice 1 modifies `FinalizeSubmission.cs` — the global audit submission endpoint. Do not skip ATDD for this slice.
