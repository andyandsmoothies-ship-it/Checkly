# Báo Cáo Ảnh Hưởng Hệ Thống: Phân Tích Chi Tiết 3 Phương Án PM

**Ngày**: 28-05-2026 | **ShortID**: c3563378
**Chủ đề**: Phân tích ảnh hưởng mã nguồn & kiến trúc (Thêm / Xóa / Sửa) của 3 Phương án
**Trạng thái**: Tài liệu kỹ thuật tham khảo

---

## 1. Sơ Đồ Tổng Quan Ảnh Hưởng Kiến Trúc

Dưới đây là luồng tác động từ các Phương án (Options) lên 3 tầng của hệ thống Checkly hiện tại (Database, Backend C#, Flutter UI):

```
                       [Phương án Lựa chọn]
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
  [Option 1: Translator]   [Option 2: Golden MVP]  [Option 3: Risk Scorecard]
  - Nặng nhất ở DB         - Thay đổi nhẹ nhất     - Thêm bảng Trọng số (Weight)
  - Quét JSON câu hỏi      - Chia nhóm Archetype   - Tính toán Index động
```

---

## 2. Ảnh Hưởng Chi Tiết Của Từng Phương Án (Add / Remove / Update)

---

### PHƯƠNG ÁN 1: "Universal Translator" (Bộ Dịch Đa Năng - Cấp câu hỏi)

Phương án này có tác động **nặng nhất** đến hiệu năng cơ sở dữ liệu và yêu cầu thay đổi sâu trong thuật toán quét JSON.

```
[Báo cáo Submission] ──► [Quét JSON câu hỏi] ──► [Nhóm theo Tags] ──► [Tính tỷ lệ đạt %]
```

#### 1. Thêm mới (Add):
* **C# Backend**: 
  * Xây dựng dịch vụ `CheckpointTagComplianceCalculator.cs` để bóc tách tệp JSON snapshot của từng bài đánh giá, đếm số câu Pass/Fail theo nhãn danh mục (`CategoryTags`).
* **PostgreSQL Database**:
  * Tạo chỉ mục GIN (GIN Index) trên cột JSONB chứa snapshot của Submission để tăng tốc độ truy vấn nhãn danh mục ở cấp câu hỏi.
* **Flutter UI**:
  * Thêm Widget `AuditTypeSelector` (Thanh chọn loại bài đánh giá: Đánh giá chất lượng / Checklists vận hành / Khảo sát) ở đầu màn hình Dashboard.

#### 2. Xóa bỏ (Remove):
* **C# Backend**:
  * Xóa bỏ cách tính điểm trung bình cộng số học thô (`Average()`) trực tiếp từ bảng `Submissions` trong báo cáo BOD vì cách tính này gây sai lệch toán học khi trộn các mẫu checklist khác nhau.

#### 3. Cập nhật (Update):
* **Nightly Snapshot Worker (`BodReportCalculator.cs`)**:
  * Thay đổi hoàn toàn logic tính toán hàng đêm: thay vì tính điểm trung bình của cửa hàng, phải chuyển sang chạy vòng lặp gom nhóm theo Tag để tính **Tỉ lệ tuân thủ từng Tag**.
* **Flutter DTOs (`bod_analytics_data.dart`)**:
  * Cập nhật lại cấu trúc dữ liệu gửi từ server về để chứa danh sách `% Đạt` của từng Tag (ví dụ: `{"FoodSafety": 85, "Brand": 92}`).

---

### PHƯƠNG ÁN 2: "Golden Output Metrics" (Chỉ Số Đầu Ra Vàng - Cấp báo cáo)

Phương án này có tác động **nhẹ nhất**, tập trung vào việc đơn giản hóa và làm sạch phạm vi của phiên bản MVP.

```
[Báo cáo Submission] ──► [Chỉ lấy cột lớn] ──► [Đo lường Completion & TTR]
```

#### 1. Thêm mới (Add):
* **PostgreSQL & EF Core**:
  * Thêm cột `TemplateArchetype` (Enum: `ScoredAudit`, `TaskCampaign`, `FaultLog`) vào bảng `Templates`.
* **C# Backend**:
  * Thêm trường tính toán `AverageTtr` (Thời gian xử lý lỗi trung bình) và `CompletionRate` (Tỉ lệ hoàn thành) vào bảng lưu trữ Snapshot hàng đêm `BodReports`.

#### 2. Xóa bỏ (Remove):
* **C# Backend & API**:
  * Xóa bỏ/Đóng hoàn toàn 2 tác vụ đang chờ: API lọc theo ngày tùy chỉnh (`date`) và lọc theo mẫu checklist (`template`) để bảo vệ hiệu năng hệ thống.
* **Flutter UI**:
  * Xóa bỏ cử chỉ vuốt chạm nâng cao trên biểu đồ (Tap-to-Filter on Charts) để giảm thiểu độ phức tạp giao diện.

#### 3. Cập nhật (Update):
* **C# Endpoint Handler**:
  * Cập nhật truy vấn SQL trong `BodReportCalculator.cs`: Thêm bộ lọc cứng loại trừ tất cả các templates không thuộc archetype `ScoredAudit` ra khỏi biểu đồ xu hướng điểm số (để tránh làm hỏng điểm trung bình).
* **Flutter Dashboard (`bod_dashboard_body.dart`)**:
  * Cập nhật các thẻ KPI để hiển thị **Thời gian sửa lỗi (TTR)** và **Tỉ lệ hoàn thành** làm trọng tâm, thay vì chỉ hiển thị điểm số phần trăm thô.

---

### PHƯƠNG ÁN 3: "Tag-Weighted Risk Scorecard" (Thẻ Điểm Rủi Ro - Cấp Trọng số)

Phương án này mang lại sự cân bằng, tác động ở mức **trung bình** và tạo ra giá trị doanh nghiệp rất lớn.

```
[Bảng trọng số TagWeight] ──► [Bài kiểm tra] ──► [Nhân Trọng số rủi ro] ──► [Chỉ số DRAI]
```

#### 1. Thêm mới (Add):
* **PostgreSQL Database**:
  * Tạo bảng mới `TagWeights` (Id, TagName, WeightValue) để lưu trữ cấu hình trọng số của công ty.
* **C# Backend & Admin API**:
  * Thêm Endpoint `POST /api/settings/tag-weights` để quản trị viên thiết lập mức độ rủi ro cho từng nhãn danh mục.
  * Thêm dịch vụ `WeightedComplianceCalculator.cs` để tính toán **Chỉ số Rủi ro Động (DRAI)** dựa trên trọng số nhãn.
* **Flutter UI**:
  * Thêm thẻ hiển thị **Chỉ số Rủi Ro Động (DRAI)** trên màn hình tóm tắt của cửa hàng (`Store Executive Summary Sheet`).

#### 2. Xóa bỏ (Remove):
* **C# Backend**:
  * Xóa bỏ các đoạn mã tính điểm trung bình cộng số học không có trọng số trong dịch vụ phân tích báo cáo.

#### 3. Cập nhật (Update):
* **Data Sync Engine (Đồng bộ dữ liệu)**:
  * Cập nhật luồng đồng bộ SQLite trên Flutter để tải bảng cấu hình `TagWeights` về máy local, giúp ứng dụng có thể tính toán chỉ số rủi ro ngay cả khi không có mạng (offline-first).
* **Flutter Store Leaderboard Widget**:
  * Cập nhật bảng xếp hạng cửa hàng: Thay vì xếp hạng theo Điểm số trung bình thô, chuyển sang xếp hạng theo **Chỉ số Rủi ro Động (DRAI)** để đảm bảo tính công bằng giữa các loại checklist khác nhau.

---

## 3. Bảng Tóm Tắt Khối Lượng Công Việc Lập Trình

| Hạng mục ảnh hưởng | Phương án 1 (Translator) | Phương án 2 (Golden MVP) | Phương án 3 (Risk Scorecard) |
| :--- | :--- | :--- | :--- |
| **Database Migration** | 🟡 Trung bình (Thêm index GIN) | 🟢 Rất nhẹ (Thêm cột Enum) | 🟡 Trung bình (Tạo bảng mới) |
| **C# Backend Logic** | 🔴 Nặng (Quét đếm JSON) | 🟢 Rất nhẹ (Tính Average thô) | 🟡 Trung bình (Nhân trọng số) |
| **Flutter UI Changes** | 🟡 Trung bình (Thêm Selector) | 🟢 Rất nhẹ (Sắp xếp lại thẻ KPI) | 🟡 Trung bình (Hiển thị DRAI) |
| **Độ phức tạp SQL** | 🔴 Rất cao (Gom nhóm Tag từ JSON) | 🟢 Thấp (Truy vấn cột phẳng) | 🟡 Trung bình (Liên kết bảng Tag) |
| **Rủi ro kiểm thử (QA)**| 🔴 Cao (Dễ lệch data khi sync) | 🟢 Thấp (Dữ liệu phẳng, dễ test)| 🟡 Trung bình (Cần test cấu hình) |
