-- ===================================================================================
-- ĐỒ ÁN MÔN HỌC: HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU
-- ĐỀ TÀI: Phân tích mô hình giao thông đô thị và dự báo ùn tắc ngắn hạn sử dụng dữ liệu UAV
-- HỆ QUẢN TRỊ: Microsoft SQL Server (Transact-SQL)
-- TÁC GIẢ: Dương Đình Khôi & Nhóm nghiên cứu
-- FILE 02: NẠP DỮ LIỆU MẪU MÔ PHỎNG TẬP DỮ LIỆU UAV (inD & pNEUMA)
-- ===================================================================================

USE UAV_TrafficDB;
GO

SET NOCOUNT ON;

-- 1. NẠP DỮ LIỆU NGƯỜI DÙNG MẪU (USERS)
INSERT INTO dbo.USERS (Username, PasswordHash, FullName, Email, RoleName, IsActive)
VALUES
('admin', 'e10adc3949ba59abbe56e057f20f883e', N'Dương Đình Khôi', 'khoidd1318@ut.edu.vn', 'Administrator', 1),
('researcher01', 'e10adc3949ba59abbe56e057f20f883e', N'Trần Thị Thu Thảo', 'thao.researcher@uav-traffic.edu.vn', 'Researcher', 1),
('analyst01', 'e10adc3949ba59abbe56e057f20f883e', N'Lê Hoàng Phúc', 'phuc.analyst@uav-traffic.edu.vn', 'Analyst', 1),
('student01', 'e10adc3949ba59abbe56e057f20f883e', N'Đặng Minh Đức', 'duc.student@uav-traffic.edu.vn', 'Student', 1);
GO

-- 2. NẠP DỮ LIỆU ĐỢT QUAY DRONE (RECORDINGS)
INSERT INTO dbo.RECORDINGS 
(RecordingID, LocationName, City, RecordingDate, StartTime, EndTime, DroneAltitude_m, FrameRate_Hz, TotalVehicles, DatasetSource)
VALUES
('REC_IND_01', N'Nút giao Hàng Xanh (Mô phỏng inD Roundabout)', N'TP. Hồ Chí Minh', '2026-10-10', '07:00:00', '08:30:00', 85.5, 25.0, 150, 'inD'),
('REC_IND_02', N'Giao lộ Điện Biên Phủ - Đinh Bộ Lĩnh', N'TP. Hồ Chí Minh', '2026-10-10', '08:30:00', '10:00:00', 90.0, 25.0, 185, 'inD'),
('REC_PNEUMA_01', N'Trục đường Võ Thị Sáu (Mô phỏng pNEUMA Corridor)', N'TP. Hồ Chí Minh', '2026-10-11', '17:00:00', '18:30:00', 100.0, 25.0, 210, 'pNEUMA');
GO

-- 3. NẠP DANH MỤC PHƯƠNG TIỆN (VEHICLE_TRACKS) MẪU CHO REC_IND_01
INSERT INTO dbo.VEHICLE_TRACKS
(RecordingID, VehicleID_InRec, VehicleType, FirstAppearance, LastAppearance, AvgSpeed_kmh, TotalDistance_m)
VALUES
('REC_IND_01', 1, N'Ô tô con', '2026-10-10 07:00:05', '2026-10-10 07:00:35', 38.5, 320.5),
('REC_IND_01', 2, N'Xe máy',   '2026-10-10 07:00:10', '2026-10-10 07:00:30', 42.0, 233.0),
('REC_IND_01', 3, N'Xe buýt',  '2026-10-10 07:00:15', '2026-10-10 07:01:05', 22.4, 310.0),
('REC_IND_01', 4, N'Xe tải',   '2026-10-10 07:00:20', '2026-10-10 07:01:00', 25.1, 280.0),
('REC_IND_01', 5, N'Xe máy',   '2026-10-10 07:00:25', '2026-10-10 07:00:50', 35.8, 248.0),
('REC_IND_01', 6, N'Ô tô con', '2026-10-10 07:01:00', '2026-10-10 07:01:40', 32.0, 355.0),
('REC_IND_01', 7, N'Xe máy',   '2026-10-10 07:01:10', '2026-10-10 07:01:30', 45.2, 250.0),
('REC_IND_01', 8, N'Ô tô con', '2026-10-10 07:01:15', '2026-10-10 07:01:50', 28.6, 278.0);
GO

-- 4. NẠP TỌA ĐỘ VÀ QUỸ ĐẠO KHUNG HÌNH (TRAJECTORY_FRAMES)
-- Mô phỏng tọa độ không gian (Local X, Y theo mét) của xe TrackID = 1 và 2 di chuyển qua giao lộ
INSERT INTO dbo.TRAJECTORY_FRAMES 
(TrackID, FrameTimestamp, CoordinateX_m, CoordinateY_m, Speed_kmh, Heading_deg, Acceleration_ms2)
VALUES
-- Quỹ đạo Xe 1 (Ô tô con di chuyển từ Tây sang Đông)
(1, '2026-10-10 07:00:05', 10.0, 50.2, 35.0, 90.0, 0.5),
(1, '2026-10-10 07:00:10', 45.2, 50.8, 38.2, 90.5, 0.2),
(1, '2026-10-10 07:00:15', 82.5, 51.5, 40.0, 89.8, -0.1),
(1, '2026-10-10 07:00:20', 121.0, 52.0, 39.5, 90.0, 0.0),
(1, '2026-10-10 07:00:25', 159.8, 52.3, 38.0, 90.2, -0.3),
(1, '2026-10-10 07:00:30', 198.0, 52.5, 36.5, 90.0, -0.2),
(1, '2026-10-10 07:00:35', 235.0, 52.8, 35.0, 90.0, 0.0),

-- Quỹ đạo Xe 2 (Xe máy)
(2, '2026-10-10 07:00:10', 12.0, 45.0, 40.0, 90.0, 0.8),
(2, '2026-10-10 07:00:15', 52.0, 45.5, 43.5, 89.5, 0.4),
(2, '2026-10-10 07:00:20', 95.0, 46.0, 44.0, 90.0, 0.1),
(2, '2026-10-10 07:00:25', 138.0, 46.2, 42.5, 90.2, -0.3),
(2, '2026-10-10 07:00:30', 180.0, 46.5, 41.0, 90.0, -0.2);
GO

-- 5. NẠP CHUỖI THỜI GIAN GOM CỤM (TRAFFIC_TIME_SERIES) - Khung 5 phút cho REC_IND_01
-- Đây là bảng chuỗi thời gian nòng cốt để huấn luyện và đánh giá mô hình dự báo
INSERT INTO dbo.TRAFFIC_TIME_SERIES
(RecordingID, WindowTimestamp, AggregationWindow, VehicleCount, Flow_veh_per_h, Density_veh_per_km, AvgSpeed_kmh, CongestionLevel)
VALUES
('REC_IND_01', '2026-10-10 07:00:00', '5min', 32, 384.0, 25.6, 42.5, N'Thông thoáng'),
('REC_IND_01', '2026-10-10 07:05:00', '5min', 45, 540.0, 36.0, 38.2, N'Bình thường'),
('REC_IND_01', '2026-10-10 07:10:00', '5min', 58, 696.0, 46.4, 34.0, N'Bình thường'),
('REC_IND_01', '2026-10-10 07:15:00', '5min', 75, 900.0, 60.0, 27.5, N'Đông đúc'),
('REC_IND_01', '2026-10-10 07:20:00', '5min', 92, 1104.0, 73.6, 21.0, N'Đông đúc'),
('REC_IND_01', '2026-10-10 07:25:00', '5min', 115, 1380.0, 92.0, 14.5, N'Ùn tắc nghiêm trọng'),
('REC_IND_01', '2026-10-10 07:30:00', '5min', 128, 1536.0, 102.4, 11.2, N'Ùn tắc nghiêm trọng'),
('REC_IND_01', '2026-10-10 07:35:00', '5min', 135, 1620.0, 108.0, 9.8,  N'Ùn tắc nghiêm trọng'),
('REC_IND_01', '2026-10-10 07:40:00', '5min', 120, 1440.0, 96.0, 12.0, N'Ùn tắc nghiêm trọng'),
('REC_IND_01', '2026-10-10 07:45:00', '5min', 105, 1260.0, 84.0, 16.5, N'Đông đúc'),
('REC_IND_01', '2026-10-10 07:50:00', '5min', 88, 1056.0, 70.4, 22.0, N'Đông đúc'),
('REC_IND_01', '2026-10-10 07:55:00', '5min', 65, 780.0, 52.0, 29.0, N'Bình thường'),
('REC_IND_01', '2026-10-10 08:00:00', '5min', 48, 576.0, 38.4, 36.5, N'Bình thường'),
('REC_IND_01', '2026-10-10 08:05:00', '5min', 35, 420.0, 28.0, 41.0, N'Thông thoáng');
GO

-- 6. NẠP DỮ LIỆU THỰC NGHIỆM DỰ BÁO (EXPERIMENTS)
INSERT INTO dbo.EXPERIMENTS
(ExperimentName, RecordingID, ModelAlgorithm, AggregationWindow, TrainTestRatio, Hyperparameters, RandomSeed, ExecutionStatus)
VALUES
(N'Thực nghiệm 01: Dự báo ngắn hạn bằng ARIMA(2,1,2)', 'REC_IND_01', 'ARIMA', '5min', 0.80, 'p=2, d=1, q=2, trend=c', 42, 'Completed'),
(N'Thực nghiệm 02: Dự báo ngắn hạn bằng Facebook Prophet', 'REC_IND_01', 'Prophet', '5min', 0.80, 'seasonality_mode=multiplicative, changepoint_prior=0.05', 42, 'Completed');
GO

-- 7. NẠP KẾT QUẢ DỰ BÁO ĐỐI SOÁT (FORECAST_RESULTS)
-- Đối chiếu kết quả dự báo 5 bước thời gian tiếp theo (khung giờ 07:45 - 08:05)
-- Model 1: ARIMA
INSERT INTO dbo.FORECAST_RESULTS
(ExperimentID, ForecastTime, ActualDensity, PredictedDensity, AbsoluteError, PercentageError)
VALUES
(1, '2026-10-10 07:45:00', 84.0, 86.5, 2.5, 2.98),
(1, '2026-10-10 07:50:00', 70.4, 73.2, 2.8, 3.98),
(1, '2026-10-10 07:55:00', 52.0, 55.4, 3.4, 6.54),
(1, '2026-10-10 08:00:00', 38.4, 41.0, 2.6, 6.77),
(1, '2026-10-10 08:05:00', 28.0, 30.5, 2.5, 8.93);

-- Model 2: Prophet
INSERT INTO dbo.FORECAST_RESULTS
(ExperimentID, ForecastTime, ActualDensity, PredictedDensity, AbsoluteError, PercentageError)
VALUES
(2, '2026-10-10 07:45:00', 84.0, 85.1, 1.1, 1.31),
(2, '2026-10-10 07:50:00', 70.4, 71.8, 1.4, 1.99),
(2, '2026-10-10 07:55:00', 52.0, 53.6, 1.6, 3.08),
(2, '2026-10-10 08:00:00', 38.4, 39.8, 1.4, 3.65),
(2, '2026-10-10 08:05:00', 28.0, 29.5, 1.5, 5.36);
GO

-- 8. NẠP CHỈ SỐ ĐO LƯỜNG HIỆU NĂNG MÔ HÌNH (EXPERIMENT_METRICS)
INSERT INTO dbo.EXPERIMENT_METRICS (ExperimentID, MAE, RMSE, MAPE, R2_Score)
VALUES
(1, 2.7600, 2.7845, 6.24, 0.9412), -- ARIMA metrics
(2, 1.4000, 1.4170, 3.08, 0.9854); -- Prophet metrics
GO

-- 9. GHI AUDIT LOG BAN ĐẦU
INSERT INTO dbo.AUDIT_LOGS (ActionType, TargetTable, RecordKey, Description)
VALUES
('INSERT', 'RECORDINGS', 'REC_IND_01', N'Khởi tạo đợt quay mẫu từ tập dữ liệu inD Roundabout'),
('RUN_FORECAST', 'EXPERIMENTS', 'ExpID=1,2', N'Chạy hoàn tất thực nghiệm so sánh ARIMA vs Prophet trên chuỗi thời gian 5 phút');
GO

PRINT N'==> Đã nạp thành công toàn bộ dữ liệu mẫu cho UAV_TrafficDB!';
GO
