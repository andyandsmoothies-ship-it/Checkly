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
-- Step 3: Sample Template - Food Safety Audit
-- ============================================================
DO $$
DECLARE
  t_id UUID := gen_random_uuid();
  g1_id UUID := gen_random_uuid();
  g2_id UUID := gen_random_uuid();
BEGIN

-- Template
INSERT INTO templates (id, title, description, type, version, is_active, created_at, updated_at)
VALUES (t_id, 'Vệ sinh An toàn Thực phẩm', 'Kiểm tra tiêu chuẩn ATTP hàng tháng', 'weighted', 1, true, NOW(), NOW());

-- Section 1: Kitchen Area
INSERT INTO groups (id, template_id, title, description, weight, order_index, is_active, created_at, updated_at)
VALUES (g1_id, t_id, 'Khu vực bếp', 'Kiểm tra khu vực chế biến', 60.0, 0, true, NOW(), NOW());

-- Section 2: Service Area
INSERT INTO groups (id, template_id, title, description, weight, order_index, is_active, created_at, updated_at)
VALUES (g2_id, t_id, 'Khu vực phục vụ', 'Kiểm tra khu vực tiếp khách', 40.0, 1, true, NOW(), NOW());

-- Criteria for Section 1 (Kitchen)
INSERT INTO criteria (id, group_id, label, description, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES
  (gen_random_uuid(), g1_id, 'Sàn nhà sạch sẽ',        'Không có rác, nước đọng',       'boolean', 10.0, false, false, 0, true, NOW(), NOW()),
  (gen_random_uuid(), g1_id, 'Nhiệt độ tủ lạnh',       'Dưới 5°C',                      'numeric', 15.0, true,  false, 1, true, NOW(), NOW()),
  (gen_random_uuid(), g1_id, 'Dụng cụ được khử trùng', 'Dao, thớt, dụng cụ nấu nướng',  'boolean', 15.0, true,  true,  2, true, NOW(), NOW()),
  (gen_random_uuid(), g1_id, 'Nhân viên đeo găng tay',  'Khi chế biến thực phẩm',        'boolean', 10.0, false, false, 3, true, NOW(), NOW()),
  (gen_random_uuid(), g1_id, 'Thùng rác có nắp đậy',   'Đầy đủ và sạch sẽ',             'boolean', 10.0, false, false, 4, true, NOW(), NOW());

-- Criteria for Section 2 (Service)
INSERT INTO criteria (id, group_id, label, description, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES
  (gen_random_uuid(), g2_id, 'Bàn ghế sạch sẽ',         'Không có vết bẩn, đồ ăn thừa',  'boolean', 10.0, false, false, 0, true, NOW(), NOW()),
  (gen_random_uuid(), g2_id, 'Menu rõ ràng, sạch sẽ',   'Không rách, không bẩn',          'boolean', 10.0, false, false, 1, true, NOW(), NOW()),
  (gen_random_uuid(), g2_id, 'Nhà vệ sinh đạt chuẩn',   'Có xà phòng, giấy, nước sạch',  'boolean', 10.0, false, true,  2, true, NOW(), NOW()),
  (gen_random_uuid(), g2_id, 'Khu vực rửa tay khách',    'Có xà phòng và khăn giấy',      'boolean', 10.0, false, false, 3, true, NOW(), NOW());

END $$;

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
