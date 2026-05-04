DO $$ 
DECLARE 
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT "Id", "Email" FROM "AspNetUsers" 
        WHERE "Email" LIKE 'sm%@checkly.local' OR "Email" LIKE 'am%@checkly.local'
    LOOP
        -- Check if role already exists to avoid duplicates
        IF NOT EXISTS (SELECT 1 FROM user_roles WHERE user_id = rec."Id") THEN
            IF rec."Email" LIKE 'sm%' THEN
                INSERT INTO user_roles (id, user_id, role, created_at) VALUES (gen_random_uuid(), rec."Id", 'store_manager', now());
            ELSIF rec."Email" LIKE 'am%' THEN
                INSERT INTO user_roles (id, user_id, role, created_at) VALUES (gen_random_uuid(), rec."Id", 'area_manager', now());
            END IF;
        END IF;
    END LOOP;
END $$;
