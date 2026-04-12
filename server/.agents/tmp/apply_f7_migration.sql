INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260412094921_AddSubmissionConcurrencyToken', '10.0.4')
ON CONFLICT ("MigrationId") DO NOTHING;
