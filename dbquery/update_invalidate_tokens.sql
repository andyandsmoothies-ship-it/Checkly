CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE TABLE notifications (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        user_id uuid NOT NULL,
        type text NOT NULL,
        title text NOT NULL,
        message text,
        read_at timestamp with time zone,
        action_url text,
        metadata jsonb,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_notifications" PRIMARY KEY (id)
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE TABLE stores (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        name text NOT NULL,
        address text,
        area_code text,
        gps_lat numeric,
        gps_lng numeric,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        updated_at timestamp with time zone NOT NULL DEFAULT (now()),
        is_active boolean DEFAULT TRUE,
        CONSTRAINT "PK_stores" PRIMARY KEY (id)
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE TABLE templates (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        title text NOT NULL,
        description text,
        type text NOT NULL,
        version integer NOT NULL DEFAULT 1,
        scoring_logic_config jsonb,
        is_active boolean NOT NULL DEFAULT TRUE,
        created_by uuid,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        updated_at timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_templates" PRIMARY KEY (id)
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE TABLE user_roles (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        user_id uuid NOT NULL,
        role text NOT NULL,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_user_roles" PRIMARY KEY (id)
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE TABLE profiles (
        id uuid NOT NULL,
        full_name text,
        email text,
        avatar_url text,
        store_id uuid,
        area_code text,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        updated_at timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_profiles" PRIMARY KEY (id),
        CONSTRAINT "FK_profiles_stores_store_id" FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE SET NULL
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE TABLE groups (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        template_id uuid NOT NULL,
        title text NOT NULL,
        description text,
        weight numeric DEFAULT 1.0,
        max_deduction_points numeric,
        order_index integer NOT NULL DEFAULT 0,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        updated_at timestamp with time zone NOT NULL DEFAULT (now()),
        parent_id uuid,
        metadata jsonb,
        is_active boolean NOT NULL DEFAULT TRUE,
        CONSTRAINT "PK_groups" PRIMARY KEY (id),
        CONSTRAINT "FK_groups_groups_parent_id" FOREIGN KEY (parent_id) REFERENCES groups (id) ON DELETE RESTRICT,
        CONSTRAINT "FK_groups_templates_template_id" FOREIGN KEY (template_id) REFERENCES templates (id) ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE TABLE submissions (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        template_id uuid,
        auditor_id uuid,
        store_id uuid,
        status text NOT NULL DEFAULT 'draft',
        total_score numeric,
        section_scores jsonb,
        gps_lat numeric,
        gps_lng numeric,
        gps_verified_at timestamp with time zone,
        notes text,
        scheduled_at timestamp with time zone,
        completed_at timestamp with time zone,
        approved_by uuid,
        approved_at timestamp with time zone,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        updated_at timestamp with time zone NOT NULL DEFAULT (now()),
        started_at timestamp with time zone,
        auditor_name text,
        auditor_email text,
        store_name text,
        template_title text,
        approver_name text,
        review_status text,
        CONSTRAINT "PK_submissions" PRIMARY KEY (id),
        CONSTRAINT "FK_submissions_stores_store_id" FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE SET NULL,
        CONSTRAINT "FK_submissions_templates_template_id" FOREIGN KEY (template_id) REFERENCES templates (id) ON DELETE SET NULL
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE TABLE criteria (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        group_id uuid NOT NULL,
        label text NOT NULL,
        description text,
        input_type text NOT NULL,
        points_weight numeric DEFAULT 1.0,
        is_ccp boolean NOT NULL DEFAULT FALSE,
        is_risk boolean NOT NULL DEFAULT FALSE,
        order_index integer NOT NULL DEFAULT 0,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        updated_at timestamp with time zone NOT NULL DEFAULT (now()),
        metadata jsonb,
        is_active boolean NOT NULL DEFAULT TRUE,
        CONSTRAINT "PK_criteria" PRIMARY KEY (id),
        CONSTRAINT "FK_criteria_groups_group_id" FOREIGN KEY (group_id) REFERENCES groups (id) ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE TABLE answers (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        submission_id uuid,
        criteria_id uuid,
        value text,
        numeric_value numeric,
        note text,
        photo_url text,
        photo_metadata jsonb,
        is_repeated_error boolean NOT NULL DEFAULT FALSE,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        updated_at timestamp with time zone NOT NULL DEFAULT (now()),
        metadata jsonb,
        criteria_label text,
        CONSTRAINT "PK_answers" PRIMARY KEY (id),
        CONSTRAINT "FK_answers_criteria_criteria_id" FOREIGN KEY (criteria_id) REFERENCES criteria (id) ON DELETE SET NULL,
        CONSTRAINT "FK_answers_submissions_submission_id" FOREIGN KEY (submission_id) REFERENCES submissions (id) ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE TABLE action_plans (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        answer_id uuid,
        submission_id uuid,
        store_id uuid,
        store_manager_id uuid,
        criteria_label text NOT NULL,
        group_title text NOT NULL,
        plan_description text,
        evidence_photo_url text,
        evidence_note text,
        status text NOT NULL DEFAULT 'open',
        deadline timestamp with time zone,
        closed_at timestamp with time zone,
        verified_by uuid,
        verified_at timestamp with time zone,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        updated_at timestamp with time zone NOT NULL DEFAULT (now()),
        root_cause text,
        correction_plan text,
        store_name text,
        store_manager_name text,
        verifier_name text,
        CONSTRAINT "PK_action_plans" PRIMARY KEY (id),
        CONSTRAINT "FK_action_plans_answers_answer_id" FOREIGN KEY (answer_id) REFERENCES answers (id) ON DELETE SET NULL,
        CONSTRAINT "FK_action_plans_stores_store_id" FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE SET NULL,
        CONSTRAINT "FK_action_plans_submissions_submission_id" FOREIGN KEY (submission_id) REFERENCES submissions (id) ON DELETE SET NULL
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE INDEX "IX_action_plans_answer_id" ON action_plans (answer_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE INDEX "IX_action_plans_store_id" ON action_plans (store_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE INDEX "IX_action_plans_submission_id" ON action_plans (submission_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE INDEX "IX_answers_criteria_id" ON answers (criteria_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE INDEX "IX_answers_submission_id" ON answers (submission_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE INDEX "IX_criteria_group_id" ON criteria (group_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE INDEX "IX_groups_parent_id" ON groups (parent_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE INDEX "IX_groups_template_id" ON groups (template_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE INDEX "IX_profiles_store_id" ON profiles (store_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE INDEX "IX_submissions_store_id" ON submissions (store_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    CREATE INDEX "IX_submissions_template_id" ON submissions (template_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311001911_InitialCreate') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260311001911_InitialCreate', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE TABLE "AspNetRoles" (
        "Id" uuid NOT NULL,
        "Name" character varying(256),
        "NormalizedName" character varying(256),
        "ConcurrencyStamp" text,
        CONSTRAINT "PK_AspNetRoles" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE TABLE "AspNetUsers" (
        "Id" uuid NOT NULL,
        "UserName" character varying(256),
        "NormalizedUserName" character varying(256),
        "Email" character varying(256),
        "NormalizedEmail" character varying(256),
        "EmailConfirmed" boolean NOT NULL,
        "PasswordHash" text,
        "SecurityStamp" text,
        "ConcurrencyStamp" text,
        "PhoneNumber" text,
        "PhoneNumberConfirmed" boolean NOT NULL,
        "TwoFactorEnabled" boolean NOT NULL,
        "LockoutEnd" timestamp with time zone,
        "LockoutEnabled" boolean NOT NULL,
        "AccessFailedCount" integer NOT NULL,
        CONSTRAINT "PK_AspNetUsers" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE TABLE "AspNetRoleClaims" (
        "Id" integer GENERATED BY DEFAULT AS IDENTITY,
        "RoleId" uuid NOT NULL,
        "ClaimType" text,
        "ClaimValue" text,
        CONSTRAINT "PK_AspNetRoleClaims" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_AspNetRoleClaims_AspNetRoles_RoleId" FOREIGN KEY ("RoleId") REFERENCES "AspNetRoles" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE TABLE "AspNetUserClaims" (
        "Id" integer GENERATED BY DEFAULT AS IDENTITY,
        "UserId" uuid NOT NULL,
        "ClaimType" text,
        "ClaimValue" text,
        CONSTRAINT "PK_AspNetUserClaims" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_AspNetUserClaims_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE TABLE "AspNetUserLogins" (
        "LoginProvider" text NOT NULL,
        "ProviderKey" text NOT NULL,
        "ProviderDisplayName" text,
        "UserId" uuid NOT NULL,
        CONSTRAINT "PK_AspNetUserLogins" PRIMARY KEY ("LoginProvider", "ProviderKey"),
        CONSTRAINT "FK_AspNetUserLogins_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE TABLE "AspNetUserRoles" (
        "UserId" uuid NOT NULL,
        "RoleId" uuid NOT NULL,
        CONSTRAINT "PK_AspNetUserRoles" PRIMARY KEY ("UserId", "RoleId"),
        CONSTRAINT "FK_AspNetUserRoles_AspNetRoles_RoleId" FOREIGN KEY ("RoleId") REFERENCES "AspNetRoles" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_AspNetUserRoles_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE TABLE "AspNetUserTokens" (
        "UserId" uuid NOT NULL,
        "LoginProvider" text NOT NULL,
        "Name" text NOT NULL,
        "Value" text,
        CONSTRAINT "PK_AspNetUserTokens" PRIMARY KEY ("UserId", "LoginProvider", "Name"),
        CONSTRAINT "FK_AspNetUserTokens_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE INDEX "IX_user_roles_user_id" ON user_roles (user_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE INDEX "IX_AspNetRoleClaims_RoleId" ON "AspNetRoleClaims" ("RoleId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE UNIQUE INDEX "RoleNameIndex" ON "AspNetRoles" ("NormalizedName");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE INDEX "IX_AspNetUserClaims_UserId" ON "AspNetUserClaims" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE INDEX "IX_AspNetUserLogins_UserId" ON "AspNetUserLogins" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE INDEX "IX_AspNetUserRoles_RoleId" ON "AspNetUserRoles" ("RoleId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE INDEX "EmailIndex" ON "AspNetUsers" ("NormalizedEmail");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    CREATE UNIQUE INDEX "UserNameIndex" ON "AspNetUsers" ("NormalizedUserName");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    ALTER TABLE profiles ADD CONSTRAINT "FK_profiles_AspNetUsers_id" FOREIGN KEY (id) REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    ALTER TABLE user_roles ADD CONSTRAINT "FK_user_roles_AspNetUsers_user_id" FOREIGN KEY (user_id) REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260311003627_AddIdentity') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260311003627_AddIdentity', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    ALTER TABLE profiles DROP CONSTRAINT "FK_profiles_AspNetUsers_id";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    DROP INDEX "IX_action_plans_store_id";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    ALTER TABLE submissions ADD idempotency_key text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    ALTER TABLE criteria ADD minus_impact numeric;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    ALTER TABLE answers ADD repeated_faults integer NOT NULL DEFAULT 0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    CREATE TABLE system_logs (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        user_id uuid,
        action text NOT NULL,
        category text NOT NULL,
        message text,
        path text,
        level text NOT NULL DEFAULT 'info',
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_system_logs" PRIMARY KEY (id)
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    CREATE INDEX "IX_submissions_auditor_id" ON submissions (auditor_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    CREATE INDEX "IX_submissions_created_at" ON submissions (created_at DESC);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    CREATE UNIQUE INDEX "IX_submissions_idempotency_key" ON submissions (idempotency_key) WHERE idempotency_key IS NOT NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    CREATE INDEX "IX_submissions_status_review_status" ON submissions (status, review_status);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    CREATE INDEX "IX_stores_area_code" ON stores (area_code);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    CREATE INDEX "IX_stores_is_active" ON stores (is_active) WHERE is_active = true;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    CREATE INDEX "IX_notifications_user_id_created_at" ON notifications (user_id, created_at);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    CREATE INDEX "IX_action_plans_deadline" ON action_plans (deadline);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    CREATE INDEX "IX_action_plans_store_id_status" ON action_plans (store_id, status);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312131932_AddPerformanceIndexes') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260312131932_AddPerformanceIndexes', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312140018_AddSystemLogCreatedAtIndex') THEN
    CREATE INDEX "IX_system_logs_created_at" ON system_logs (created_at DESC);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260312140018_AddSystemLogCreatedAtIndex') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260312140018_AddSystemLogCreatedAtIndex', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313075211_AddAreasTable') THEN
    CREATE TABLE areas (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        name text NOT NULL,
        code text NOT NULL,
        is_active boolean NOT NULL DEFAULT TRUE,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        updated_at timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_areas" PRIMARY KEY (id)
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313075211_AddAreasTable') THEN
    CREATE UNIQUE INDEX "IX_areas_code" ON areas (code);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313075211_AddAreasTable') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260313075211_AddAreasTable', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313081726_AddAreaIdToStoresAndProfiles') THEN
    ALTER TABLE stores ADD area_id uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313081726_AddAreaIdToStoresAndProfiles') THEN
    ALTER TABLE profiles ADD area_id uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313081726_AddAreaIdToStoresAndProfiles') THEN
    CREATE INDEX "IX_stores_area_id" ON stores (area_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313081726_AddAreaIdToStoresAndProfiles') THEN
    CREATE INDEX "IX_profiles_area_id" ON profiles (area_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313081726_AddAreaIdToStoresAndProfiles') THEN
    ALTER TABLE profiles ADD CONSTRAINT "FK_profiles_areas_area_id" FOREIGN KEY (area_id) REFERENCES areas (id) ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313081726_AddAreaIdToStoresAndProfiles') THEN
    ALTER TABLE stores ADD CONSTRAINT "FK_stores_areas_area_id" FOREIGN KEY (area_id) REFERENCES areas (id) ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313081726_AddAreaIdToStoresAndProfiles') THEN
    UPDATE stores SET area_id = a.id
    FROM areas a
    WHERE LOWER(stores.area_code) = a.code
      AND stores.area_code IS NOT NULL;

    UPDATE profiles SET area_id = a.id
    FROM areas a
    WHERE LOWER(profiles.area_code) = a.code
      AND profiles.area_code IS NOT NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313081726_AddAreaIdToStoresAndProfiles') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260313081726_AddAreaIdToStoresAndProfiles', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313092220_DropAreaCodeColumns') THEN
    DROP INDEX "IX_stores_area_code";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313092220_DropAreaCodeColumns') THEN
    ALTER TABLE stores DROP COLUMN area_code;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313092220_DropAreaCodeColumns') THEN
    ALTER TABLE profiles DROP COLUMN area_code;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260313092220_DropAreaCodeColumns') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260313092220_DropAreaCodeColumns', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260315050132_SimplifyAreaDropCodeAddDescription') THEN
    DROP INDEX "IX_areas_code";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260315050132_SimplifyAreaDropCodeAddDescription') THEN
    ALTER TABLE areas DROP COLUMN code;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260315050132_SimplifyAreaDropCodeAddDescription') THEN
    ALTER TABLE areas ADD description text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260315050132_SimplifyAreaDropCodeAddDescription') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260315050132_SimplifyAreaDropCodeAddDescription', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318003846_AddScoringModeAndDisplayNoun') THEN
    ALTER TABLE templates ADD display_noun text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318003846_AddScoringModeAndDisplayNoun') THEN
    ALTER TABLE submissions ADD display_noun text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318003846_AddScoringModeAndDisplayNoun') THEN
    ALTER TABLE submissions ADD scoring_mode text NOT NULL DEFAULT 'penalty';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318003846_AddScoringModeAndDisplayNoun') THEN
    ALTER TABLE groups ADD COLUMN IF NOT EXISTS minus_per_fault numeric;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318003846_AddScoringModeAndDisplayNoun') THEN
    CREATE INDEX ix_submissions_scoring_mode ON submissions (scoring_mode);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318003846_AddScoringModeAndDisplayNoun') THEN
    CREATE INDEX IF NOT EXISTS ix_submissions_section_scores_gin ON submissions USING GIN (section_scores jsonb_path_ops);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318003846_AddScoringModeAndDisplayNoun') THEN

                    UPDATE submissions s
                    SET scoring_mode = COALESCE(
                        (SELECT t.scoring_logic_config::jsonb->>'scoringMode'
                         FROM templates t WHERE t.id = s.template_id),
                        'penalty'
                    );
                
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318003846_AddScoringModeAndDisplayNoun') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260318003846_AddScoringModeAndDisplayNoun', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318022806_AddUserGroupsAndAssignments') THEN
    CREATE TABLE user_groups (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        name text NOT NULL,
        description text,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        updated_at timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_user_groups" PRIMARY KEY (id)
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318022806_AddUserGroupsAndAssignments') THEN
    CREATE TABLE template_assignments (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        template_id uuid NOT NULL,
        user_group_id uuid NOT NULL,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_template_assignments" PRIMARY KEY (id),
        CONSTRAINT "FK_template_assignments_templates_template_id" FOREIGN KEY (template_id) REFERENCES templates (id) ON DELETE CASCADE,
        CONSTRAINT "FK_template_assignments_user_groups_user_group_id" FOREIGN KEY (user_group_id) REFERENCES user_groups (id) ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318022806_AddUserGroupsAndAssignments') THEN
    CREATE TABLE user_group_members (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        user_group_id uuid NOT NULL,
        profile_id uuid NOT NULL,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_user_group_members" PRIMARY KEY (id),
        CONSTRAINT "FK_user_group_members_profiles_profile_id" FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE,
        CONSTRAINT "FK_user_group_members_user_groups_user_group_id" FOREIGN KEY (user_group_id) REFERENCES user_groups (id) ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318022806_AddUserGroupsAndAssignments') THEN
    CREATE UNIQUE INDEX "IX_template_assignments_template_id_user_group_id" ON template_assignments (template_id, user_group_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318022806_AddUserGroupsAndAssignments') THEN
    CREATE INDEX "IX_template_assignments_user_group_id" ON template_assignments (user_group_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318022806_AddUserGroupsAndAssignments') THEN
    CREATE INDEX "IX_user_group_members_profile_id" ON user_group_members (profile_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318022806_AddUserGroupsAndAssignments') THEN
    CREATE UNIQUE INDEX "IX_user_group_members_user_group_id_profile_id" ON user_group_members (user_group_id, profile_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318022806_AddUserGroupsAndAssignments') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260318022806_AddUserGroupsAndAssignments', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318223846_AddAnalyticsTables') THEN
    CREATE TABLE store_analytics_snapshot (
        store_id uuid NOT NULL,
        avg_score_30d numeric NOT NULL,
        total_audits_30d integer NOT NULL,
        open_action_plans integer NOT NULL DEFAULT 0,
        overdue_action_plans integer NOT NULL DEFAULT 0,
        last_audit_score numeric,
        last_audit_at timestamp with time zone,
        updated_at timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_store_analytics_snapshot" PRIMARY KEY (store_id),
        CONSTRAINT "FK_store_analytics_snapshot_stores_store_id" FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318223846_AddAnalyticsTables') THEN
    CREATE TABLE submission_section_scores (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        submission_id uuid NOT NULL,
        store_id uuid,
        template_id uuid,
        section_title text NOT NULL,
        score numeric NOT NULL,
        max_score numeric NOT NULL,
        ratio numeric,
        is_ccp_failed boolean NOT NULL DEFAULT FALSE,
        weight numeric,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_submission_section_scores" PRIMARY KEY (id),
        CONSTRAINT "FK_submission_section_scores_submissions_submission_id" FOREIGN KEY (submission_id) REFERENCES submissions (id) ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318223846_AddAnalyticsTables') THEN
    CREATE INDEX "IX_submission_section_scores_store_id_section_title" ON submission_section_scores (store_id, section_title);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318223846_AddAnalyticsTables') THEN
    CREATE INDEX "IX_submission_section_scores_submission_id" ON submission_section_scores (submission_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318223846_AddAnalyticsTables') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260318223846_AddAnalyticsTables', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318233345_AddSubmissionCompositeIndexes') THEN
    DROP INDEX "IX_submissions_store_id";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318233345_AddSubmissionCompositeIndexes') THEN
    DROP INDEX "IX_submissions_template_id";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318233345_AddSubmissionCompositeIndexes') THEN
    CREATE INDEX "IX_submissions_store_id_created_at" ON submissions (store_id, created_at DESC);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318233345_AddSubmissionCompositeIndexes') THEN
    CREATE INDEX "IX_submissions_template_id_scoring_mode" ON submissions (template_id, scoring_mode);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260318233345_AddSubmissionCompositeIndexes') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260318233345_AddSubmissionCompositeIndexes', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260320031922_AddTemplateSnapshot') THEN
    ALTER TABLE submissions ADD template_snapshot jsonb;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260320031922_AddTemplateSnapshot') THEN
    ALTER TABLE submissions ADD template_version integer;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260320031922_AddTemplateSnapshot') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260320031922_AddTemplateSnapshot', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260320105910_AddAuditEntityFields') THEN
    ALTER TABLE system_logs ADD entity_id uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260320105910_AddAuditEntityFields') THEN
    ALTER TABLE system_logs ADD entity_type text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260320105910_AddAuditEntityFields') THEN
    CREATE INDEX "IX_system_logs_entity_type_entity_id" ON system_logs (entity_type, entity_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260320105910_AddAuditEntityFields') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260320105910_AddAuditEntityFields', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260321000141_RemoveAreaIsActive') THEN
    ALTER TABLE areas DROP COLUMN is_active;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260321000141_RemoveAreaIsActive') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260321000141_RemoveAreaIsActive', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260323233530_AddAnswerIsFailureAndAreaActive') THEN
    ALTER TABLE groups ALTER COLUMN weight DROP DEFAULT;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260323233530_AddAnswerIsFailureAndAreaActive') THEN
    ALTER TABLE areas ADD is_active boolean NOT NULL DEFAULT TRUE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260323233530_AddAnswerIsFailureAndAreaActive') THEN
    ALTER TABLE answers ADD is_failure boolean NOT NULL DEFAULT FALSE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260323233530_AddAnswerIsFailureAndAreaActive') THEN
    CREATE INDEX "IX_answers_is_failure_criteria_id" ON answers (is_failure, criteria_id);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260323233530_AddAnswerIsFailureAndAreaActive') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260323233530_AddAnswerIsFailureAndAreaActive', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260324120342_ExpandSystemLogsTracking') THEN
    ALTER TABLE system_logs ADD trace_id text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260324120342_ExpandSystemLogsTracking') THEN
    ALTER TABLE system_logs ADD user_email text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260324120342_ExpandSystemLogsTracking') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260324120342_ExpandSystemLogsTracking', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260325084125_AddActionPlanUniqueConstraint') THEN
    DROP INDEX "IX_action_plans_submission_id";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260325084125_AddActionPlanUniqueConstraint') THEN
    CREATE UNIQUE INDEX "IX_action_plans_submission_id_answer_id" ON action_plans (submission_id, answer_id) WHERE submission_id IS NOT NULL AND answer_id IS NOT NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260325084125_AddActionPlanUniqueConstraint') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260325084125_AddActionPlanUniqueConstraint', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260325143056_DropAreaIsActiveColumn') THEN
    ALTER TABLE areas DROP COLUMN is_active;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260325143056_DropAreaIsActiveColumn') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260325143056_DropAreaIsActiveColumn', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260329071037_AddIsActiveFilteredIndexes') THEN
    CREATE INDEX "IX_templates_is_active" ON templates (is_active) WHERE is_active = true;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260329071037_AddIsActiveFilteredIndexes') THEN
    CREATE INDEX "IX_groups_is_active" ON groups (is_active) WHERE is_active = true;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260329071037_AddIsActiveFilteredIndexes') THEN
    CREATE INDEX "IX_criteria_is_active" ON criteria (is_active) WHERE is_active = true;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260329071037_AddIsActiveFilteredIndexes') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260329071037_AddIsActiveFilteredIndexes', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260401045525_AddVoidAuditStatus') THEN
    ALTER TABLE submissions ADD void_reason text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260401045525_AddVoidAuditStatus') THEN
    ALTER TABLE submissions ADD voided_at timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260401045525_AddVoidAuditStatus') THEN
    ALTER TABLE submissions DROP CONSTRAINT IF EXISTS status_check;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260401045525_AddVoidAuditStatus') THEN
    ALTER TABLE submissions ADD CONSTRAINT status_check CHECK (status IN ('scheduled', 'draft', 'completed', 'pending_approval', 'approved', 'rejected', 'voided'));
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260401045525_AddVoidAuditStatus') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260401045525_AddVoidAuditStatus', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260402083752_AddUpdatedAtIndexes_V1') THEN
    CREATE INDEX "IX_templates_updated_at" ON templates (updated_at);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260402083752_AddUpdatedAtIndexes_V1') THEN
    CREATE INDEX "IX_submissions_updated_at" ON submissions (updated_at);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260402083752_AddUpdatedAtIndexes_V1') THEN
    CREATE INDEX "IX_stores_updated_at" ON stores (updated_at);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260402083752_AddUpdatedAtIndexes_V1') THEN
    CREATE INDEX "IX_groups_updated_at" ON groups (updated_at);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260402083752_AddUpdatedAtIndexes_V1') THEN
    CREATE INDEX "IX_criteria_updated_at" ON criteria (updated_at);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260402083752_AddUpdatedAtIndexes_V1') THEN
    CREATE INDEX "IX_answers_updated_at" ON answers (updated_at);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260402083752_AddUpdatedAtIndexes_V1') THEN
    CREATE INDEX "IX_action_plans_updated_at" ON action_plans (updated_at);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260402083752_AddUpdatedAtIndexes_V1') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260402083752_AddUpdatedAtIndexes_V1', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260408112945_AddRoleCapabilities') THEN
    CREATE TABLE role_capabilities (
        id uuid NOT NULL DEFAULT (gen_random_uuid()),
        role character varying(50) NOT NULL,
        capability character varying(100) NOT NULL,
        created_at timestamp with time zone NOT NULL DEFAULT (now()),
        CONSTRAINT "PK_role_capabilities" PRIMARY KEY (id)
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260408112945_AddRoleCapabilities') THEN
    CREATE INDEX "IX_role_capabilities_role" ON role_capabilities (role);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260408112945_AddRoleCapabilities') THEN
    CREATE UNIQUE INDEX "UX_role_capabilities_role_capability" ON role_capabilities (role, capability);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260408112945_AddRoleCapabilities') THEN
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES ('9e86aa90-d1d0-40e2-b65b-13567123054b', 'admin', 'templates:create', TIMESTAMPTZ '2026-04-12T06:27:54.542764+00:00');
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES ('1d5d0627-a8cd-41e6-95be-906ec6f2d2dc', 'admin', 'templates:update', TIMESTAMPTZ '2026-04-12T06:27:54.542768+00:00');
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES ('a3a64385-cca7-4287-a03b-e5e63a9808b0', 'admin', 'templates:delete', TIMESTAMPTZ '2026-04-12T06:27:54.542768+00:00');
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES ('192bc9cf-860e-492b-90f0-27f4b84c0bd6', 'admin', 'stores:write', TIMESTAMPTZ '2026-04-12T06:27:54.542768+00:00');
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES ('fa123079-fea4-451b-a7c5-a2dc9ee3513f', 'admin', 'areas:write', TIMESTAMPTZ '2026-04-12T06:27:54.542768+00:00');
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES ('9ff4e042-e0d6-4193-b2a0-8a99c61a7cc8', 'admin', 'users:manage', TIMESTAMPTZ '2026-04-12T06:27:54.542768+00:00');
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES ('fc1cf31e-a741-431b-be89-e8ed32a5ed69', 'admin', 'analytics:admin', TIMESTAMPTZ '2026-04-12T06:27:54.542768+00:00');
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260408112945_AddRoleCapabilities') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260408112945_AddRoleCapabilities', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260408135714_AddPbacInvalidateTrigger') THEN
    CREATE OR REPLACE FUNCTION notify_pbac_change()
    RETURNS TRIGGER LANGUAGE plpgsql AS $$
    BEGIN
        PERFORM pg_notify('pbac_invalidate', 'reload');
        RETURN NEW;
    END;
    $$;

    DROP TRIGGER IF EXISTS trg_pbac_invalidate ON role_capabilities;

    CREATE TRIGGER trg_pbac_invalidate
    AFTER INSERT OR UPDATE OR DELETE ON role_capabilities
    FOR EACH STATEMENT
    EXECUTE FUNCTION notify_pbac_change();
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260408135714_AddPbacInvalidateTrigger') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260408135714_AddPbacInvalidateTrigger', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260409010423_SeedAdminManageRolesCapability') THEN
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES (gen_random_uuid(), 'admin', 'admin:manage_roles', now())
    ON CONFLICT (role, capability) DO NOTHING;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260409010423_SeedAdminManageRolesCapability') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260409010423_SeedAdminManageRolesCapability', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260409084817_SeedSubmissionsListCapability') THEN
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES 
        (gen_random_uuid(), 'admin', 'submissions:list', now()),
        (gen_random_uuid(), 'auditor', 'submissions:list', now()),
        (gen_random_uuid(), 'store_manager', 'submissions:list', now()),
        (gen_random_uuid(), 'area_manager', 'submissions:list', now())
    ON CONFLICT (role, capability) DO NOTHING;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260409084817_SeedSubmissionsListCapability') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260409084817_SeedSubmissionsListCapability', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260410000250_SeedAnalyticsAreaCapability') THEN
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES
        (gen_random_uuid(), 'area_manager', 'analytics:area', now())
    ON CONFLICT (role, capability) DO NOTHING;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260410000250_SeedAnalyticsAreaCapability') THEN
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES
        (gen_random_uuid(), 'admin', 'templates:create',  now()),
        (gen_random_uuid(), 'admin', 'templates:update',  now()),
        (gen_random_uuid(), 'admin', 'templates:delete',  now()),
        (gen_random_uuid(), 'admin', 'stores:write',      now()),
        (gen_random_uuid(), 'admin', 'areas:write',       now()),
        (gen_random_uuid(), 'admin', 'users:manage',      now()),
        (gen_random_uuid(), 'admin', 'analytics:admin',   now()),
        (gen_random_uuid(), 'admin', 'analytics:area',    now()),
        (gen_random_uuid(), 'admin', 'submissions:list',  now()),
        (gen_random_uuid(), 'admin', 'admin:manage_roles',now())
    ON CONFLICT (role, capability) DO NOTHING;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260410000250_SeedAnalyticsAreaCapability') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260410000250_SeedAnalyticsAreaCapability', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260410021648_SeedAdminAccessCapability') THEN
    INSERT INTO role_capabilities (id, role, capability, created_at)
    VALUES (gen_random_uuid(), 'admin', 'admin:access', now())
    ON CONFLICT (role, capability) DO NOTHING;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260410021648_SeedAdminAccessCapability') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260410021648_SeedAdminAccessCapability', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260411165653_AddNotificationTypeIndex') THEN
    CREATE INDEX "IX_notifications_user_id_type" ON notifications (user_id, type);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260411165653_AddNotificationTypeIndex') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260411165653_AddNotificationTypeIndex', '10.0.4');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260412062737_AddInvalidateTokensBeforeToUser') THEN
    ALTER TABLE "AspNetUsers" ADD invalidate_tokens_before timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260412062737_AddInvalidateTokensBeforeToUser') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260412062737_AddInvalidateTokensBeforeToUser', '10.0.4');
    END IF;
END $EF$;
COMMIT;

