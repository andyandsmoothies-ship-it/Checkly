$task = @"
using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Checkly.Api.Common.Persistence;

var connectionString = \"Host=localhost;Port=5432;Database=checkly;Username=postgres;Password=Aa1234567@\";

var services = new ServiceCollection();
services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

using var serviceProvider = services.BuildServiceProvider();
using var scope = serviceProvider.CreateScope();
var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

async Task UpdateDesc(string id, string desc) {
    var t = await db.Templates.FindAsync(Guid.Parse(id));
    if (t != null) {
        t.Description = desc;
        await db.SaveChangesAsync();
        Console.WriteLine(\"Updated: \" + t.Title);
    }
}

await UpdateDesc(\"67d467eb-ed23-4875-bdff-19f429bd8428\", \"Đặc điểm: Cờ RISK đánh rớt 0% ngay lập tức cho các vi phạm đe dọa an toàn lao động, kết hợp hình thức phạt trừ điểm lũy tiến cho sai phạm lặp lại.\\nKiểm tra an toàn công trường chi tiết:\\n- Định vị khu vực lỗi qua cấu trúc Section (Lô chung cư A) - Subsection (Tầng 15) - Criterion (Dây đai an toàn) để khoanh vùng rủi ro.\\n- Đình chỉ ngay lập tức các vi phạm nghiêm trọng qua Cờ RISK (Lỗi giàn giáo không rào chắn).\\n- Tăng mức phạt cho các lỗi tái phạm nhiều lần qua Phạt lũy tiến (Công nhân không đeo găng tay nhiều lần).\");
await UpdateDesc(\"ac036932-2842-4332-bc28-e662b71777b1\", \"Đặc điểm: Định dạng câu hỏi Nhiều lựa chọn (Multi-Choice) cho phép khách hàng chọn nhiều ý kiến, hoàn toàn không tính điểm phân loại.\\nKhảo sát ý kiến khách hàng:\\n- Thu thập sở thích qua cấu trúc Section (Sản phẩm) - Subsection (Dùng thử) - Criterion (Hương vị) để nắm bắt nhu cầu thực tế.\\n- Ghi nhận đa dạng ý kiến qua Chế độ Survey (Chọn nhiều phương án cùng lúc mà không tính điểm Đạt/Rớt).\");
await UpdateDesc(\"c607b147-f6a2-4464-9b0b-21c61cff790d\", \"Đặc điểm: Chế độ trừ điểm phẳng (Checklist Mode), mỗi mục vi phạm hoặc chưa hoàn thành sẽ bị trừ 1 điểm.\\nKiểm tra chuẩn chuẩn bị đầu ngày:\\n- Rà soát công việc qua cấu trúc Section (Khu vực POS) - Subsection (Thiết bị) - Criterion (Bật máy in bill) để không bỏ sót đầu việc.\\n- Xác nhận hoàn thành từng đầu việc qua Chế độ Checklist (Mỗi mục chưa xong trừ 1 điểm phẳng).\");
await UpdateDesc(\"66d70066-2276-4ff7-bfb0-b4459f43094d\", \"Đặc điểm: Khảo sát ẩn danh hoàn toàn, không lưu trữ thông tin cá nhân. Tự động trích xuất biểu đồ thống kê kết quả phân bổ trên hệ thống quản trị.\\nKhảo sát mức độ hài lòng:\\n- Đánh giá môi trường làm việc qua cấu trúc Section (Văn phòng) - Subsection (Tiện ích) - Criterion (Trạm sạc xe điện) để cải thiện đãi ngộ.\\n- Góp ý ẩn danh hoàn toàn qua Chế độ Survey để tự động trích xuất biểu đồ phân bổ ý kiến mà không lưu danh tính.\");
await UpdateDesc(\"bf5badaa-dbac-406e-9bdd-cf1323ac7686\", \"Đặc điểm: Chấm điểm theo phương pháp Cộng dồn (Accumulation). Hệ thống tự động tính toán tổng tỷ lệ phần trăm (%) điểm tối đa đạt được.\\nSát hạch kiến thức nhân sự:\\n- Cấu trúc bài thi qua cấu trúc Section (Kiến thức sản phẩm) - Subsection (Tính năng) - Criterion (Câu hỏi 1) để đánh giá toàn diện.\\n- Tính điểm tự động dựa trên câu trả lời đúng qua Chế độ Tích lũy (Đúng câu nào cộng điểm câu đó).\");
await UpdateDesc(\"c09c47bb-520d-47a2-bdad-aca73e33dadd\", \"Đặc điểm: Chấm điểm cộng dồn. Tích hợp cờ Chốt chặn an toàn (CCP) - nếu vi phạm lỗi này, toàn bộ điểm của phần kỹ năng đó sẽ bằng 0.\\nThi chứng chỉ hành nghề bếp:\\n- Sát hạch kỹ năng qua cấu trúc Section (Vệ sinh) - Subsection (Dụng cụ) - Criterion (Khử trùng dao) để đảm bảo an toàn.\\n- Chốt chặn kiến thức cốt lõi qua Cờ CCP (Sai mục trọng yếu khiến toàn bộ điểm phần đó về 0).\");
await UpdateDesc(\"ccf45f02-e340-421a-a949-5b389d34a180\", \"Đặc điểm: Áp dụng \u0027Phạt lũy tiến\u0027 (cộng dồn điểm trừ cho các lỗi tái phạm), kết hợp cờ CCP \u0026 RISK đình chỉ ngay lập tức các vi phạm đe dọa an toàn.\\nThanh tra ATTP định kỳ:\\n- Kiểm soát toàn diện khu vực qua cấu trúc Section (Bếp nóng) - Subsection (Khu sơ chế) - Criterion (Nhiệt độ tủ đông) để ngăn chặn rủi ro.\\n- Chốt chặn sai phạm trọng yếu qua Cờ CCP (Nhiệt độ tủ > 10°C) để đảm bảo an toàn thực phẩm.\\n- Giám sát các lỗi tái lặp qua Phạt lũy tiến (Thiếu tem nhãn thực phẩm nhiều kỳ liên tiếp).\");
await UpdateDesc(\"f3a5671f-3e1c-495f-ab3b-f8d362c45ac9\", \"Đặc điểm: Sử dụng cơ chế Thang kéo (Scale) 1-5 điểm để đánh giá các mức độ hoàn thiện quy trình, thay vì chỉ ghi nhận bằng kết quả Đạt/Không đạt.\\nĐánh giá năng lực vận hành:\\n- Đo lường mức độ hoàn thiện qua cấu trúc Section (Quy trình) - Subsection (Sản xuất) - Criterion (Bảo trì dự phòng) để tối ưu công suất.\\n- Chấm điểm chi tiết qua Thang kéo (Scale 1-5) thay vì chỉ Đạt/Rớt để tìm cơ hội cải tiến quy trình.\");
await UpdateDesc(\"9929dfc4-b128-4132-85f2-1cab272f89bb\", \"Đặc điểm: Khảo sát không tính điểm rớt hạng. Hệ thống phân bổ tỷ trọng điểm theo từng nhóm dịch vụ (Không gian 25%, Phục vụ 40%), có ô nhập số để ghi nhận số lần vi phạm.\\nĐánh giá khách hàng bí mật:\\n- Phân bổ trọng tâm qua cấu trúc Section (Không gian) - Subsection (Vệ sinh) - Criterion (Sàn nhà sạch sẽ) để kiểm soát chất lượng.\\n- Ưu tiên điểm cho nhóm dịch vụ quan trọng qua Trọng số (Nhóm Phục vụ nhân viên nhân hệ số 1.5).\");
await UpdateDesc(\"31bb3c67-a237-498a-97ed-f18d76d03cf4\", \"Đặc điểm: Nhóm Khảo sát (SURVEY). Định dạng trắc nghiệm lấy ý kiến nhanh, hoàn toàn không tính điểm Đúng/Sai.\\nLấy ý kiến sau đào tạo:\\n- Phản hồi chất lượng qua cấu trúc Section (Giảng viên) - Subsection (Phương pháp) - Criterion (Tương tác) để nâng cao hiệu quả.\\n- Ghi nhận nhanh ý kiến đóng góp qua Chế độ Survey (Hoàn toàn không tính điểm Đúng/Sai).\");
await UpdateDesc(\"f8fb24f7-1353-4942-97e9-be35497da81a\", \"Đặc điểm: 100% tiêu chí áp dụng cờ RISK. Hệ thống tự động cảnh báo và đình chỉ phương tiện không cho hoạt động nếu có bất kỳ hạng mục nào gặp lỗi.\\nKiểm tra an toàn bay:\\n- Rà soát kỹ thuật qua cấu trúc Section (Thân vỏ) - Subsection (Động cơ) - Criterion (Rò rỉ nhiên liệu) để đảm bảo tuyệt đối.\\n- Đình chỉ hoạt động ngay lập tức qua Cờ RISK (Mọi hạng mục bị lỗi đều tự động cảnh báo cấm bay).\");
await UpdateDesc(\"f5e05f0a-c6f8-4049-85f8-cd78bd6a4c76\", \"Đặc điểm: Tích hợp cờ Rủi ro (RISK). Hệ thống cảnh báo và chấm 0% toàn bài đánh giá ngay lập tức nếu phát hiện vi phạm nghiêm trọng.\\nKiểm tra thiết bị PCCC:\\n- Tuần tra an toàn qua cấu trúc Section (Tầng hầm) - Subsection (Hệ thống chữa cháy) - Criterion (Áp suất bình) để bảo trì thiết bị.\\n- Cảnh báo ngay vi phạm nghiêm trọng qua Cờ RISK (Phát hiện bình hết hạn khiến bài đánh giá rớt 0%).\");
await UpdateDesc(\"23312894-1950-4560-b824-d0a46eff1c3f\", \"Đặc điểm: Yêu cầu \u0027Xác nhận từng mục\u0027 để đảm bảo tính chính xác, không thể bỏ qua, hỗ trợ nhập số liệu đo lường thực tế.\\nBàn giao ca làm việc:\\n- Đối soát tài sản qua cấu trúc Section (Két sắt) - Subsection (Tiền mặt) - Criterion (Số dư cuối ca) để minh bạch tài chính.\\n- Xác nhận chặt chẽ từng mục qua Xác nhận bắt buộc (Phải nhập số liệu thực tế mới có thể hoàn tất).\");
await UpdateDesc(\"293e338d-e20f-4f43-81c1-759cc8ea00ea\", \"Đặc điểm: Chấm điểm theo phương pháp Trừ lùi (Penalty) từ mốc 100%. Tự động phân bổ tỷ trọng điểm khác nhau cho từng khu vực kiểm tra lớn/nhỏ.\\nĐánh giá tiêu chuẩn cửa hàng:\\n- Kiểm tra diện mạo qua cấu trúc Section (Ngoại thất) - Subsection (Bảng hiệu) - Criterion (Đèn led sáng) để duy trì hình ảnh.\\n- Phân bổ tỷ trọng điểm qua Trọng số (Khu vực trung tâm có mật độ điểm cao hơn các khu phụ).\");
await UpdateDesc(\"0fb39549-ebd3-4934-98ea-9db19feb7e91\", \"Đặc điểm: Xây dựng cấu trúc thẩm định 3 tầng (Phân khu \u003e Dãy kệ \u003e Tên hàng). Chấm điểm tích lũy, các mặt hàng giá trị cao sẽ có trọng số điểm lớn hơn.\\nKiểm đếm hàng hóa thực tế:\\n- Định vị kho bãi qua cấu trúc Section (Khu vực) - Subsection (Dãy kệ) - Criterion (Mặt hàng) để bao quát toàn bộ vị trí (Zone A > Rack 1 > Item 001).\\n- Cộng dồn điểm cho mỗi mặt hàng xác nhận đúng qua Chế độ Tích lũy (Mỗi mặt hàng đúng cộng 1 điểm vào tổng điểm của kệ).\\n- Nhân hệ số cho các mặt hàng giá trị cao qua Trọng số để tập trung chính xác vào tài sản lớn (Mặt hàng tại Zone A nhân hệ số 3.0 thay vì 1.0).\");
"@

# 1. Create console project
dotnet new console -n DbUpdater --force
cd DbUpdater
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add reference ../../Checkly.Api.csproj

# 2. Write Program.cs
$task | Out-File -FilePath Program.cs -Encoding utf8

# 3. Run it
dotnet run
