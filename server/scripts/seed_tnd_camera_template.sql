-- ============================================================
-- Seed Data: [MAYCHA] - Store Visit - Camera (V011124)
-- ============================================================
DO $$
DECLARE
  t_id UUID := gen_random_uuid();
  g_root    UUID := gen_random_uuid();
BEGIN

-- Insert Template
INSERT INTO templates (id, title, description, type, version, scoring_logic_config, display_noun, is_active, created_at, updated_at)
VALUES (t_id, '[MAYCHA] TnD Store Visit - Camera', 'Bản mẫu Store Visit (V011124) Gián tiếp qua Camera', 'training', 1, '{"scoringMode":"accumulation"}', 'Audit', true, NOW(), NOW());

-- Insert Group
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_root, t_id, NULL, 'GIÁN TIẾP THÔNG QUA CAMERA', 0, true, NOW(), NOW());

-- Insert Criteria 66
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_root, 'FOH-SE Nhân viên sẵn sàng phục vụ - Đồng phục/tác phong đúng quy định - Menu cầm tay, túi đựng tiền lẻ thanh toán & điện thoại đăng nhập PDA định danh sẵn sàng - POSM đầy đủ, được cập nhật, trong tình trạng sử dụng tốt & được sắp xếp đầy đủ - Bình trà cho Shipper sạch sẽ, sẵn sàng phục vụ - Nhân viên có thực hiện up-selling/cross-selling - Stock các sản phẩm tại quầy ra món (Nếu có) theo quy định & đảm bảo tiêu chuẩn - Tổng thể khu vực đón khách, vỉa hè sạch sẽ, gọn gàng', 'pass_fail', 1.0, false, false, 0, true, NOW(), NOW());

-- Insert Criteria 67
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_root, 'FOH-CA Nhân viên sẵn sàng phục vụ - Đồng phục/tác phong đúng quy định - OPEN/CLOSE cửa hàng & ON/OFF món trên App - Thực hiện bàn giao tiền giữa CA & SE đúng quy định & được ghi nhận vào sổ vận hành ca hoàn hảo - Tổng thể khu vực sạch sẽ, gọn gàng', 'pass_fail', 1.0, false, false, 1, true, NOW(), NOW());

-- Insert Criteria 68
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_root, 'BOH-BA Nhân viên sẵn sàng phục vụ - Đồng phục/tác phong đúng quy định - Sơ chế/pha chế đúng tiêu chuẩn - Bảo quản hàng hóa đúng tiêu chuẩn - Tổng thể khu vực sạch sẽ, gọn gàng - Không có sự xuất hiện các vấn đề mang tính rủi ro nghiêm trọng (RISK): Sử dụng hàng hóa hết HSD, có hành vi thay tem HSD/kéo dài HSD, sử dụng hàng hóa hư hỏng để phục vụ khách hàng', 'pass_fail', 0.0, false, false, 2, true, NOW(), NOW());

-- Insert Criteria 69
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_root, 'BOH-KI Nhân viên sẵn sàng phục vụ - Đồng phục/tác phong đúng quy định - Sơ chế/pha chế đúng tiêu chuẩn - Bảo quản hàng hóa đúng tiêu chuẩn - Tổng thể khu vực sạch sẽ, gọn gàng - Không có sự xuất hiện các vấn đề mang tính rủi ro nghiêm trọng (RISK): Sử dụng hàng hóa hết HSD, có hành vi thay tem HSD/kéo dài HSD, sử dụng hàng hóa hư hỏng để phục vụ khách hàng', 'pass_fail', 0.0, false, false, 3, true, NOW(), NOW());

-- Insert Criteria 70
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_root, 'MODs Thực hiện travel path & ghi nhận sổ vận hành đầy đủ - Quy trình quản lý tiền: Bàn giao tiền (Sales & petty cash) giữa CA & MODs đúng quy định & ghi nhận đầy đủ sổ bàn giao doanh thu, lưu trữ sales & petty cash đúng quy định - Làm chủ được ca làm việc, luôn theo sát vận hành & xử lý các tình huống phát sinh hợp lý', 'pass_fail', 1.0, false, false, 4, true, NOW(), NOW());

END $$;
