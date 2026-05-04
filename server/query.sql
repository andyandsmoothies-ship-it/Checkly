DO $$ 
DECLARE
    new_user_id uuid := gen_random_uuid();
BEGIN
    INSERT INTO "AspNetUsers" ("Id", "UserName", "NormalizedUserName", "Email", "NormalizedEmail", "EmailConfirmed", "PasswordHash", "SecurityStamp", "ConcurrencyStamp", "PhoneNumberConfirmed", "TwoFactorEnabled", "LockoutEnabled", "AccessFailedCount")
    VALUES (new_user_id, 'admin@checkly.local', 'ADMIN@CHECKLY.LOCAL', 'admin@checkly.local', 'ADMIN@CHECKLY.LOCAL', true, 'AQAAAAIAAYagAAAAENj2u97I9IP6W2NNnbZQBBWKNfrZufSJtfKtxPZy49PpDCSxmQeTloZleGKcwdZobw==', gen_random_uuid()::text, gen_random_uuid()::text, false, false, true, 0);

    INSERT INTO profiles ("id", "full_name", "email", "created_at", "updated_at")
    VALUES (new_user_id, 'System Admin', 'admin@checkly.local', now(), now());

    INSERT INTO user_roles ("id", "user_id", "role", "created_at")
    VALUES (gen_random_uuid(), new_user_id, 'admin', now());
END $$;
