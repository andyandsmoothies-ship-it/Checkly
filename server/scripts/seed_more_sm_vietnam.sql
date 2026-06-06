DO $$ 
DECLARE 
    -- Variables for IDs
    v_hash VARCHAR := 'AQAAAAIAAYagAAAAEF77TZYrqUszIb5yTR0v6ghM2lcGM2VY5lL6wFF5jIsczA2V/IJcRh1azmqMK3Kg9A=='; -- Hash for Aa1234567@
    v_user_id UUID;
    v_store_id UUID;
    
    -- Arrays for Hanoi stores
    hanoi_names TEXT[] := ARRAY['Checkly Hoan Kiem', 'Checkly Ba Dinh', 'Checkly Cau Giay', 'Checkly Dong Da', 'Checkly Hai Ba Trung'];
    hanoi_addresses TEXT[] := ARRAY['1 Hang Bai, Hoan Kiem, Ha Noi', '15 Hung Vuong, Ba Dinh, Ha Noi', '120 Xuan Thuy, Cau Giay, Ha Noi', '99 Chua Boc, Dong Da, Ha Noi', '88 Pho Hue, Hai Ba Trung, Ha Noi'];
    
    -- Arrays for Central Vietnam stores
    central_names TEXT[] := ARRAY['Checkly Hai Chau', 'Checkly Hue', 'Checkly Nha Trang', 'Checkly Hoi An', 'Checkly Quy Nhon'];
    central_addresses TEXT[] := ARRAY['35 Bach Dang, Hai Chau, Da Nang', '5 Le Loi, TP Hue, Thua Thien Hue', '60 Tran Phu, Nha Trang, Khanh Hoa', '10 Tran Hung Dao, Hoi An, Quang Nam', '12 Nguyen Hue, Quy Nhon, Binh Dinh'];
    central_provinces TEXT[] := ARRAY['Đà Nẵng', 'Thừa Thiên Huế', 'Khánh Hòa', 'Quảng Nam', 'Bình Định'];
    
    i INT;
    v_email VARCHAR;
BEGIN

    -- 1. Create Hanoi Stores and Hanoi Store Managers (sm11 to sm15)
    FOR i IN 1..5 LOOP
        v_email := 'sm' || (10 + i) || '@checkly.local';
        v_user_id := gen_random_uuid();
        v_store_id := gen_random_uuid();
        
        -- Insert Store
        INSERT INTO stores (id, name, address, address_province, gps_lat, gps_lng, is_active, created_at, updated_at)
        VALUES (v_store_id, hanoi_names[i], hanoi_addresses[i], 'Hà Nội', 21.0285, 105.8542, true, NOW(), NOW());
        
        -- Insert Auth User
        INSERT INTO "AspNetUsers" ("Id", "UserName", "NormalizedUserName", "Email", "NormalizedEmail", "EmailConfirmed", "PasswordHash", "SecurityStamp", "ConcurrencyStamp", "PhoneNumberConfirmed", "TwoFactorEnabled", "LockoutEnabled", "AccessFailedCount")
        VALUES (v_user_id, v_email, UPPER(v_email), v_email, UPPER(v_email), true, v_hash, gen_random_uuid()::text, gen_random_uuid()::text, false, false, true, 0);
        
        -- Insert Profile and Link to Store
        INSERT INTO profiles (id, full_name, email, store_id, created_at, updated_at)
        VALUES (v_user_id, 'Store Manager ' || (10 + i), v_email, v_store_id, NOW(), NOW());
        
        -- Assign Role
        INSERT INTO user_roles (id, user_id, role, created_at)
        VALUES (gen_random_uuid(), v_user_id, 'store_manager', NOW());
    END LOOP;

    -- 2. Create Central Vietnam Stores and Store Managers (sm16 to sm20)
    FOR i IN 1..5 LOOP
        v_email := 'sm' || (15 + i) || '@checkly.local';
        v_user_id := gen_random_uuid();
        v_store_id := gen_random_uuid();
        
        -- Insert Store
        INSERT INTO stores (id, name, address, address_province, gps_lat, gps_lng, is_active, created_at, updated_at)
        VALUES (v_store_id, central_names[i], central_addresses[i], central_provinces[i], 16.0678, 108.2208, true, NOW(), NOW());
        
        -- Insert Auth User
        INSERT INTO "AspNetUsers" ("Id", "UserName", "NormalizedUserName", "Email", "NormalizedEmail", "EmailConfirmed", "PasswordHash", "SecurityStamp", "ConcurrencyStamp", "PhoneNumberConfirmed", "TwoFactorEnabled", "LockoutEnabled", "AccessFailedCount")
        VALUES (v_user_id, v_email, UPPER(v_email), v_email, UPPER(v_email), true, v_hash, gen_random_uuid()::text, gen_random_uuid()::text, false, false, true, 0);
        
        -- Insert Profile and Link to Store
        INSERT INTO profiles (id, full_name, email, store_id, created_at, updated_at)
        VALUES (v_user_id, 'Store Manager ' || (15 + i), v_email, v_store_id, NOW(), NOW());
        
        -- Assign Role
        INSERT INTO user_roles (id, user_id, role, created_at)
        VALUES (gen_random_uuid(), v_user_id, 'store_manager', NOW());
    END LOOP;

END $$;
