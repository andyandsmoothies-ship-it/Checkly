-- Update Construction Site Safety
UPDATE templates SET description = 'Đặc điểm: Cờ RISK đánh rớt 0% ngay lập tức cho các vi phạm đe dọa an toàn lao động, kết hợp hình thức phạt trừ điểm lũy tiến cho sai phạm lặp lại.
Kiểm tra an toàn công trường chi tiết:
- Định vị khu vực lỗi qua cấu trúc Section (Lô chung cư A) - Subsection (Tầng 15) - Criterion (Dây đai an toàn) để khoanh vùng rủi ro.
- Đình chỉ ngay lập tức các vi phạm nghiêm trọng qua Cờ RISK (Lỗi giàn giáo không rào chắn).
- Tăng mức phạt cho các lỗi tái phạm nhiều lần qua Phạt lũy tiến (Công nhân không đeo găng tay nhiều lần).'
WHERE id = '67d467eb-ed23-4875-bdff-19f429bd8428';

-- Update Customer Feedback Form
UPDATE templates SET description = 'Đặc điểm: Định dạng câu hỏi Nhiều lựa chọn (Multi-Choice) cho phép khách hàng chọn nhiều ý kiến, hoàn toàn không tính điểm phân loại.
Khảo sát ý kiến khách hàng:
- Thu thập sở thích qua cấu trúc Section (Sản phẩm) - Subsection (Dùng thử) - Criterion (Hương vị) để nắm bắt nhu cầu thực tế.
- Ghi nhận đa dạng ý kiến qua Chế độ Survey (Chọn nhiều phương án cùng lúc mà không tính điểm Đạt/Rớt).'
WHERE id = 'ac036932-2842-4332-bc28-e662b71777b1';

-- Update Daily Opening Checklist
UPDATE templates SET description = 'Đặc điểm: Chế độ trừ điểm phẳng (Checklist Mode), mỗi mục vi phạm hoặc chưa hoàn thành sẽ bị trừ 1 điểm.
Kiểm tra chuẩn chuẩn bị đầu ngày:
- Rà soát công việc qua cấu trúc Section (Khu vực POS) - Subsection (Thiết bị) - Criterion (Bật máy in bill) để không bỏ sót đầu việc.
- Xác nhận hoàn thành từng đầu việc qua Chế độ Checklist (Mỗi mục chưa xong trừ 1 điểm phẳng).'
WHERE id = 'c607b147-f6a2-4464-9b0b-21c61cff790d';

-- Update Employee Satisfaction Survey
UPDATE templates SET description = 'Đặc điểm: Khảo sát ẩn danh hoàn toàn, không lưu trữ thông tin cá nhân. Tự động trích xuất biểu đồ thống kê kết quả phân bổ trên hệ thống quản trị.
Khảo sát mức độ hài lòng:
- Đánh giá môi trường làm việc qua cấu trúc Section (Văn phòng) - Subsection (Tiện ích) - Criterion (Trạm sạc xe điện) để cải thiện đãi ngộ.
- Góp ý ẩn danh hoàn toàn qua Chế độ Survey để tự động trích xuất biểu đồ phân bổ ý kiến mà không lưu danh tính.'
WHERE id = '66d70066-2276-4ff7-bfb0-b4459f43094d';

-- Update Employee Training Quiz
UPDATE templates SET description = 'Đặc điểm: Chấm điểm theo phương pháp Cộng dồn (Accumulation). Hệ thống tự động tính toán tổng tỷ lệ phần trăm (%) điểm tối đa đạt được.
Sát hạch kiến thức nhân sự:
- Cấu trúc bài thi qua cấu trúc Section (Kiến thức sản phẩm) - Subsection (Tính năng) - Criterion (Câu hỏi 1) để đánh giá toàn diện.
- Tính điểm tự động dựa trên câu trả lời đúng qua Chế độ Tích lũy (Đúng câu nào cộng điểm câu đó).'
WHERE id = 'bf5badaa-dbac-406e-9bdd-cf1323ac7686';

-- Update Food Handler Certification
UPDATE templates SET description = 'Đặc điểm: Chấm điểm cộng dồn. Tích hợp cờ Chốt chặn an toàn (CCP) - nếu vi phạm lỗi này, toàn bộ điểm của phần kỹ năng đó sẽ bằng 0.
Thi chứng chỉ hành nghề bếp:
- Sát hạch kỹ năng qua cấu trúc Section (Vệ sinh) - Subsection (Dụng cụ) - Criterion (Khử trùng dao) để đảm bảo an toàn.
- Chốt chặn kiến thức cốt lõi qua Cờ CCP (Sai mục trọng yếu khiến toàn bộ điểm phần đó về 0).'
WHERE id = 'c09c47bb-520d-47a2-bdad-aca73e33dadd';

-- Update Food Safety / HACCP Audit
UPDATE templates SET description = 'Đặc điểm: Áp dụng \u0027Phạt lũy tiến\u0027 (cộng dồn điểm trừ cho các lỗi tái phạm), kết hợp cờ CCP \u0026 RISK đình chỉ ngay lập tức các vi phạm đe dọa an toàn.
Thanh tra ATTP định kỳ:
- Kiểm soát toàn diện khu vực qua cấu trúc Section (Bếp nóng) - Subsection (Khu sơ chế) - Criterion (Nhiệt độ tủ đông) để ngăn chặn rủi ro.
- Chốt chặn sai phạm trọng yếu qua Cờ CCP (Nhiệt độ tủ > 10°C) để đảm bảo an toàn thực phẩm.
- Giám sát các lỗi tái lặp qua Phạt lũy tiến (Thiếu tem nhãn thực phẩm nhiều kỳ liên tiếp).'
WHERE id = 'ccf45f02-e340-421a-a949-5b389d34a180';

-- Update ISO Maturity Assessment
UPDATE templates SET description = 'Đặc điểm: Sử dụng cơ chế Thang kéo (Scale) 1-5 điểm để đánh giá các mức độ hoàn thiện quy trình, thay vì chỉ ghi nhận bằng kết quả Đạt/Không đạt.
Đánh giá năng lực vận hành:
- Đo lường mức độ hoàn thiện qua cấu trúc Section (Quy trình) - Subsection (Sản xuất) - Criterion (Bảo trì dự phòng) để tối ưu công suất.
- Chấm điểm chi tiết qua Thang kéo (Scale 1-5) thay vì chỉ Đạt/Rớt để tìm cơ hội cải tiến quy trình.'
WHERE id = 'f3a5671f-3e1c-495f-ab3b-f8d362c45ac9';

-- Update Mystery Shopper Evaluation
UPDATE templates SET description = 'Đặc điểm: Khảo sát không tính điểm rớt hạng. Hệ thống phân bổ tỷ trọng điểm theo từng nhóm dịch vụ (Không gian 25%, Phục vụ 40%), có ô nhập số để ghi nhận số lần vi phạm.
Đánh giá khách hàng bí mật:
- Phân bổ trọng tâm qua cấu trúc Section (Không gian) - Subsection (Vệ sinh) - Criterion (Sàn nhà sạch sẽ) để kiểm soát chất lượng.
- Ưu tiên điểm cho nhóm dịch vụ quan trọng qua Trọng số (Nhóm Phục vụ nhân viên nhân hệ số 1.5).'
WHERE id = '9929dfc4-b128-4132-85f2-1cab272f89bb';

-- Update Post-Training Feedback
UPDATE templates SET description = 'Đặc điểm: Nhóm Khảo sát (SURVEY). Định dạng trắc nghiệm lấy ý kiến nhanh, hoàn toàn không tính điểm Đúng/Sai.
Lấy ý kiến sau đào tạo:
- Phản hồi chất lượng qua cấu trúc Section (Giảng viên) - Subsection (Phương pháp) - Criterion (Tương tác) để nâng cao hiệu quả.
- Ghi nhận nhanh ý kiến đóng góp qua Chế độ Survey (Hoàn toàn không tính điểm Đúng/Sai).'
WHERE id = '31bb3c67-a237-498a-97ed-f18d76d03cf4';

-- Update Pre-Flight Aircraft Checklist
UPDATE templates SET description = 'Đặc điểm: 100% tiêu chí áp dụng cờ RISK. Hệ thống tự động cảnh báo và đình chỉ phương tiện không cho hoạt động nếu có bất kỳ hạng mục nào gặp lỗi.
Kiểm tra an toàn bay:
- Rà soát kỹ thuật qua cấu trúc Section (Thân vỏ) - Subsection (Động cơ) - Criterion (Rò rỉ nhiên liệu) để đảm bảo tuyệt đối.
- Đình chỉ hoạt động ngay lập tức qua Cờ RISK (Mọi hạng mục bị lỗi đều tự động cảnh báo cấm bay).'
WHERE id = 'f8fb24f7-1353-4942-97e9-be35497da81a';

-- Update Safety Equipment Verification
UPDATE templates SET description = 'Đặc điểm: Tích hợp cờ Rủi ro (RISK). Hệ thống cảnh báo và chấm 0% toàn bài đánh giá ngay lập tức nếu phát hiện vi phạm nghiêm trọng.
Kiểm tra thiết bị PCCC:
- Tuần tra an toàn qua cấu trúc Section (Tầng hầm) - Subsection (Hệ thống chữa cháy) - Criterion (Áp suất bình) để bảo trì thiết bị.
- Cảnh báo ngay vi phạm nghiêm trọng qua Cờ RISK (Phát hiện bình hết hạn khiến bài đánh giá rớt 0%).'
WHERE id = 'f5e05f0a-c6f8-4049-85f8-cd78bd6a4c76';

-- Update Shift Handover Checklist
UPDATE templates SET description = 'Đặc điểm: Yêu cầu \u0027Xác nhận từng mục\u0027 để đảm bảo tính chính xác, không thể bỏ qua, hỗ trợ nhập số liệu đo lường thực tế.
Bàn giao ca làm việc:
- Đối soát tài sản qua cấu trúc Section (Két sắt) - Subsection (Tiền mặt) - Criterion (Số dư cuối ca) để minh bạch tài chính.
- Xác nhận chặt chẽ từng mục qua Xác nhận bắt buộc (Phải nhập số liệu thực tế mới có thể hoàn tất).'
WHERE id = '23312894-1950-4560-b824-d0a46eff1c3f';

-- Update Store Condition Audit
UPDATE templates SET description = 'Đặc điểm: Chấm điểm theo phương pháp Trừ lùi (Penalty) từ mốc 100%. Tự động phân bổ tỷ trọng điểm khác nhau cho từng khu vực kiểm tra lớn/nhỏ.
Đánh giá tiêu chuẩn cửa hàng:
- Kiểm tra diện mạo qua cấu trúc Section (Ngoại thất) - Subsection (Bảng hiệu) - Criterion (Đèn led sáng) để duy trì hình ảnh.
- Phân bổ tỷ trọng điểm qua Trọng số (Khu vực trung tâm có mật độ điểm cao hơn các khu phụ).'
WHERE id = '293e338d-e20f-4f43-81c1-759cc8ea00ea';

-- Update Warehouse Inventory Audit
UPDATE templates SET description = 'Đặc điểm: Xây dựng cấu trúc thẩm định 3 tầng (Phân khu \u003e Dãy kệ \u003e Tên hàng). Chấm điểm tích lũy, các mặt hàng giá trị cao sẽ có trọng số điểm lớn hơn.
Kiểm đếm hàng hóa thực tế:
- Định vị kho bãi qua cấu trúc Section (Khu vực) - Subsection (Dãy kệ) - Criterion (Mặt hàng) để bao quát toàn bộ vị trí (Zone A > Rack 1 > Item 001).
- Cộng dồn điểm cho mỗi mặt hàng xác nhận đúng qua Chế độ Tích lũy (Mỗi mặt hàng đúng cộng 1 điểm vào tổng điểm của kệ).
- Nhân hệ số cho các mặt hàng giá trị cao qua Trọng số để tập trung chính xác vào tài sản lớn (Mặt hàng tại Zone A nhân hệ số 3.0 thay vì 1.0).'
WHERE id = '0fb39549-ebd3-4934-98ea-9db19feb7e91';
