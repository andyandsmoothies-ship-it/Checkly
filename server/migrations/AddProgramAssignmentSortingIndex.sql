START TRANSACTION;
CREATE INDEX "IX_program_assignments_program_id_created_at" ON program_assignments (program_id, created_at DESC);

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260501100938_AddProgramAssignmentSortingIndex', '10.0.4');

COMMIT;

