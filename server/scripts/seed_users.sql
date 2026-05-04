DO $$ 
DECLARE 
    i INT;
    v_email VARCHAR;
    v_user_id UUID;
    v_hash VARCHAR := 'AQAAAAIAAYagAAAAECLlZ5q2eQAOfH1I3ao+dw1j9FbySgF/A8ajgndAK7BW9ojVt9Wwpv9R+OHGd4kWew==';
BEGIN
    -- Create sm1 to sm10
    FOR i IN 1..10 LOOP
        v_email := 'sm' || i || '@checkly.local';
        v_user_id := gen_random_uuid();
        
        INSERT INTO "AspNetUsers" ("Id", "UserName", "NormalizedUserName", "Email", "NormalizedEmail", "EmailConfirmed", "PasswordHash", "SecurityStamp", "ConcurrencyStamp", "PhoneNumberConfirmed", "TwoFactorEnabled", "LockoutEnabled", "AccessFailedCount")
        VALUES (v_user_id, v_email, UPPER(v_email), v_email, UPPER(v_email), true, v_hash, gen_random_uuid()::text, gen_random_uuid()::text, false, false, true, 0);
        
        INSERT INTO "profiles" ("id", "full_name", "email", "created_at", "updated_at")
        VALUES (v_user_id, 'Store Manager ' || i, v_email, now(), now());
    END LOOP;

    -- Create am1 and am2
    FOR i IN 1..2 LOOP
        v_email := 'am' || i || '@checkly.local';
        v_user_id := gen_random_uuid();
        
        INSERT INTO "AspNetUsers" ("Id", "UserName", "NormalizedUserName", "Email", "NormalizedEmail", "EmailConfirmed", "PasswordHash", "SecurityStamp", "ConcurrencyStamp", "PhoneNumberConfirmed", "TwoFactorEnabled", "LockoutEnabled", "AccessFailedCount")
        VALUES (v_user_id, v_email, UPPER(v_email), v_email, UPPER(v_email), true, v_hash, gen_random_uuid()::text, gen_random_uuid()::text, false, false, true, 0);
        
        INSERT INTO "profiles" ("id", "full_name", "email", "created_at", "updated_at")
        VALUES (v_user_id, 'Area Manager ' || i, v_email, now(), now());
    END LOOP;
END $$;
