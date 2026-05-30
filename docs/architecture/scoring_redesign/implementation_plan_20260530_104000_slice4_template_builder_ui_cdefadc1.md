# Implementation Plan: Scoring Redesign — Slice 4: Template Builder UI

**Created**: 2026-05-30T10:40:00+07:00
**Epic**: SCORING-REDESIGN | **Slice**: 4 of 5
**Status**: PLANNING (UPDATED - SRE VERIFIED)

---

## Input Lineage

- **Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\analysis_epic_20260529_222100_scoring_redesign_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`
- **SRE Audit Report**: `C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\scoring_redesign\audit_failure_report_20260530_094500_cdefadc1.md`
- **Previous Plan**: `implementation_plan_20260530_092025_slice4_template_builder_ui_cdefadc1.md` (superseded due to critical backend/cache disconnectedness discoveries).

---

## Executive Summary & Data Flow Correction

An SRE audit identified a fatal gap in `categoryTag` exposure. PostgreSQL migration has the `category_tag` column on the `templates` database table, but the ASP.NET Core API layer and Flutter Drift SQLite offline cache do not expose or map it. Consequently, saving `categoryTag` via the UI would cause silent data loss.

This updated plan adds **Step A (C# API update)** and **Step B (Flutter Drift Cache update)** to run *before* the UI changes in **Step C**.

```text
BEFORE (BLOCKED):
[MetadataFormCard (UI)] ──► _categoryTag ──► [TemplateManager.saveTemplate()] 
                                                            │
                                                            ▼ (SILENT DROPPED!)
                                                     [SaveTemplateTree API]
                                                            │
                                                            ▼ (NOT PERSISTED offline!)
                                                     [Drift SQLite Cache]

AFTER (RESOLVED):
[MetadataFormCard (UI)] ──► _categoryTag ──► [TemplateManager.saveTemplate()]
                                                            │
                                                            ▼ (SENT as top-level DTO property)
                                                     [SaveTemplateTree API] ──► [Postgres DB (templates.category_tag)]
                                                            │
                                                            ▼ (PROPAGATED in GET/SYNC responses)
                                                     [Drift SQLite Cache (CachedTemplates.categoryTag)]
```

---

## System Context Gaps

### What the Code Lacks:
- **`Dtos.cs`**: `TemplateDto`, `TemplateTreeDto`, and `CreateTemplateRequest` records lack the `string? CategoryTag` property.
- **`GetTemplate.cs`**: The EF Core projection query lacks the selection of `t.CategoryTag` and fails to map it.
- **`CreateTemplate.cs`**: Instantiates a new `Template` but lacks setting `CategoryTag = request.CategoryTag`.
- **`UpdateTemplate.cs`**: `Request` record lacks `string? CategoryTag` and fails to update `template.CategoryTag`.
- **`SaveTemplateTree.cs`**: `SaveTreeRequest` lacks `string? CategoryTag` and the update block fails to map `template.CategoryTag = request.CategoryTag`.
- **`SyncTemplates.cs` & `ListTemplates.cs`**: Projection queries select new `TemplateDto` but lack `t.CategoryTag`.
- **`tables.dart`**: `CachedTemplates` Drift table definition lacks the `categoryTag` text column.
- **`template_dto.dart`**: `TemplateDto` and `TemplateTreeDto` class definitions, factory mappings, and JSON serialization lack `categoryTag`.
- **`template_dao.dart`**: `_rowToTemplateDto()` mapping lacks the `categoryTag` property from the database row, and `_templateToCompanion()` lacks setting `categoryTag` value companion.

---

## Technical Specifications & Implementations

### Step A: ASP.NET Core Backend Update

#### 1. `server/Features/Templates/Dtos.cs`
Modify records to add the nullable string `CategoryTag`:
```csharp
public sealed record TemplateDto(
    Guid Id,
    string Title,
    string? Description,
    string Type,
    int Version,
    string? ScoringLogicConfig,
    string? DisplayNoun,
    string? CategoryTag, // Added
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public sealed record TemplateTreeDto(
    Guid Id,
    string Title,
    string? Description,
    string Type,
    int Version,
    string? ScoringLogicConfig,
    string? DisplayNoun,
    string? CategoryTag, // Added
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    List<GroupDto> Groups,
    LintResult? LintResult = null);

public sealed record CreateTemplateRequest(
    string Title,
    string Type,
    string? Description,
    string? ScoringLogicConfig,
    string? DisplayNoun,
    string? CategoryTag); // Added
```

#### 2. `server/Features/Templates/GetTemplate.cs`
Update projection and tree construction:
```csharp
            .Select(t => new
            {
                t.Id,
                t.Title,
                t.Description,
                t.Type,
                t.Version,
                t.ScoringLogicConfig,
                t.DisplayNoun,
                t.CategoryTag, // Added
                t.IsActive,
                t.CreatedAt,
                t.UpdatedAt
            })
...
        var dto = new TemplateTreeDto(
            template.Id, template.Title, template.Description, template.Type,
            template.Version, template.ScoringLogicConfig, template.DisplayNoun,
            template.CategoryTag, // Added
            template.IsActive, template.CreatedAt, template.UpdatedAt, tree);
```

#### 3. `server/Features/Templates/CreateTemplate.cs`
Map and return CategoryTag:
```csharp
        var template = new Template
        {
            ...
            CategoryTag = request.CategoryTag, // Added
            ...
        };
...
            new TemplateDto(
                template.Id, template.Title, template.Description, template.Type,
                template.Version, template.ScoringLogicConfig, template.DisplayNoun,
                template.CategoryTag, // Added
                template.IsActive, template.CreatedAt, template.UpdatedAt));
```

#### 4. `server/Features/Templates/UpdateTemplate.cs`
Add `CategoryTag` to `Request` and map it:
```csharp
    public record Request(
        string? Title,
        string? Description,
        string? Type,
        string? ScoringLogicConfig,
        string? CategoryTag); // Added
...
        if (request.CategoryTag != null)
            template.CategoryTag = request.CategoryTag.Trim();
```

#### 5. `server/Features/Templates/SaveTemplateTree.cs`
Add `CategoryTag` to `SaveTreeRequest` and map it:
```csharp
    public record SaveTreeRequest(
        string Title,
        string Type,
        string? Description,
        string? ScoringLogicConfig,
        string? DisplayNoun,
        int Version,
        string? CategoryTag, // Added
        List<SaveGroupRequest> Groups);
...
        template.CategoryTag = request.CategoryTag; // Added
...
        var dto = new TemplateTreeDto(
            template.Id, template.Title, template.Description, template.Type,
            template.Version, template.ScoringLogicConfig, template.DisplayNoun,
            template.CategoryTag, // Added
            template.IsActive, template.CreatedAt, template.UpdatedAt, tree,
            lintResult);
```

#### 6. `server/Features/Templates/ListTemplates.cs` & `SyncTemplates.cs`
Map `CategoryTag` in `TemplateDto` projection:
```csharp
            .Select(t => new TemplateDto(
                t.Id, t.Title, t.Description, t.Type, t.Version,
                t.ScoringLogicConfig, t.DisplayNoun, t.CategoryTag, t.IsActive, t.CreatedAt, t.UpdatedAt))
```

---

### Step B: Flutter SQLite Cache Update

#### 1. `lib/_shared/database/tables.dart`
Add the nullable text column:
```dart
class CachedTemplates extends Table {
  ...
  TextColumn get categoryTag => text().nullable()(); // Added
  ...
}
```

#### 2. `lib/_shared/database/app_database.dart`
Increment `schemaVersion` from `31` to `32` and write migration:
```dart
  @override
  int get schemaVersion => 32; // Changed
...
      if (from < 32) {
        // v32: CategoryTag column added to CachedTemplates
        await m.addColumn(cachedTemplates, cachedTemplates.categoryTag);
      }
```

#### 3. Regenerate Drift Database Code
Run code generator tool:
```bash
rtk flutter pub run build_runner build --delete-conflicting-outputs
```

#### 4. `lib/features/templates/models/template_dto.dart`
Expose `categoryTag` property:
```dart
class TemplateDto {
  ...
  final String? categoryTag; // Added

  const TemplateDto({
    ...
    this.categoryTag, // Added
    ...
  });

  factory TemplateDto.fromJson(Map<String, dynamic> json) => TemplateDto(
    ...
    categoryTag: json['categoryTag'] as String?, // Added
    ...
  );
}

class TemplateTreeDto {
  ...
  final String? categoryTag; // Added

  const TemplateTreeDto({
    ...
    this.categoryTag, // Added
    ...
  });

  factory TemplateTreeDto.fromJson(Map<String, dynamic> json) => TemplateTreeDto(
    ...
    categoryTag: json['categoryTag'] as String?, // Added
    ...
  );
}
```

#### 5. `lib/_shared/database/dao/template_dao.dart`
Map the DTO to/from database tables:
```dart
  TemplateDto _rowToTemplateDto(CachedTemplate row) => TemplateDto(
    ...
    categoryTag: row.categoryTag, // Added
    ...
  );

  CachedTemplatesCompanion _templateToCompanion(TemplateDto dto) =>
      CachedTemplatesCompanion.insert(
        ...
        categoryTag: Value(dto.categoryTag), // Added
        ...
      );
```

---

### Step C: UI & State Implementation (Original Slice 4)

#### 1. `lib/features/templates/widgets/metadata_form_card.dart`
Replace dropdown with SegmentedButton + isWeighted Switch + categoryTag TextFormField:
- **State Properties**: `scoreDirection` (down/up/none), `isWeighted` (bool), `categoryTag` (String).
- **Callbacks**: `onScoreDirectionChanged`, `onIsWeightedChanged`, `onCategoryTagChanged`.

#### 2. `lib/features/templates/pages/template_builder_page.dart`
- Replace state `String _scoringMode` with:
  ```dart
  String _scoreDirection = 'down';
  bool _isWeighted = true;
  String _categoryTag = '';
  ```
- Derive legacy string for backward-compatible sub-cards via bridge getter:
  ```dart
  String get _legacyScoringMode {
    if (_scoreDirection == 'none') return 'survey';
    if (_scoreDirection == 'up') return 'accumulation';
    return _isWeighted ? 'penalty' : 'checklist';
  }
  ```

#### 3. `lib/features/templates/pages/template_builder_page_logic.dart`
- Load:
  ```dart
  _scoreDirection = config['scoreDirection'] as String? ?? 'down';
  _isWeighted = config['isWeighted'] as bool? ?? true;
  _categoryTag = template.categoryTag ?? '';
  ```
- Save:
  - Pass `scoreDirection` and `isWeighted` to `buildScoringLogicConfig()`.
  - Pass `categoryTag` through to `saveTemplate()`.

#### 4. `lib/features/templates/utils/template_payload_mapper.dart`
- Update `buildScoringLogicConfig()` to map the new orthogonal keys.

#### 5. `lib/features/templates/utils/dart_template_linter.dart`
- Update `lint()` signature to accept `scoreDirection` and `isWeighted` instead of the legacy `scoringMode`.

---

## Test & Verification Specs

### Integration Tests (C# API Verification)
- Add verification test in `TemplateCategoryTagsProjectionTests.cs` to verify `SaveTemplateTree` saves `CategoryTag` to database and `GetTemplate`/`ListTemplates`/`SyncTemplates` returns it.

### Unit Tests (Drift SQLite Cache Verification)
- Run Drift database integration test ensuring schema upgrade from version 31 to 32 successfully adds `category_tag` column to `cached_templates`.

---

## Execution Slices

### Slice 1: Backend C# DTO & Endpoint Projection Wiring
- **Entry**: ASP.NET Core solution compiles successfully.
- **Exit**: All API handlers load, query, filter, update, and return the `category_tag` column. C# tests green.
- **Route**: Route 2 (Write integration test first verifying DTO project capability).

### Slice 2: Drift SQLite offline Cache Schema Wiring
- **Entry**: Slice 1 complete.
- **Exit**: `tables.dart` has `categoryTag` column. Migration to v32 is declared. Code generation completes. TemplateDao projects to/from domain DTOs.
- **Route**: Route 2 (Drift migration unit test).

### Slice 3: UI Controls & Linter State Integration
- **Entry**: Slice 2 complete.
- **Exit**: MetadataFormCard renders the SegmentedButton + Switch + TextField. Builder page loads/saves and correctly synchronizes with Drift Cache and Backend API.
- **Route**: Route 1 (Direct Build).

---

## Handoff Block

**Plan File**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260530_104000_slice4_template_builder_ui_cdefadc1.md`

**Task Tracker**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\scoring_redesign\task_20260530_092025_slice4_template_builder_ui_cdefadc1.md`
