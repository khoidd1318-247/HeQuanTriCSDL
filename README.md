# Urban Traffic Pattern Analysis & Congestion Forecasting Using Drone Data

> **Môn học:** Hệ quản trị cơ sở dữ liệu (Database Management Systems)  
> **Đề tài:** Phân tích mô hình giao thông đô thị và dự báo ùn tắc ngắn hạn sử dụng dữ liệu giao thông thu thập bằng UAV  
> **Tên tiếng Anh:** Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting Using Drone-Collected Traffic Data  
> **Hệ quản trị CSDL:** Microsoft SQL Server (T-SQL Engine) — Database hợp nhất: `UAV_TrafficDB`  
> **Nhóm sinh viên thực hiện:** Dương Đình Khôi (Khôi), Trần Tiến Dũng, Thùy Trâm, Võ Thị Tuyết Ngân, Phạm Quốc Huy  

---

## 1. Giới thiệu đề tài

Ùn tắc giao thông đô thị tiếp tục là một trong những thách thức nghiêm trọng nhất đối với các thành phố hiện đại. Dự án khai thác dữ liệu quỹ đạo giao thông độ phân giải cao thu thập từ thiết bị bay không người lái (UAV / Drone — bộ dữ liệu chuẩn quốc tế `inD` và `pNEUMA`) kết hợp với **Hệ quản trị cơ sở dữ liệu Microsoft SQL Server (ngôn ngữ T-SQL)** để xây dựng một nền tảng hoàn chỉnh từ quản lý dữ liệu, phân tích mô hình giao thông, dự báo ùn tắc ngắn hạn (ARIMA & Prophet), trực quan hóa Dashboard cho đến quản lý thực nghiệm và xuất báo cáo kiểm toán tự động.

---

## 2. Cấu trúc thư mục dự án

```text
HeQuanTriCSDL/
│
├── sql/                                      # Mã nguồn 6 Mô-đun (T-SQL + Python) hợp nhất trên CSDL UAV_TrafficDB
│   ├── Module1_Traffic_Dataset_Management/   # Mô-đun 1: Quản lý & Kiểm định chất lượng tập dữ liệu UAV
│   │   ├── 01_schema.sql                     # Khởi tạo CSDL UAV_TrafficDB, bảng DATASETS, RECORDINGS, TRAJECTORIES
│   │   ├── 02_procedures_triggers.sql        # Thủ tục nạp dữ liệu, kiểm định chất lượng & Trigger bảo vệ dữ liệu
│   │   └── src/dataset_manager.py            # Công cụ Python kiểm định chất lượng dữ liệu & trích xuất metadata
│   │
│   ├── Module2_Traffic_Pattern_Analysis/     # Mô-đun 2: Phân tích mô hình giao thông & Điểm nóng ùn tắc
│   │   ├── 01_schema/                        # Các bảng vùng giao thông, khung giờ & kết quả phân tích
│   │   ├── 02_functions/                     # Các hàm T-SQL tính mật độ, tốc độ, lưu lượng & mức độ ùn tắc
│   │   ├── 03_procedures/                    # Các Stored Procedures phân tích theo giờ, loại xe & điểm nóng
│   │   ├── 04_triggers/                      # Các Triggers kiểm tra toàn vẹn dữ liệu quan sát & cảnh báo ùn tắc
│   │   └── tests/                            # Kịch bản kiểm thử tự động và dữ liệu mẫu T-SQL cho Mô-đun 2
│   │
│   ├── Module3_Traffic_Forecasting/          # Mô-đun 3: Dự báo ùn tắc ngắn hạn (ARIMA & Facebook Prophet)
│   │   ├── data_loader.py                    # Tiền xử lý dữ liệu chuỗi thời gian 1 phút / 5 phút / 15 phút
│   │   ├── models.py                         # Huấn luyện mô hình ARIMA, Prophet & đánh giá MAE, RMSE, MAPE
│   │   └── main.py                           # Pipeline chạy thực nghiệm dự báo tự động
│   │
│   ├── Module4_Traffic_Dashboard/            # Mô-đun 4: Bảng điều khiển trực quan hóa (Streamlit Dashboard)
│   │   ├── sql/01_schema_and_programmability.sql # Bảng TrafficObservation, ForecastResult, Hàm, View, Trigger
│   │   └── app.py                            # Ứng dụng Web Dashboard kết nối trực tiếp CSV hoặc SQL Server
│   │
│   ├── Module5_Experiment_Management/        # Mô-đun 5: Quản lý Thực nghiệm & Tái lập kết quả (Reproducibility)
│   │   ├── 01_experiment_schema.sql          # Bảng EXPERIMENTS và FORECAST_RESULTS
│   │   ├── 02_experiment_functions_views.sql # Hàm tính điểm tin cậy, định dạng nhãn & View Leaderboard
│   │   ├── 03_experiment_procedures.sql      # Thủ tục tạo thực nghiệm, lưu metric & so sánh ARIMA vs Prophet
│   │   ├── 04_sample_benchmarks.sql          # Dữ liệu mẫu đối sánh thực nghiệm ARIMA(2,1,2) và Prophet
│   │   └── src/experiment_manager.py         # Tiện ích quản lý cấu hình siêu tham số & đánh giá mô hình
│   │
│   └── Module6_Reporting/                    # Mô-đun 6: Xuất báo cáo tự động & Kiểm toán hệ thống (Audit Trail)
│       ├── 01_reporting_audit_schema.sql     # Bảng SYSTEM_AUDIT_LOG và REPORT_EXPORT_HISTORY
│       ├── 02_audit_triggers.sql             # Triggers tự động ghi nhật ký kiểm toán chống xóa/sửa trái phép
│       ├── 03_reporting_views_procedures.sql # Views báo cáo tổng hợp & Thủ tục sp_ExportExecutiveSummary
│       └── src/report_generator.py           # Công cụ xuất báo cáo tự động ra định dạng PDF, Excel (.xlsx), CSV
│
├── app/                                      # Ứng dụng Quản trị & Phân tích tổng hợp (Master Streamlit App)
│   ├── app.py                                # Giao diện tích hợp toàn bộ 6 mô-đun
│   └── services/db_service.py                # Dịch vụ kết nối SQL Server (có chế độ dự phòng đọc CSV mẫu)
│
├── data/                                     # Dữ liệu mẫu chuẩn hóa dùng chung cho toàn dự án
│   ├── uav_traffic_sample.csv                # Tập dữ liệu 2.100 dòng quỹ đạo UAV mẫu (inD & pNEUMA)
│   └── DATA_DICTIONARY.md                    # Tài liệu đặc tả cấu trúc dữ liệu
│
├── docs/                                     # Tài liệu báo cáo và phân công nhiệm vụ nhóm
│   └── Phan_Chia_Cong_Viec_Nhom.docx         # Bảng phân công công việc chi tiết của 5 thành viên
│
├── tests/                                    # Kịch bản kiểm thử tổng hợp (Database, Giao tác, Hiệu năng)
├── .gitignore                                # Bộ lọc loại bỏ các tệp tin tạm
└── README.md                                 # Tài liệu hướng dẫn cài đặt và chạy dự án
```

---

## 3. Phân công các Mô-đun chức năng

| Mô-đun | Tên Mô-đun | Thành viên phụ trách | Thư mục mã nguồn |
| :--- | :--- | :--- | :--- |
| **Mô-đun 1** | Quản lý tập dữ liệu giao thông (Dataset Management) | **Trần Tiến Dũng** (`dungtt1699@ut.edu.vn`) | `sql/Module1_Traffic_Dataset_Management/` |
| **Mô-đun 2** | Phân tích mô hình giao thông (Traffic Pattern Analysis) | **Phạm Quốc Huy** (`huypq2489@ut.edu.vn`) | `sql/Module2_Traffic_Pattern_Analysis/` |
| **Mô-đun 3** | Dự báo ùn tắc ngắn hạn (Traffic Forecasting) | **Thùy Trâm** (`tramttn6172@ut.edu.vn`) & **Dương Đình Khôi** | `sql/Module3_Traffic_Forecasting/` |
| **Mô-đun 4** | Bảng điều khiển trực quan hóa (Visualization Dashboard) | **Võ Thị Tuyết Ngân** (`nganvtt8989@ut.edu.vn`) | `sql/Module4_Traffic_Dashboard/` |
| **Mô-đun 5** | Quản lý Thực nghiệm & Tái lập (Experiment Management) | **Dương Đình Khôi** (`khoidd1318@ut.edu.vn`) | `sql/Module5_Experiment_Management/` |
| **Mô-đun 6** | Xuất báo cáo & Kiểm toán hệ thống (Reporting & Audit Trail) | **Dương Đình Khôi** (`khoidd1318@ut.edu.vn`) | `sql/Module6_Reporting/` |

---

## 4. Hướng dẫn cài đặt và chạy dự án (Setup & Execution Guide)

### Yêu cầu hệ thống (Prerequisites)
1. **Hệ quản trị CSDL:** Microsoft SQL Server (2019 / 2022 trở lên) và công cụ **SQL Server Management Studio (SSMS)**.
2. **Trình điều khiển kết nối:** `ODBC Driver 17 for SQL Server` hoặc `ODBC Driver 18 for SQL Server`.
3. **Môi trường lập trình:** Python `3.10+` (khuyến nghị `Python 3.11` hoặc `3.12`).

---

### Bước 1: Khởi tạo CSDL `UAV_TrafficDB` trên SQL Server (SSMS)

Toàn bộ 6 mô-đun của dự án đã được đồng bộ hóa để sử dụng chung một Cơ sở dữ liệu duy nhất là **`UAV_TrafficDB`**. Mở **SSMS**, kết nối vào SQL Server (`localhost`) và mở lần lượt các file `.sql` theo thứ tự dưới đây rồi nhấn **`F5` (Execute)**:

1. **Khởi tạo Mô-đun 1 (Tạo Database `UAV_TrafficDB` và bảng gốc):**
   - `sql/Module1_Traffic_Dataset_Management/01_schema.sql`
   - `sql/Module1_Traffic_Dataset_Management/02_procedures_triggers.sql`
2. **Khởi tạo Mô-đun 2 (Bảng phân tích, Hàm, Thủ tục, Trigger & Kiểm thử):**
   - Chạy các file trong `sql/Module2_Traffic_Pattern_Analysis/01_schema/` (`01_create_database.sql` -> `04_create_indexes.sql`)
   - Chạy các file trong `02_functions/`, `03_procedures/`, `04_triggers/`
   - *(Tùy chọn)* Chạy `sql/Module2_Traffic_Pattern_Analysis/tests/01_insert_test_data.sql` và `02_test_cases.sql` để xem kết quả kiểm thử T-SQL.
3. **Khởi tạo Mô-đun 4 (Bảng quan sát & View phục vụ Dashboard):**
   - `sql/Module4_Traffic_Dashboard/sql/01_schema_and_programmability.sql`
4. **Khởi tạo Mô-đun 5 (Bảng thực nghiệm, Hàm, Thủ tục & Dữ liệu Benchmark ARIMA vs Prophet):**
   - `sql/Module5_Experiment_Management/01_experiment_schema.sql`
   - `sql/Module5_Experiment_Management/02_experiment_functions_views.sql`
   - `sql/Module5_Experiment_Management/03_experiment_procedures.sql`
   - `sql/Module5_Experiment_Management/04_sample_benchmarks.sql`
5. **Khởi tạo Mô-đun 6 (Bảng Kiểm toán Audit Trail, Trigger bảo mật & Thủ tục xuất báo cáo):**
   - `sql/Module6_Reporting/01_reporting_audit_schema.sql`
   - `sql/Module6_Reporting/02_audit_triggers.sql`
   - `sql/Module6_Reporting/03_reporting_views_procedures.sql`

---

### Bước 2: Cài đặt thư viện Python

Mở **Windows PowerShell** hoặc **Terminal** tại thư mục gốc của dự án và cài đặt đầy đủ các thư viện cần thiết:

```powershell
python -m pip install pandas numpy scipy statsmodels prophet scikit-learn matplotlib openpyxl reportlab streamlit plotly sqlalchemy pyodbc pytest
```

Hoặc cài đặt trực tiếp từ các tệp `requirements.txt` của từng mô-đun:

```powershell
python -m pip install -r sql/Module1_Traffic_Dataset_Management/requirements.txt
python -m pip install -r sql/Module3_Traffic_Forecasting/requirements.txt
python -m pip install -r sql/Module4_Traffic_Dashboard/requirements.txt
python -m pip install -r sql/Module6_Reporting/requirements.txt
```

---

### Bước 3: Chạy các Mô-đun xử lý dữ liệu, Dự báo & Xuất báo cáo (CLI)

Từ thư mục gốc của dự án, bạn có thể chạy độc lập từng mô-đun bằng các lệnh sau:

#### 1. Chạy Mô-đun 1 — Kiểm định chất lượng dữ liệu & Trích xuất Metadata:
```powershell
python sql/Module1_Traffic_Dataset_Management/src/dataset_manager.py --input data/uav_traffic_sample.csv --dataset-name "inD" --location "Intersection_A"
```
> Kết quả sẽ sinh ra báo cáo kiểm định chất lượng dữ liệu tại `reports/data_quality_report.json` và `reports/dataset_metadata.json`.

#### 2. Chạy Mô-đun 3 — Huấn luyện mô hình dự báo ngắn hạn (ARIMA & Prophet):
```powershell
cd sql/Module3_Traffic_Forecasting
python main.py
cd ../..
```
> Chương trình tự động nạp dữ liệu từ `data/uav_traffic_sample.csv`, tổng hợp theo khung thời gian, huấn luyện mô hình ARIMA và Facebook Prophet, in bảng đánh giá sai số (`MAE`, `RMSE`, `MAPE`) và lưu biểu đồ dự báo `forecast_comparison.png`.

#### 3. Chạy Mô-đun 5 — Quản lý cấu hình thực nghiệm & Tái lập kết quả:
```powershell
python sql/Module5_Experiment_Management/src/experiment_manager.py
```
> Xuất tệp cấu hình thực nghiệm chuẩn hóa tại `reports/experiment_manifest.json`.

#### 4. Chạy Mô-đun 6 — Xuất báo cáo tổng hợp tự động (Excel `.xlsx` & PDF):
```powershell
python sql/Module6_Reporting/src/report_generator.py
```
> Tự động sinh báo cáo trang tính đa tab tại `reports/Traffic_Pattern_Report.xlsx` và báo cáo tổng hợp PDF tại `reports/Traffic_Analytics_Executive_Summary.pdf`.

#### 5. Chạy bộ Kiểm thử tự động (Unit Tests):
```powershell
python -m pytest sql/Module1_Traffic_Dataset_Management/tests sql/Module5_Experiment_Management/tests sql/Module6_Reporting/tests
```

---

### Bước 4: Khởi chạy Giao diện Web Dashboard (Streamlit)

Dự án cung cấp **2 giao diện Web Dashboard** trực quan:

#### Cách 1: Chạy Dashboard chuyên biệt của Mô-đun 4 (`sql/Module4_Traffic_Dashboard/app.py`)
```powershell
streamlit run sql/Module4_Traffic_Dashboard/app.py
```
Sau khi trình duyệt mở địa chỉ `http://localhost:8501`, ở thanh công cụ bên trái (**Nguồn dữ liệu**), bạn có thể chọn 1 trong 2 chế độ:
- **Tải CSV chuẩn hóa:** Nhấn **Upload** và chọn file `data/uav_traffic_sample.csv`.
- **SQL Server:** Giữ nguyên cấu hình mặc định (`Server: localhost`, `Database: UAV_TrafficDB`, `Bảng: dbo.TrafficObservation`, tích chọn `Windows Authentication`) và nhấn **Kết nối và tải dữ liệu**. *(Nếu bảng `dbo.TrafficObservation` đang trống, ứng dụng sẽ tự động nạp 2.100 dòng dữ liệu mẫu từ `data/uav_traffic_sample.csv` vào SQL Server và hiển thị ngay biểu đồ).*

#### Cách 2: Chạy Ứng dụng Quản trị Tổng hợp toàn dự án (`app/app.py`)
```powershell
streamlit run app/app.py
```
> Cung cấp cái nhìn tổng thể xuyên suốt cả 6 mô-đun: Quản lý Dataset, Phân tích Điểm nóng ùn tắc, Dự báo ARIMA/Prophet, Quản lý Thực nghiệm và Nhật ký Kiểm toán Hệ thống.
