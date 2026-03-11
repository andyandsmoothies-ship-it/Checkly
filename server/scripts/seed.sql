-- ============================================================
-- Checkly UAT Seed Data
-- ============================================================
-- Run this AFTER EF Core migrations have been applied:
--   dotnet ef database update
--
-- IMPORTANT: Do NOT include passwords here.
-- Create the admin user via the /api/auth/register endpoint,
-- then use this script to assign the admin role.
-- ============================================================

-- Step 1: Register an admin user via API first:
--   POST /api/auth/register
--   { "email": "admin@checkly.local", "password": "...", "fullName": "Admin" }
--
-- Then assign admin role (replace <USER_ID> with the actual ID):
-- UPDATE "Users" SET "Role" = 'admin' WHERE "Email" = 'admin@checkly.local';

-- ============================================================
-- Sample Stores (for UAT testing)
-- ============================================================
INSERT INTO "Stores" ("Id", "Name", "Address", "AreaCode", "IsActive", "CreatedAt", "UpdatedAt")
VALUES
  (gen_random_uuid(), 'Cửa hàng Quận 1',   '123 Nguyễn Huệ, Q.1, TP.HCM',    'Q1',  true, NOW(), NOW()),
  (gen_random_uuid(), 'Cửa hàng Quận 7',   '456 Nguyễn Thị Thập, Q.7, TP.HCM', 'Q7',  true, NOW(), NOW()),
  (gen_random_uuid(), 'Cửa hàng Bình Thạnh', '789 Điện Biên Phủ, Bình Thạnh',   'BT',  true, NOW(), NOW()),
  (gen_random_uuid(), 'Cửa hàng Thủ Đức',  '321 Võ Văn Ngân, Thủ Đức',         'TD',  true, NOW(), NOW()),
  (gen_random_uuid(), 'Cửa hàng Gò Vấp',   '654 Quang Trung, Gò Vấp',          'GV',  true, NOW(), NOW());

-- ============================================================
-- Sample Template: "Vệ sinh An toàn Thực phẩm" (Food Safety)
-- ============================================================
-- NOTE: Template, Group, and Criteria IDs are generated here
-- so they can cross-reference each other.

DO $$
DECLARE
  t_id UUID := gen_random_uuid();
  g1_id UUID := gen_random_uuid();
  g2_id UUID := gen_random_uuid();
BEGIN

-- Template
INSERT INTO "Templates" ("Id", "Title", "Description", "Type", "Version", "IsActive", "CreatedAt", "UpdatedAt")
VALUES (t_id, 'Vệ sinh An toàn Thực phẩm', 'Kiểm tra tiêu chuẩn ATTP hàng tháng', 'weighted', 1, true, NOW(), NOW());

-- Section 1: Khu vực bếp (Kitchen Area)
INSERT INTO "Groups" ("Id", "TemplateId", "Title", "Description", "Weight", "OrderIndex", "IsActive", "CreatedAt", "UpdatedAt")
VALUES (g1_id, t_id, 'Khu vực bếp', 'Kiểm tra khu vực chế biến', 60.0, 0, true, NOW(), NOW());

-- Section 2: Khu vực phục vụ (Service Area)
INSERT INTO "Groups" ("Id", "TemplateId", "Title", "Description", "Weight", "OrderIndex", "IsActive", "CreatedAt", "UpdatedAt")
VALUES (g2_id, t_id, 'Khu vực phục vụ', 'Kiểm tra khu vực tiếp khách', 40.0, 1, true, NOW(), NOW());

-- Criteria for Section 1
INSERT INTO "Criteria" ("Id", "GroupId", "Label", "Description", "InputType", "PointsWeight", "IsCcp", "IsRisk", "OrderIndex", "IsActive", "CreatedAt", "UpdatedAt")
VALUES
  (gen_random_uuid(), g1_id, 'Sàn nhà sạch sẽ',        'Không có rác, nước đọng',       'boolean', 10.0, false, false, 0, true, NOW(), NOW()),
  (gen_random_uuid(), g1_id, 'Nhiệt độ tủ lạnh',       'Dưới 5°C',                      'numeric', 15.0, true,  false, 1, true, NOW(), NOW()),
  (gen_random_uuid(), g1_id, 'Dụng cụ được khử trùng', 'Dao, thớt, dụng cụ nấu nướng',  'boolean', 15.0, true,  true,  2, true, NOW(), NOW()),
  (gen_random_uuid(), g1_id, 'Nhân viên đeo găng tay',  'Khi chế biến thực phẩm',        'boolean', 10.0, false, false, 3, true, NOW(), NOW()),
  (gen_random_uuid(), g1_id, 'Thùng rác có nắp đậy',   'Đầy đủ và sạch sẽ',             'boolean', 10.0, false, false, 4, true, NOW(), NOW());

-- Criteria for Section 2
INSERT INTO "Criteria" ("Id", "GroupId", "Label", "Description", "InputType", "PointsWeight", "IsCcp", "IsRisk", "OrderIndex", "IsActive", "CreatedAt", "UpdatedAt")
VALUES
  (gen_random_uuid(), g2_id, 'Bàn ghế sạch sẽ',         'Không có vết bẩn, đồ ăn thừa',  'boolean', 10.0, false, false, 0, true, NOW(), NOW()),
  (gen_random_uuid(), g2_id, 'Menu rõ ràng, sạch sẽ',   'Không rách, không bẩn',          'boolean', 10.0, false, false, 1, true, NOW(), NOW()),
  (gen_random_uuid(), g2_id, 'Nhà vệ sinh đạt chuẩn',   'Có xà phòng, giấy, nước sạch',  'boolean', 10.0, false, true,  2, true, NOW(), NOW()),
  (gen_random_uuid(), g2_id, 'Khu vực rửa tay khách',    'Có xà phòng và khăn giấy',      'boolean', 10.0, false, false, 3, true, NOW(), NOW());

END $$;

-- ============================================================
-- Verification: Check data was seeded correctly
-- ============================================================
-- SELECT COUNT(*) AS store_count FROM "Stores";
-- SELECT t."Title", COUNT(g."Id") AS sections FROM "Templates" t JOIN "Groups" g ON g."TemplateId" = t."Id" GROUP BY t."Title";
-- SELECT g."Title", COUNT(c."Id") AS criteria FROM "Groups" g JOIN "Criteria" c ON c."GroupId" = g."Id" GROUP BY g."Title";
