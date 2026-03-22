-- ============================================================
-- Store Visit Template Fix Script
-- Template ID: 615a7dc3-40d8-460f-831e-0f3a152838a8
-- Fixes: Trà Hú type/pts, Camera type/pts, D-PRODUCT missing,
--        truncated labels/descriptions
-- ============================================================

SET client_encoding = 'UTF8';

-- ============================================================
-- FIX 1: Trà Hú (TH1–TH5) → input_type='text', points_weight=0
-- These are information-gathering text questions, not scored items
-- ============================================================
UPDATE criteria SET input_type = 'text', points_weight = 0
WHERE group_id = (
    SELECT g.id FROM groups g
    WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8'
    AND g.title LIKE '%TRÀ HÚ%'
);

-- ============================================================
-- FIX 2: Camera (FOH-SE, FOH-CA, BOH-BA, BOH-KI, MODs)
-- → input_type='text', points_weight=0
-- These are observation note paragraphs, not scored items
-- ============================================================
UPDATE criteria SET input_type = 'text', points_weight = 0
WHERE group_id = (
    SELECT g.id FROM groups g
    WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8'
    AND g.title LIKE '%CAMERA%'
);

-- ============================================================
-- FIX 3: Add D-PRODUCT section + 1 criterion
-- ============================================================
DO $$
DECLARE
    dp_group_id UUID := gen_random_uuid();
    t_id UUID := '615a7dc3-40d8-460f-831e-0f3a152838a8';
    camera_order INT;
BEGIN
    -- Get the current order_index of the Camera group (last group)
    SELECT g.order_index INTO camera_order
    FROM groups g
    WHERE g.template_id = t_id AND g.title LIKE '%CAMERA%';

    -- Shift Camera group up by 1 to make room for D-PRODUCT before it
    UPDATE groups SET order_index = camera_order + 1
    WHERE template_id = t_id AND title LIKE '%CAMERA%';

    -- Insert D-PRODUCT group at the Camera's old position
    INSERT INTO groups (id, template_id, title, description, weight, order_index, is_active, created_at, updated_at)
    VALUES (dp_group_id, t_id, 'D-PRODUCT (SẢN PHẨM)', 'Kiểm tra chất lượng sản phẩm', 1.0, camera_order, true, NOW(), NOW());

    -- Insert the D-PRODUCT criterion
    INSERT INTO criteria (id, group_id, label, description, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
    VALUES (gen_random_uuid(), dp_group_id,
        'PRODUCT - Chọn BTP (Topping/Cốt trà sữa) để test và ra kết luận',
        'Nếu không đạt vui lòng ghi rõ tên món - Không đạt chỗ nào - Nguyên nhân vì sao?',
        'single_choice', 0, false, false, 0, true, NOW(), NOW());
END $$;

-- ============================================================
-- FIX 4: Update truncated labels to include full text
-- ============================================================

-- B1.11: Add full detail to label
UPDATE criteria SET label = 'B1.11-Kệ ưu tiên trong tủ ACC được sắp xếp đúng công năng: Cánh 1 - HSD ngày hôm nay, Cánh 2 & 3 - HSD ngày tiếp theo'
WHERE group_id = (SELECT g.id FROM groups g WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8' AND g.title LIKE '%PHA CHẾ (BA)%')
AND label LIKE 'B1.11%';

-- B2.10: Add full detail to label
UPDATE criteria SET label = 'B2.10-Kệ ưu tiên tủ mát được sắp xếp đúng công năng các HSD trong ngày hôm nay, các NVL/BTP đã mở bao bì'
WHERE group_id = (SELECT g.id FROM groups g WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8' AND g.title LIKE '%BẾP PHA CHẾ (KI)%')
AND label LIKE 'B2.10%';

-- ============================================================
-- FIX 5: Add descriptions to truncated criteria
-- ============================================================

-- C1.2: Add sub-items as description
UPDATE criteria SET description = 'Nộp sales vào ngân hàng đúng quy định. Bàn giao tiền (Sales & petty cash) giữa CA & MODs đúng quy định. Ghi nhận đầy đủ sổ bàn giao doanh thu'
WHERE group_id = (SELECT g.id FROM groups g WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8' AND g.title = 'C1-SALES')
AND label LIKE 'C1.2%';

-- C2.2: Add parenthetical as description
UPDATE criteria SET description = 'Bộ tiêu chuẩn được cập nhật mới nhất luôn sẵn sàng tại cửa hàng'
WHERE group_id = (SELECT g.id FROM groups g WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8' AND g.title = 'C2-COST CONTROL')
AND label LIKE 'C2.2%';

-- C2.3: Add detail as description
UPDATE criteria SET description = 'Kiểm đếm hàng hóa, ghi nhận Nhập-Xuất-Tồn & đối soát variance thông qua Inventory Tool được ghi nhận đầy đủ'
WHERE group_id = (SELECT g.id FROM groups g WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8' AND g.title = 'C2-COST CONTROL')
AND label LIKE 'C2.3%';

-- C2.4: Add detail as description
UPDATE criteria SET description = 'Tuân thủ theo training plan & training roadmap'
WHERE group_id = (SELECT g.id FROM groups g WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8' AND g.title = 'C2-COST CONTROL')
AND label LIKE 'C2.4%';

-- ============================================================
-- FIX 6: Bump template version
-- ============================================================
UPDATE templates SET version = version + 1, updated_at = NOW()
WHERE id = '615a7dc3-40d8-460f-831e-0f3a152838a8';

-- ============================================================
-- VERIFY: Check the fixes
-- ============================================================
SELECT '=== TEMPLATE ===' AS info;
SELECT id, title, version FROM templates WHERE id = '615a7dc3-40d8-460f-831e-0f3a152838a8';

SELECT '=== GROUPS ===' AS info;
SELECT g.title, g.order_index, (SELECT COUNT(*) FROM criteria c WHERE c.group_id = g.id) AS crit_count
FROM groups g WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8'
ORDER BY g.order_index;

SELECT '=== TRÀ HÚ (should be text, 0pts) ===' AS info;
SELECT c.label, c.input_type, c.points_weight
FROM criteria c JOIN groups g ON c.group_id = g.id
WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8' AND g.title LIKE '%TRÀ HÚ%'
ORDER BY c.order_index;

SELECT '=== CAMERA (should be text, 0pts) ===' AS info;
SELECT c.label, c.input_type, c.points_weight
FROM criteria c JOIN groups g ON c.group_id = g.id
WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8' AND g.title LIKE '%CAMERA%'
ORDER BY c.order_index;

SELECT '=== D-PRODUCT (new) ===' AS info;
SELECT c.label, c.description, c.input_type, c.points_weight
FROM criteria c JOIN groups g ON c.group_id = g.id
WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8' AND g.title LIKE '%PRODUCT%'
ORDER BY c.order_index;

SELECT '=== UPDATED LABELS ===' AS info;
SELECT c.label, c.description
FROM criteria c JOIN groups g ON c.group_id = g.id
WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8'
AND (c.label LIKE 'B1.11%' OR c.label LIKE 'B2.10%' OR c.label LIKE 'C1.2%' OR c.label LIKE 'C2.2%' OR c.label LIKE 'C2.3%' OR c.label LIKE 'C2.4%')
ORDER BY g.order_index, c.order_index;
