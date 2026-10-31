# Urban Traffic Pattern Analysis & Congestion Forecasting Using Drone Data

> **Môn học:** Hệ quản trị cơ sở dữ liệu (Database Management Systems)  
> **Đề tài:** Phân tích mô hình giao thông đô thị và dự báo ùn tắc ngắn hạn sử dụng dữ liệu giao thông thu thập bằng UAV  
> **Tên tiếng Anh:** Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting Using Drone-Collected Traffic Data  
> **Hệ quản trị CSDL:** Microsoft SQL Server (T-SQL Engine) — Database: `UAV_TrafficDB`  

---

## Hướng dẫn cài đặt và chạy dự án (Setup & Execution Guide)

### Yêu cầu hệ thống (Prerequisites)
1. **Hệ quản trị CSDL:** Microsoft SQL Server (2019 / 2022 trở lên) và công cụ **SQL Server Management Studio (SSMS)**.
2. **Trình điều khiển kết nối:** `ODBC Driver 17 for SQL Server` hoặc `ODBC Driver 18 for SQL Server`.
3. **Môi trường lập trình:** Python `3.10+` (khuyến nghị `Python 3.11` hoặc `3.12`).

---

### Bước 1: Khởi tạo CSDL `UAV_TrafficDB` trên SQL Server (SSMS)

Toàn bộ 6 mô-đun của dự án sử dụng chung một Cơ sở dữ liệu duy nhất là **`UAV_TrafficDB`**. Mở **SSMS**, kết nối vào SQL Server (`localhost`) và mở lần lượt các file `.sql` theo thứ tự dưới đây rồi nhấn **`F5` (Execute)**:

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
