-- ============================================================
-- Checkly UAT Seed Data (snake_case schema)
-- ============================================================
-- Run AFTER EF Core migrations and user registration.
-- ============================================================

-- ============================================================
-- Step 1: Promote admin user
-- ============================================================
UPDATE user_roles SET role = 'admin'
WHERE user_id = (SELECT "Id" FROM "AspNetUsers" WHERE "Email" = 'admin@checkly.local');

-- ============================================================
-- Step 2: Sample Stores (for UAT testing)
-- ============================================================
INSERT INTO stores (id, name, address, area_code, is_active, created_at, updated_at)
SELECT gen_random_uuid(), v.name, v.address, v.area_code, true, NOW(), NOW()
FROM (VALUES
  ('Cửa hàng Quận 1',     '123 Nguyễn Huệ, Q.1, TP.HCM',     'Q1'),
  ('Cửa hàng Quận 7',     '456 Nguyễn Thị Thập, Q.7, TP.HCM', 'Q7'),
  ('Cửa hàng Bình Thạnh', '789 Điện Biên Phủ, Bình Thạnh',    'BT'),
  ('Cửa hàng Thủ Đức',    '321 Võ Văn Ngân, Thủ Đức',         'TD'),
  ('Cửa hàng Gò Vấp',     '654 Quang Trung, Gò Vấp',          'GV')
) AS v(name, address, area_code)
WHERE NOT EXISTS (SELECT 1 FROM stores s WHERE s.name = v.name);


-- ============================================================
-- Verify: Check seeded data
-- ============================================================
SELECT 'Users & Roles:' AS info;
SELECT u."Email", r.role FROM "AspNetUsers" u JOIN user_roles r ON r.user_id = u."Id";

SELECT 'Stores:' AS info;
SELECT name, area_code FROM stores;

SELECT 'Template & Criteria:' AS info;
SELECT t.title, COUNT(c.id) AS criteria_count
FROM templates t
JOIN groups g ON g.template_id = t.id
JOIN criteria c ON c.group_id = g.id
GROUP BY t.title;
