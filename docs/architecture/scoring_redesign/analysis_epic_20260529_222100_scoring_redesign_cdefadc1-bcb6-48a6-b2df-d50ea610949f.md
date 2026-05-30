<latent_space_scratchpad>
## Pattern Label
This is a **Domain Model Restructuring** (Data Model State Migration) epic.
The core change is collapsing a 4-value enum/string into a 2-field orthogonal model.

## Key Risks
1. Blast radius is VERY LARGE: ScoringMode touches 50+ files (Flutter + .NET), DB schema, sync, test fixtures.
2. The `ScoringMode` column on `Submissions` table is a denormalized cache — it must be migrated AND its write logic changed.
3. ScoringConfigParser in C# reads a raw JSON string from the DB — the JSON shape must change alongside.
4. Checklist Mode currently has a "fallback" in PenaltyCalculator when weights are null — this coupling must be cleanly removed.
5. Analytics snapshot jobs read scoring_mode to build boardroom reports — must be updated.

## Shape Options
- Shape A: Keep old enum in DB, add new columns, map in application layer (Strangler Fig)
- Shape B: Hard cut — new columns replace old string, one-time data migration
- Chosen: Shape A for DB backward compat (less risk), Shape B for application/UI code (clean cut)
</latent_space_scratchpad>

# Epic Plan: Scoring Mode Redesign (Two Toggles + Category Tags)

**Created**: 2026-05-29  
**Author**: Antigravity AI  
**Epic ID**: SCORING-REDESIGN  
**Status**: PLANNING

---

## Input Lineage

- **Source**: Architectural discussion in conversation `cdefadc1-bcb6-48a6-b2df-d50ea610949f`
- **Key Files Analyzed**:
  - `lib/_shared/services/scoring_mode.dart`
  - `lib/_shared/services/scoring_engine.dart`
  - `server/Common/Scoring/ScoringCalculators.cs`
  - `server/Common/Scoring/ScoringConfigParser.cs`
  - `lib/features/templates/widgets/metadata_form_card.dart`
  - `lib/features/templates/utils/dart_template_linter.dart`

---

## Executive Summary

The current system uses a **4-value scoring mode string** (`penalty`, `accumulation`, `checklist`, `survey`) that creates:
- Confusing UI for template creators ("Penalty" sounds scary for daily checklists)
- Hidden mathematical overlap (`checklist` ≈ `penalty` with null weights)
- Reporting ambiguity (all penalty-mode templates are grouped together regardless of intent)

**The proposed fix** replaces the single `scoringMode` field with **two orthogonal toggles** and adds a mandatory **Category Tag**, resulting in a cleaner, more expressive system:

```text
OLD: scoringMode = "penalty" | "accumulation" | "checklist" | "survey"

NEW:
  scoreDirection = "up" | "down" | "none"    (was: accumulation | penalty+checklist | survey)
  isWeighted     = true | false              (was: penalty | checklist)
  categoryTag    = "compliance" | "routine" | "financial" | ...  (NEW)
```

---

## Decision Matrix

| Requirement | Shape A: Strangler Fig (Keep old DB col, map in app) | Shape B: Hard Cut (New cols, migrate old) |
|---|:---:|:---:|
| R1: No data loss for existing audits | ✅ | ✅ (via migration script) |
| R2: Template builder shows clean UI | ✅ | ✅ |
| R3: Backend math unchanged (same formulas) | ✅ | ✅ |
| R4: Dashboard can filter by category | ❌ (tag is new regardless) | ✅ |
| R5: Sync contract between Flutter and .NET | ⚠️ (double field mapping) | ✅ (clean new DTO) |
| R6: Tests remain green without mass rewrites | ❌ (two systems in parallel = brittle) | ✅ |
| R7: No orphaned legacy code | ❌ | ✅ |

**Winner: Shape B (Hard Cut)**  
Rationale: The Strangler Fig approach doubles the complexity of every switch/case statement across 50+ files for a temporary gain. A clean migration is safer long-term.

---

## Risk Assessment

### Risk 1: Blast Radius (HIGH)
- `ScoringMode` is referenced in **50+ files** across Flutter and .NET.
- **Mitigation**: Slice the work strictly by layer. Change the Flutter enum first (compile error = free impact map). Then change .NET. Run full test suite between each layer.

### Risk 2: DB Migration Fails on Production Data (HIGH)
- Old `ScoringMode` column contains raw strings. A bad migration drops data.
- **Mitigation**: Write the migration in two phases: (1) ADD new columns, (2) backfill with CASE statements, (3) only then drop old values. Never drop the column in the same migration as the backfill.

### Risk 3: ScoringConfigParser JSON Shape Change (MEDIUM)
- The `ScoringLogicConfig` JSON blob currently stores `{"scoringMode":"penalty"}`. This shape must change to `{"scoreDirection":"down","isWeighted":true}`.
- **Mitigation**: 100% Hard Cut on the JSON API. Drop `scoringMode` entirely and only expect `scoreDirection` and `isWeighted`. No backward-compatibility code needed since the app is unpublished, keeping the backend perfectly clean.

### Risk 4: Broken Snapshot Analytics (MEDIUM)
- BOD/Province/Area snapshot jobs filter submissions by `ScoringMode`. After migration, these queries need updating.
- **Mitigation**: Update snapshot jobs in the same slice as the DB migration (they are in the same layer).

### Risk 5: Missing Category Tag (LOW)
- If existing templates are migrated without a Category Tag, dashboards will show blank categories.
- **Mitigation**: The migration script assigns a **default Category Tag** (`routine`) to all existing templates. Admins can re-tag later.

---

## Visual & Functional Context

### UI Screens Affected

| Screen | What Changes |
|--------|-------------|
| Template Builder — Step 1 (Metadata) | Replace scoring mode dropdown with Two Toggle selectors |
| Template Builder — Step 2 (Sections) | `WizardModeBanner` reads new fields instead of old string |
| Template Builder — Criterion Editor | Weight field visibility driven by `isWeighted` flag |
| Template Builder — Footer / Save Button | Linter validation uses new fields |
| Dashboard — Score Filters | Add Category Tag filter dropdown |
| Audit Detail Screen | Score display unchanged (scores are still 0-100 percentages) |

### New Template Builder UI Flow

```text
Step 1 — Metadata Form:

 [Question A: How does this template score?]
   (o) Down from 100  — Mistakes lose points
   ( ) Up from 0      — Correct answers earn points
   ( ) No Score       — Survey only, no math

 [Question B: How are points calculated?]   <- Hidden when "No Score" selected
   (o) Weighted       — Sections must sum to 100%
   ( ) Flat Points    — Raw point deductions, no % rules

 [Question C: What category is this audit?]   <- MANDATORY
   [ Compliance v ]
```

---

## System Context

| Constraint | Current | After Redesign |
|------------|---------|----------------|
| Offline-first | Scoring runs on device (Flutter) | Unchanged |
| Sync | `scoring_mode` string sent in sync DTO | Replaced with `score_direction` + `is_weighted` |
| RBAC | No change to permission model | Unchanged |
| API Contract | `ScoringLogicConfig` JSON blob | JSON blob shape changes + new `category_tag` field |

---

## Lifecycle Context

### Edge Cases

| Case | Behavior |
|------|----------|
| User selects "No Score" then tries to add weights | Weight fields are hidden; impossible |
| Old `checklist` template loaded by new app | N/A (Hard cut API; old templates must be migrated in DB) |
| New template synced to old app version | Old app falls back to `penalty` (legacy default) |
| Category tag is empty | Linter blocks Save. Field is mandatory |
| `isWeighted = true` but sections have no weights | Linter shows existing "sections must sum to 100" error |

### Rollback Plan
- If migration fails: The two new columns are nullable. Rolling back means nullifying them and re-reading the old `ScoringMode` column. No data is lost because we add columns before backfilling.

---

## Data Context

### Schema Migration (Submissions table)

```text
CURRENT:  submissions.scoring_mode  VARCHAR  (e.g. "penalty", "checklist")

PROPOSED: submissions.score_direction  VARCHAR  (e.g. "down", "up", "none")
          submissions.is_weighted      BOOLEAN
          submissions.category_tag     VARCHAR  (e.g. "compliance", "routine")  -- Denormalized for fast analytics
```

### Backfill CASE Logic

```sql
UPDATE submissions SET
  score_direction = CASE scoring_mode
    WHEN 'penalty'      THEN 'down'
    WHEN 'checklist'    THEN 'down'
    WHEN 'accumulation' THEN 'up'
    WHEN 'survey'       THEN 'none'
  END,
  is_weighted = CASE scoring_mode
    WHEN 'penalty'      THEN true
    WHEN 'checklist'    THEN false
    WHEN 'accumulation' THEN false
    WHEN 'survey'       THEN false
  END;
```

### Template Category Tag (Templates and Submissions tables)

```text
NEW: templates.category_tag    VARCHAR  DEFAULT 'routine'
NEW: submissions.category_tag  VARCHAR  DEFAULT 'routine' (Denormalized for fast analytics queries without joins)
```

---

## Architecture Flow

```text
[User picks toggles in Flutter UI]
        |
        v
[Flutter ScoringInput] 
  scoreDirection = ScoreDirection.down
  isWeighted     = true
        |
        v
[Flutter ScoringEngine.calculate()]
  switch(scoreDirection):
    .down + isWeighted  --> PenaltyCalculator.compute()
    .down + !isWeighted --> ChecklistCalculator.compute()   (NO CHANGE to math)
    .up                 --> AccumulationCalculator.compute()
    .none               --> return null
        |
        v
[Flutter submits score to API]
  POST /submissions  { score_direction: "down", is_weighted: true, ... }
        |
        v
[.NET ScoringConfigParser.Parse()]
  Reads new JSON: {"scoreDirection":"down","isWeighted":true}
  (100% Hard Cut, no backward compatibility fallback needed)
        |
        v
[.NET ScoringCalculators.Verify()]
  Logic UNCHANGED — receives same parameters as before
        |
        v
[PostgreSQL submissions table]
  score_direction = "down"
  is_weighted     = true
  category_tag    = "compliance"
        |
        v
[Dashboard Analytics Query]
  WHERE category_tag = 'compliance'
  AVG(score)  -- all results are 0-100%, no distortion
```

---

## Risk Review & Security

| Persona | Score | Concern |
|---------|-------|---------|
| DB Architect | 8/10 | Migration is safe — ADD before DROP pattern. Risk: missing index on new `score_direction` column for analytics queries. **Fix**: Add composite index `(template_id, score_direction)` in migration. |
| Security Auditor | 9/10 | No new attack surface. Category tag is an admin-controlled enum. **Fix**: Validate `category_tag` against a server-side whitelist in the template save endpoint. |
| Junior Dev | 7/10 | The `ScoringConfigParser` dual-format read is complex. **Fix**: Write a clear comment and unit tests for both JSON shapes to prevent future confusion. |

All scores ≥ 7. Plan passes the review gate.

---

## Logs & Audits

- No new audit log entries required.
- Template save events already log metadata changes. The new fields will appear automatically in the existing JSON audit payload.

---

## Testing Expectations

| Slice | Test Type | Key Test Cases |
|-------|-----------|---------------|
| Slice 1: DB Migration | Integration | Old `penalty` rows → `down+true`. Old `checklist` rows → `down+false`. No nulls remain. |
| Slice 2: Backend Parser | Unit | New JSON format parsed correctly. `scoringMode` is fully removed. |
| Slice 3: Flutter Enum | Unit | `ScoringMode` enum replaced. All switch cases compile and route correctly. |
| Slice 4: Template Builder UI | Widget | "No Score" hides weight toggle. Category tag field blocks Save when empty. |
| Slice 5: Analytics Dashboard | Integration | Category filter returns only correct templates. Averages are not distorted. |

<command_logs>
- grep_search: ScoringMode in server/Common — found 50+ migration files with ScoringMode column
- grep_search: ScoringMode in Flutter lib — found scoring_mode.dart, scoring_engine.dart, checklist_calculator.dart, penalty_calculator.dart, 20+ widget files
- list_dir: server/ — confirmed flat project structure (no src/ subfolder)
- view_file: scoring_mode.dart — confirmed `enum ScoringMode { penalty, accumulation, checklist, survey }`
</command_logs>

---

## Handoff Block

**Final Decision**: Shape B (Hard Cut) — new `score_direction` + `is_weighted` columns replace the old `scoring_mode` string. One-time EF Core migration backfills all existing rows. New `category_tag` mandatory field added to templates.

**Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\analysis_epic_20260529_222100_scoring_redesign_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`

---

### Slices

**Slice 1: Database Migration**
- **Plain English**: Add two new columns (`score_direction`, `is_weighted`) to `submissions`. Add `category_tag` to BOTH `templates` and `submissions` (denormalization for fast analytics). Run a SQL CASE backfill to translate old strings to new values.
- **Why now?**: All other slices depend on the new DB columns existing. This must go first.
- **Risk**: Network/Database → **Plan → Write Acceptance Tests → Build**
- **Scope**: `server/Common/Persistence/Migrations/` + `AppDbContext.cs` + Entity classes
- **Order**: [BLOCKING] — all other slices depend on this

**Slice 2: Backend Parser + Scoring Engine**
- **Plain English**: 100% Hard Cut on the JSON API. Drop the `scoringMode` field entirely from the C# DTOs and `ScoringConfigParser.cs`. Only expect `scoreDirection` and `isWeighted`. Update `ScoringCalculators.cs` to use the new field names.
- **Why now?**: We don't need to write messy backward-compatibility code since the app is unpublished. This keeps the backend perfectly clean.
- **Risk**: Network/Database → **Plan → Write Acceptance Tests → Build**
- **Scope**: `server/Common/Scoring/ScoringConfigParser.cs`, `ScoringCalculators.cs`, DTO classes
- **Order**: [SEQUENTIAL] — after Slice 1

**Slice 3: Flutter Core (Enum + Engine)**
- **Plain English**: Replace the `ScoringMode` enum in Dart with two new enums (`ScoreDirection`, `IsWeighted`). Update the scoring engine dispatcher and all 3 calculator files. Write a local Drift (SQLite) schema migration inside the Flutter app to update the offline database.
- **Why now?**: The Flutter compiler will instantly flag every broken reference, giving us a free impact map.
- **Risk**: Internal Logic → **Plan → Write Unit Tests → Build**
- **Scope**: `lib/_shared/services/scoring_mode.dart`, `scoring_engine.dart`, all 3 calculator files, local Drift databases
- **Order**: [SEQUENTIAL] — after Slice 2

**Slice 4: Template Builder UI**
- **Plain English**: Replace the scoring mode dropdown in `metadata_form_card.dart` with the Two Toggles widget. Add Category Tag mandatory field. Update the linter (`dart_template_linter.dart`) to validate both new fields.
- **Why now?**: Depends on the Flutter enum (Slice 3) being finalized.
- **Risk**: Visuals → **Plan → Build**
- **Scope**: `metadata_form_card.dart`, `wizard_step_sections.dart`, `criterion_editor_drawer.dart`, `dart_template_linter.dart`
- **Order**: [SEQUENTIAL] — after Slice 3

**Slice 5: Analytics Dashboard Filter**
- **Plain English**: Add a Category Tag filter to the dashboard analytics screen. Update the backend analytics queries to use the new `category_tag` column.
- **Why now?**: This is the final deliverable that proves the business value of the redesign.
- **Risk**: Network/Database → **Plan → Write Acceptance Tests → Build**
- **Scope**: `lib/features/analytics/` (Flutter), snapshot job queries (.NET)
- **Order**: [SEQUENTIAL] — after Slice 4

### Handoff Roadmap

Execute ONE slice at a time. Do not begin the next until the previous one is build-verified and tests pass.

1. **Slice 1** [Risk: Network/Database] → Plan → Write Acceptance Tests → Build
2. **Slice 2** [Risk: Network/Database] → Plan → Write Acceptance Tests → Build
3. **Slice 3** [Risk: Internal Logic] → Plan → Write Unit Tests → Build
4. **Slice 4** [Risk: Visuals] → Plan → Build
5. **Slice 5** [Risk: Network/Database] → Plan → Write Acceptance Tests → Build
