-- ===================================================================================
-- Module 6: Reporting (Export to PDF & Excel)
-- File 03: Sample Report History Logs
-- Project: Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting
-- DBMS: Microsoft SQL Server (T-SQL)
-- ===================================================================================

USE UAV_TrafficDB;
GO

SET NOCOUNT ON;

-- Nạp các bản ghi mẫu lịch sử xuất báo cáo
IF NOT EXISTS (SELECT 1 FROM dbo.GENERATED_REPORTS WHERE ReportTitle LIKE N'%inD Roundabout%')
BEGIN
    INSERT INTO dbo.GENERATED_REPORTS
    (ReportTitle, ReportType, FileFormat, FilePath, RecordingID, ExperimentID, GeneratedBy, GeneratedAt, FileSizeBytes, SummaryNotes)
    VALUES
    (
        N'Báo cáo Phân tích Mô hình Giao thông - Nút giao inD Roundabout (REC_IND_01)',
        'TrafficPattern',
        'Excel',
        'reports/Traffic_Pattern_Report_REC_IND_01.xlsx',
        'REC_IND_01',
        NULL,
        'admin',
        '2026-10-16 10:15:00',
        45230,
        N'Báo cáo tổng hợp số lượng xe, lưu lượng q, mật độ k và nhận diện 5 điểm nóng ùn tắc.'
    ),
    (
        N'Báo cáo Đánh giá Hiệu năng Mô hình Dự báo (ARIMA vs Facebook Prophet)',
        'ModelPerformance',
        'PDF',
        'reports/Model_Performance_Benchmark_Report.pdf',
        'REC_IND_01',
        1,
        'researcher01',
        '2026-10-16 11:30:00',
        128500,
        N'Đối sánh MAE, RMSE, MAPE và R² Score trên tập dữ liệu chuỗi thời gian 5 phút. Mô hình Prophet đạt kết quả vượt trội (MAPE 3.08%).'
    );
END
GO
