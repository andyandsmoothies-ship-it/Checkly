START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260412120753_SeedPbacCompleteCapabilities') THEN
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES
        (gen_random_uuid(), 'admin',         'submissions:create',  now()),
        (gen_random_uuid(), 'auditor',       'submissions:create',  now()),
        (gen_random_uuid(), 'area_manager',  'submissions:create',  now()),
        (gen_random_uuid(), 'admin',         'submissions:review',  now()),
        (gen_random_uuid(), 'area_manager',  'submissions:review',  now()),
        (gen_random_uuid(), 'admin',         'action_plans:write',  now()),
        (gen_random_uuid(), 'auditor',       'action_plans:write',  now()),
        (gen_random_uuid(), 'store_manager', 'action_plans:write',  now()),
        (gen_random_uuid(), 'admin',         'action_plans:verify', now()),
        (gen_random_uuid(), 'auditor',       'action_plans:verify', now()),
        (gen_random_uuid(), 'area_manager',  'action_plans:verify', now())
    ON CONFLICT (role, capability) DO NOTHING;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260412120753_SeedPbacCompleteCapabilities') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260412120753_SeedPbacCompleteCapabilities', '10.0.4');
    END IF;
END $EF$;
COMMIT;

