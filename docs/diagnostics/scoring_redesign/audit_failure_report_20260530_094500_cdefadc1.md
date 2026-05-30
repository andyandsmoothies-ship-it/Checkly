# SRE Failure Report: Slice 4 Template Builder UI Flop-Catcher

```text
[Live Postgres DB] ── (category_tag column exists)
         │
         ▼ (GAP: Not mapped/exposed!)
[Backend DTOs/API] ── (Omitted in SaveTemplateTree / CreateTemplate / GetTemplate / SyncTemplates)
         │
         ▼ (GAP: No SQLite column!)
[Flutter Drift DB] ── (CachedTemplates table lacks categoryTag)
         │
         ▼ (FATAL BLOCKER)
[Template Builder] ── (Cannot save or retrieve categoryTag metadata!)
```

## Executive Summary

- **Epic**: SCORING-REDESIGN
- **Audited Target**: `docs/architecture/scoring_redesign/implementation_plan_20260530_092025_slice4_template_builder_ui_cdefadc1.md`
- **Audit Verdict**: **[FATAL]**
- **Core Cause**: The proposed Slice 4 plan assumes the root-level `CategoryTag` (added to Postgres in Slice 1) can be saved/loaded by the Flutter UI. However, neither the backend endpoints (`CreateTemplate`, `UpdateTemplate`, `GetTemplate`, `SaveTemplateTree`, `SyncTemplates`) nor the Flutter Drift SQLite cache (`CachedTemplates`) currently map or expose this property. Direct implementation will result in a dead-on-arrival feature where template-level category tags are silently discarded by the backend or trigger compile/runtime crashes.

---

## Detailed Flop Discoveries

### 1. Backend Endpoint & DTO Disconnectedness
Although PostgreSQL migration `20260529161300_AddScoringDirectionAndCategoryTag` successfully added the `category_tag` column to the `templates` database table, the API layer completely ignores it:
- **`Dtos.cs`**: `TemplateDto`, `TemplateTreeDto`, and `CreateTemplateRequest` completely lack a `CategoryTag` field.
- **`CreateTemplate.cs`**: Instantiates a new `Template` but never sets `CategoryTag` from the request.
- **`UpdateTemplate.cs`**: Does not allow updating `CategoryTag` metadata.
- **`GetTemplate.cs`**: Omits `CategoryTag` from the EF Core projection select list and does not populate it in the returned `TemplateTreeDto`.
- **`SaveTemplateTree.cs`**: The main atomic tree save handler's request `SaveTreeRequest` and the underlying `Template` metadata updater (lines 128–137) ignore `CategoryTag`.

> [!CAUTION]
> If the Flutter client tries to send `categoryTag` as a top-level JSON property to `SaveTemplateTree` or `CreateTemplate`, the ASP.NET Core deserializer will silently ignore it, resulting in data loss.

---

## Detailed Local Code Audits

### 2. Client Offline Drift Database Schema Gap
Checkly is an offline-first application relying on a local SQLite cache via Drift. 
- In `lib/_shared/database/tables.dart`, the `CachedTemplates` schema class has **no column** for `categoryTag`.
- Even if the API endpoints did support it, the local DB layer cannot persist it. Consequently:
  - Cache-first operations will not yield the tag.
  - Background database sync via `TemplateDao` will strip it out during cache updates.

---

### 3. Linter Interface Signature Change Risk
- If the signature of `DartTemplateLinter.lint(...)` is changed to require `scoreDirection` and `isWeighted` instead of the legacy `scoringMode` string, all calls in existing linter unit tests (`template_linter_slice2_test.dart` and `template_linter_slice3_test.dart`) will break compilation unless they are updated simultaneously. This was noted in the plan, but must be managed meticulously.

---

## Actionable Bridge & Remediations

To recover from this FATAL blocker, we must bridge the backend and Flutter database gaps **before** or **during** the Slice 4 implementation. We propose the following unified step-by-step remediation plan:

### Step A: Update Backend DTOs & Handler Projections
Map and expose `CategoryTag` throughout the entire C# API slice:
1. Update `Dtos.cs`:
   ```csharp
   public sealed record TemplateDto(..., string? CategoryTag, ...);
   public sealed record TemplateTreeDto(..., string? CategoryTag, ...);
   public sealed record CreateTemplateRequest(..., string? CategoryTag);
   ```
2. Update `GetTemplate.cs`: project `t.CategoryTag` in EF Core and pass to `TemplateTreeDto`.
3. Update `CreateTemplate.cs`: populate `CategoryTag = request.CategoryTag`.
4. Update `UpdateTemplate.cs` and `SaveTemplateTree.cs` (`SaveTreeRequest`): map and update `template.CategoryTag`.

### Step B: Sync Drift SQLite Schema
1. Update `lib/_shared/database/tables.dart` to add `categoryTag` to `CachedTemplates`:
   ```dart
   TextColumn get categoryTag => text().nullable()();
   ```
2. Re-run `dart run build_runner build` (via `rtk flutter pub run build_runner build --delete-conflicting-outputs`) to update Drift code generation.
3. Update `TemplateDao` mapping in `lib/_shared/database/dao/template_dao.dart` and `TemplateDto` mapping in `lib/features/templates/models/template_dto.dart`.

### Step C: Execute UI Slice 4 with Bridge Fully Ready
Once Steps A & B are deployed, the UI can be safely built as planned in Slice 4.
