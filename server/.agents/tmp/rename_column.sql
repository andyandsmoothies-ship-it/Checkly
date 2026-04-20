-- Rename TemplateType (PascalCase) to template_type (snake_case)
-- This matches the HasColumnName("template_type") mapping in AppDbContext
-- Also records the SyncSnapshot migration as applied
ALTER TABLE submissions RENAME COLUMN "TemplateType" TO template_type;

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
SELECT '20260419120907_SyncSnapshot', '10.0.4'
WHERE NOT EXISTS (
    SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260419120907_SyncSnapshot'
);
