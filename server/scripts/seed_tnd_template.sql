-- ============================================================
-- Seed Data: [MAYCHA] - Store Visit (V011124)
-- ============================================================
DO $$
DECLARE
  t_id UUID := gen_random_uuid();
  g_A UUID := gen_random_uuid();
  g_1 UUID := gen_random_uuid();
  g_2 UUID := gen_random_uuid();
  g_3 UUID := gen_random_uuid();
  g_4 UUID := gen_random_uuid();
  g_B UUID := gen_random_uuid();
  g_6 UUID := gen_random_uuid();
  g_7 UUID := gen_random_uuid();
  g_8 UUID := gen_random_uuid();
  g_C UUID := gen_random_uuid();
  g_10 UUID := gen_random_uuid();
  g_11 UUID := gen_random_uuid();
  g_D UUID := gen_random_uuid();
BEGIN

-- Insert Template
INSERT INTO templates (id, title, description, type, version, scoring_logic_config, display_noun, is_active, created_at, updated_at)
VALUES (t_id, '[MAYCHA] TnD Store Visit - In Person', 'Bản mẫu Store Visit (V011124) chuyển đổi từ Google Form', 'weighted', 1, '{"scoringMode":"accumulation"}', 'Audit', true, NOW(), NOW());

-- Insert Groups
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_A, t_id, NULL, 'FOH CHECKLIST', 0, true, NOW(), NOW());
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_1, t_id, g_A, 'A1-KHU VỰC BÊN NGOÀI CỬA HÀNG', 1, true, NOW(), NOW());
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_2, t_id, g_A, 'A2-KHU VỰC PHỤC VỤ (SE)_NHÓM TƯ VẤN', 2, true, NOW(), NOW());
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_3, t_id, g_A, 'A3-KHU VỰC PHỤC VỤ (SE)_NHÓM RA MÓN', 3, true, NOW(), NOW());
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_4, t_id, g_A, 'A4-KHU VỰC THU NGÂN (CA)', 4, true, NOW(), NOW());
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_B, t_id, NULL, 'BOH CHECKLIST', 5, true, NOW(), NOW());
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_6, t_id, g_B, 'B1-KHU VỰC PHA CHẾ (BA)', 6, true, NOW(), NOW());
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_7, t_id, g_B, 'B2-KHU VỰC BẾP PHA CHẾ (KI)', 7, true, NOW(), NOW());
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_8, t_id, g_B, 'B3-KHU VỰC TOILET/ KHÔNG GIAN CỬA HÀNG', 8, true, NOW(), NOW());
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_C, t_id, NULL, 'OPERATION FOCUS', 9, true, NOW(), NOW());
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_10, t_id, g_C, 'C1-SALES', 10, true, NOW(), NOW());
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_11, t_id, g_C, 'C2-COST CONTROL', 11, true, NOW(), NOW());
INSERT INTO groups (id, template_id, parent_id, title, order_index, is_active, created_at, updated_at)
VALUES (g_D, t_id, NULL, 'PRODUCT (SẢN PHẨM)', 12, true, NOW(), NOW());

-- Insert Criteria
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_1, 'A1.1-Bảng hiệu, bảng vẫy, đèn led,... hoạt động tốt', 'pass_fail', 1.0, false, false, 0, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_1, 'A1.2-Khu vực đón khách, vỉa hè,.. sạch sẽ', 'pass_fail', 1.0, false, false, 1, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_1, 'A1.3-Khu vực thùng rác sạch sẽ, không có mùi', 'pass_fail', 1.0, false, false, 2, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_1, 'A1.4-Không có rác tập trung thành đống', 'pass_fail', 1.0, false, false, 3, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_1, 'A1.5-POSM (Standee, TVC, Âm nhạc, Menu..) được cập nhật, trong tình trạng sử dụng tốt, thùng trà đá shipper sẵn sàng phục vụ', 'pass_fail', 4.0, false, false, 4, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_1, 'A1.6-Xe nhân viên để gọn gàng', 'pass_fail', 1.0, false, false, 5, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_2, 'A2.1-Dù sẵn có tại khu vực tư vấn. Layout bàn ghế gọn gàng, sạch sẽ', 'pass_fail', 1.0, false, false, 0, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_2, 'A2.2-Menu cầm tay, túi đựng tiền lẻ thanh toán, điện thoại đăng nhập PDA định danh sẵn sàng', 'pass_fail', 4.0, false, false, 1, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_2, 'A2.4-100% khách hàng được tiếp cận nhanh và cười tươi, chào đón cùng câu "maycha xin chào" khi đến cửa hàng', 'pass_fail', 1.0, false, false, 2, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_2, 'A2.5-100% khách hàng được nhận hóa đơn thanh toán', 'pass_fail', 1.0, false, false, 3, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_2, 'A2.7-Nhân viên chủ động quan sát, có kiến thức về tư vấn khách hàng, các chương trình bán hàng tại cửa hàng & thực hiện up-selling/cross-selling và có tư vấn chương trình MKT đến 100% khách hàng', 'pass_fail', 3.0, false, false, 4, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_3, 'A3.1-Khu vực ra món sạch sẽ, gọn gàng, không bám bụi', 'pass_fail', 1.0, false, false, 0, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_3, 'A3.2-Công cụ dụng cụ đầy đủ để phục vụ trong ca', 'pass_fail', 1.0, false, false, 1, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_3, 'A3.3-Các loại hàng hóa được stock sẵn tại quầy ra món luôn sẵn sàng phục vụ & đảm bảo tiêu chuẩn (Nếu có). Ví dụ: Trân châu phô mai', 'pass_fail', 3.0, false, false, 2, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_3, 'A3.4-Nhân viên có kiến thức về kiểm tra sản phẩm/đóng gói sản phẩm theo đơn hàng trước khi giao đến khách hàng', 'pass_fail', 3.0, false, false, 3, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_4, 'A4.1-Khu vực thu ngân sạch sẽ, dây điện được xử lý gọn gàng, bánh tráng được trưng bày đầy đủ trên kệ', 'pass_fail', 1.0, false, false, 0, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_4, 'A4.2-Cập nhật OPEN/CLOSE cửa hàng & các món ON/OFF trên App, POS. Cập nhật các món cần push hàng trong ca', 'pass_fail', 2.0, false, false, 1, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_4, 'A4.3-Quy trình bàn giao tiền giữa CA & SE được thực hiện đúng quy định & ghi nhận đầy đủ trong sổ vận hành ca hoàn hảo', 'pass_fail', 2.0, false, false, 2, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_4, 'A4.4-Nhân viên có kiến thức về nghiệp vụ công việc của CA', 'pass_fail', 1.0, false, false, 3, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.1-Khu vực BA luôn sạch sẽ, gọn gàng', 'pass_fail', 1.0, false, false, 0, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.2-Trang thiết bị & tình trạng hoạt động tốt, RTC được dán đúng nơi quy định', 'pass_fail', 2.0, false, false, 1, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.3-Setup công cụ dụng cụ, trang thiết bị, nguyên vật liệu/bán thành phẩm đầy đủ theo projection (prep plan)', 'pass_fail', 3.0, false, false, 2, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.4-Hạn sử dụng của toàn bộ hàng hóa (Đã mở bao bì) đúng quy định', 'pass_fail', 4.0, false, false, 3, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.5-Hạn sử dụng của toàn bộ hàng hóa (Chưa mở bao bì) đúng quy định', 'pass_fail', 4.0, false, false, 4, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.6-Không có sự xuất hiện các vấn đề mang tính rủi ro nghiêm trọng (RISK): Sử dụng hàng hóa hết HSD - Có hành vi thay tem HSD/kéo dài HSD - Sử dụng hàng hóa hư hỏng để phục vụ khách hàng', 'pass_fail', 0.0, false, false, 5, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.7-Sắp xếp và sử dụng hàng hóa theo FIFO, FEFO', 'pass_fail', 3.0, false, false, 6, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.8-Quality Checklist được update mới, dán đúng nơi quy định và được sử dụng đúng công năng', 'pass_fail', 1.0, false, false, 7, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.9-Bảng theo dõi nhiệt độ trang thiết bị được ghi nhận đầy đủ', 'pass_fail', 1.0, false, false, 8, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.10-Tuân thủ layout kho hàng & sắp xếp, phân loại hàng hóa đúng quy định', 'pass_fail', 3.0, false, false, 9, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.11-Kệ ưu tiên trong tủ ACC được sắp xếp đúng công năng: Cánh 1 - HSD ngày hôm nay, Cánh 2 & 3 - HSD ngày tiếp theo', 'pass_fail', 1.0, false, false, 10, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.12-Thực hiện hủy hàng, ghi nhận sổ thẻ kho và File Inventory (Nếu có)', 'pass_fail', 1.0, false, false, 11, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_6, 'B1.13-Nhân viên có kiến thức về nghiệp vụ công việc của BA', 'pass_fail', 1.0, false, false, 12, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_7, 'B2.1-Khu vực KI luôn sạch sẽ, gọn gàng', 'pass_fail', 1.0, false, false, 0, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_7, 'B2.2-Trang thiết bị & tình trạng hoạt động tốt, RTC được dán đúng nơi quy định', 'pass_fail', 1.0, false, false, 1, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_7, 'B2.3-Setup công cụ dụng cụ, trang thiết bị, nguyên vật liệu/bán thành phẩm đầy đủ theo projection (prep plan)', 'pass_fail', 3.0, false, false, 2, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_7, 'B2.4-Hạn sử dụng của toàn bộ hàng hóa (Chưa mở bao bì) đúng quy định', 'pass_fail', 3.0, false, false, 3, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_7, 'B2.5-Hạn sử dụng của toàn bộ hàng hóa (Đã mở bao bì) đúng quy định', 'pass_fail', 3.0, false, false, 4, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_7, 'B2.6-Không có sự xuất hiện các vấn đề mang tính rủi ro nghiêm trọng (RISK): Sử dụng hàng hóa hết HSD - Có hành vi thay tem HSD/kéo dài HSD - Sử dụng hàng hóa hư hỏng để phục vụ khách hàng', 'pass_fail', 0.0, false, false, 5, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_7, 'B2.7-Sắp xếp và sử dụng hàng hóa theo FIFO, FEFO', 'pass_fail', 1.0, false, false, 6, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_7, 'B2.8-Bảng theo dõi nhiệt độ trang thiết bị được ghi nhận đầy đủ', 'pass_fail', 1.0, false, false, 7, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_7, 'B2.9-Tuân thủ layout kho hàng & sắp xếp, phân loại hàng hóa đúng quy định', 'pass_fail', 3.0, false, false, 8, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_7, 'B2.10-Kệ ưu tiên tủ mát được sắp xếp đúng công năng các HSD trong ngày hôm nay, các NVL/BTP đã mở bao bì', 'pass_fail', 3.0, false, false, 9, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_7, 'B2.11-Thực hiện hủy hàng, ghi nhận sổ thẻ kho và INVENTORY Tool (Nếu có)', 'pass_fail', 1.0, false, false, 10, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_7, 'B2.12-Nhân viên có kiến thức về nghiệp vụ công việc của KI', 'pass_fail', 3.0, false, false, 11, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_8, 'B3.1-Toilet đảm bảo không có mùi, sạch sẽ, CCDC vệ sinh treo gọn gàng', 'pass_fail', 1.0, false, false, 0, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_8, 'B3.2-Kho được sắp xếp gọn gàng, ngăn nắp, không có dấu hiệu côn trùng', 'pass_fail', 1.0, false, false, 1, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_10, 'C1.1-Thực hiện Manager Checklist theo khung giờ: Mở ca Bàn giao ca - Đóng ca', 'pass_fail', 3.0, false, false, 0, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_10, 'C1.2-Quy trình quản lý tiền: + Nộp sales vào ngân hàng đúng quy định. + Bàn giao tiền (Sales & petty cash) giữa CA & MODs đúng quy định. + Ghi nhận đầy đủ sổ bàn giao doanh thu', 'pass_fail', 2.0, false, false, 1, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_11, 'C2.1-Đặt hàng không dư hoặc quá nhiều hàng hóa', 'pass_fail', 3.0, false, false, 0, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_11, 'C2.2-Nhận hàng theo bộ tiêu chuẩn (Bộ tiêu chuẩn được cập nhật mới nhất luôn sẵn sàng tại cửa hàng)', 'pass_fail', 3.0, false, false, 1, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_11, 'C2.3-Sổ thẻ kho được ghi nhận đầy đủ (Kiểm đếm hàng hóa, ghi nhận Nhập-Xuất-Tồn & đối soát variance thông qua Inventory Tool được ghi nhận đầy đủ)', 'pass_fail', 2.0, false, false, 2, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_11, 'C2.4-Nhân viên đã được certify hoặc đang trong thời gian training tại bộ phận (Tuân thủ theo training plan & training roadmap)', 'pass_fail', 3.0, false, false, 3, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_11, 'C2.5-Đồng phục, tác phong nhân viên trong ca làm việc (FOH & BOH)', 'pass_fail', 1.0, false, false, 4, true, NOW(), NOW());
INSERT INTO criteria (id, group_id, label, input_type, points_weight, is_ccp, is_risk, order_index, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), g_D, 'Chọn BTP (Topping/Cốt trà sữa) để test và ra kết luận...', 'pass_fail', 0.0, false, false, 0, true, NOW(), NOW());
END $$;