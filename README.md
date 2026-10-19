# Urban Traffic Pattern Analysis & Congestion Forecasting Using Drone Data

> **Môn học:** Hệ quản trị cơ sở dữ liệu (Database Management Systems)  
> **Đề tài:** Phân tích mô hình giao thông đô thị và dự báo ùn tắc ngắn hạn sử dụng dữ liệu giao thông thu thập bằng UAV  
> **Tên tiếng Anh:** Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting Using Drone-Collected Traffic Data  
> **Giảng viên hướng dẫn:** Thầy Nguyễn Văn Chiến  
> **Hệ quản trị CSDL:** Microsoft SQL Server (T-SQL Engine)  
> **Nhóm sinh viên thực hiện:** Dương Đình Khôi (Khôi), Trần Tiến Dũng, Thùy Trâm, Võ Thị Tuyết Ngân, Huy  

---

## 1. Giới thiệu đề tài

Ùn tắc giao thông đô thị tiếp tục là một trong những thách thức nghiêm trọng nhất đối với các thành phố hiện đại. Dự án hướng đến việc khai thác dữ liệu quỹ đạo giao thông độ phân giải cao thu thập từ thiết bị bay không người lái (UAV / Drone) kết hợp với sức mạnh của **Hệ quản trị cơ sở dữ liệu Microsoft SQL Server (ngôn ngữ T-SQL)** để xây dựng một nền tảng phân tích quy luật và dự báo ùn tắc ngắn hạn.

---

## 2. Cấu trúc thư mục dự án (Project Skeleton)

```text
HeQuanTriCSDL/
│
├── sql/                          # Toàn bộ mã nguồn T-SQL (CSDL, Bảng, Thủ tục, Hàm, Trigger)
│   ├── migrations/               # Lịch sử thay đổi lược đồ cơ sở dữ liệu
│   └── procedures/               # Các Stored Procedures nghiệp vụ
│
├── app/                          # Mã nguồn ứng dụng giao diện (Application)
│   ├── components/               # Các thành phần giao diện người dùng
│   └── services/                 # Kết nối và gọi các đối tượng CSDL
│
├── data/                         # Thư mục chứa tập dữ liệu mẫu và tài liệu đặc tả schema
│
├── docs/                         # Báo cáo đồ án, đề cương chi tiết, slide thuyết trình
│
├── tests/                        # Kịch bản kiểm thử (Kiểm thử CSDL, Giao tác, Hiệu năng)
│
├── .gitignore                    # Bộ lọc loại bỏ các tệp tin rác và file tạm
└── README.md                     # Tài liệu hướng dẫn tổng quan dự án
```

---

## 3. Các Mô-đun chức năng chính

1. **Mô-đun 1 - Quản lý tập dữ liệu giao thông (Dataset Management):**
   - Quản lý tập dữ liệu quỹ đạo (Import, kiểm định chất lượng, quản lý phiên bản).
2. **Mô-đun 2 - Phân tích mô hình giao thông (Traffic Pattern Analysis):**
   - Phân tích lưu lượng, vận tốc trung bình, mật độ xe, nhận diện điểm nóng ùn tắc không-thời gian.
3. **Mô-đun 3 - Mô-đun Dự báo (Forecasting Module):**
   - Tạo chuỗi thời gian, dự báo ngắn hạn bằng ARIMA và Facebook Prophet, đánh giá sai số.
4. **Mô-đun 4 - Bảng điều khiển trực quan hóa (Visualization Dashboard):**
   - Biểu đồ chuỗi thời gian, bản đồ nhiệt mật độ xe, trực quan hóa kết quả dự báo.
5. **Mô-đun 5 - Quản lý Thực nghiệm (Experiment Management):**
   - Quản lý siêu tham số, đảm bảo tính tái lập thử nghiệm (Reproducibility).
6. **Mô-đun 6 - Báo cáo & Kiểm toán hệ thống (Reporting & Audit Trail):**
   - Xuất báo cáo tổng hợp và theo dõi nhật ký hoạt động an toàn.

---

## 4. Kế hoạch triển khai (Roadmap)

- **Giai đoạn 1:** Phân tích yêu cầu, thiết kế CSDL quan hệ chuẩn hóa.
- **Giai đoạn 2:** Xây dựng các hàm (Functions), thủ tục (Stored Procedures) và Triggers trong T-SQL.
- **Giai đoạn 3:** Xây dựng ứng dụng quản lý dữ liệu (Application) kết nối CSDL.
- **Giai đoạn 4:** Kiểm thử toàn vẹn giao tác (Transactions, Concurrency, Deadlock).
- **Giai đoạn 5:** Hoàn thiện báo cáo, đóng gói sản phẩm và bảo vệ đồ án.
