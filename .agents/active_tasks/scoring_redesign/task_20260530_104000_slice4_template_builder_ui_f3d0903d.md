# Task Tracker: Scoring Redesign — Slice 4: Template Builder UI

Topic: `scoring_redesign`
Conversation ID: `f3d0903d-1b05-4a39-813d-fee3d9016fa7`
Status: COMPLETED

## ASCII Flowchart of Data Flow
```text
[UI: MetadataFormCard] ──(scoreDirection, isWeighted, categoryTag)──► [TemplateBuilderPage]
                                                                            │
                                                                            ▼ (Local DB)
                                                                     [CachedTemplates (SQLite)]
                                                                            │
                                                                            ▼ (Network API)
                                                                     [SaveTemplateTree API] ──► [Postgres DB (templates)]
```

## Task Checklist

### Slice 1: Backend C# DTO & Endpoint Projection Wiring
- [x] Add `CategoryTag` property to `TemplateDto`, `TemplateTreeDto`, and `CreateTemplateRequest` in `server/Features/Templates/Dtos.cs`
- [x] Update `server/Features/Templates/GetTemplate.cs` to project and map `CategoryTag`
- [x] Update `server/Features/Templates/CreateTemplate.cs` to map `CategoryTag`
- [x] Update `server/Features/Templates/UpdateTemplate.cs` to accept and map `CategoryTag`
- [x] Update `server/Features/Templates/SaveTemplateTree.cs` to accept and map `CategoryTag`
- [x] Update `server/Features/Templates/ListTemplates.cs` and `SyncTemplates.cs` to project `CategoryTag`
- [x] Run backend tests using `rtk dotnet test --filter "FullyQualifiedName~TemplateCategoryTagsProjectionTests"` to verify all C# integration tests pass successfully

### Slice 2: Drift SQLite offline Cache Schema Wiring
- [x] Add nullable text column `categoryTag` to `CachedTemplates` in `lib/_shared/database/tables.dart`
- [x] Increment `schemaVersion` to `32` and write migration block in `lib/_shared/database/app_database.dart`
- [x] Run drift code generator: `rtk flutter pub run build_runner build --delete-conflicting-outputs`
- [x] Update `TemplateDto` and `TemplateTreeDto` JSON serialization in `lib/features/templates/models/template_dto.dart`
- [x] Update `_rowToTemplateDto` and `_templateToCompanion` in `lib/_shared/database/dao/template_dao.dart`
- [x] Run Flutter unit/drift tests to verify cache schema migration is correct and fully functional

### Slice 3: UI Controls & Linter State Integration
- [x] Update `lib/features/templates/widgets/metadata_form_card.dart` with SegmentedButton, isWeighted Switch, and categoryTag TextFormField
- [x] Update `lib/features/templates/pages/template_builder_page.dart` to manage scoreDirection, isWeighted, and categoryTag states and bridge legacy mode
- [x] Update `lib/features/templates/pages/template_builder_page_logic.dart` to load and save the new states
- [x] Update `lib/features/templates/utils/template_payload_mapper.dart` to build scoring logic configuration with new orthogonal keys
- [x] Update `lib/features/templates/utils/dart_template_linter.dart` to accept scoreDirection and isWeighted
- [x] Run full `rtk flutter analyze` and `rtk flutter test` suite to ensure compilation is clean and all tests are passing

