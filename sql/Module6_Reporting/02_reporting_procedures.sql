-- ===================================================================================
-- Module 6: Reporting & Audit Trail (Export to PDF & Excel)
-- File 02: Stored Procedures for Data Extraction & Report Logging
-- Project: Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting
-- Module Lead: Dương Đình Khôi (Khôi)
-- DBMS: Microsoft SQL Server (T-SQL)
-- ===================================================================================

USE UAV_TrafficDB;
GO

-- 1. SP: sp_GetTrafficReportData - Trích xuất dữ liệu tổng hợp phục vụ xuất báo cáo phân tích giao thông
CREATE OR ALTER PROCEDURE dbo.sp_GetTrafficReportData
    @RoadSegmentID VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Phần 1: Chuỗi thời gian gom cụm 5 phút (Lưu lượng, Mật độ, Vận tốc)
    SELECT 
        DatasetVersionID,
        RoadSegmentID,
        RoadSegmentName,
        WindowTimestamp,
        [SoLuongXe] AS VehicleCount,
        [LuuLuong_xe_gio] AS Flow_veh_per_h,
        [MatDo_xe_km] AS Density_veh_per_km,
        [VanTocTB_kmh] AS AvgSpeed_kmh,
        [MucDoUnTac] AS CongestionLevel
    FROM dbo.vw_TrafficPatternReport
    WHERE (@RoadSegmentID IS NULL OR RoadSegmentID = @RoadSegmentID)
    ORDER BY WindowTimestamp ASC, RoadSegmentID ASC;

    -- Phần 2: Top điểm nóng ùn tắc giao thông
    SELECT TOP 5
        RoadSegmentID,
        RoadSegmentName,
        WindowTimestamp,
        ObservedVehicleCount,
        AvgGridSpeed_kmh,
        Density_veh_per_km,
        CongestionCategory
    FROM dbo.vw_CongestionHotspotReport
    WHERE (@RoadSegmentID IS NULL OR RoadSegmentID = @RoadSegmentID)
    ORDER BY AvgGridSpeed_kmh ASC, ObservedVehicleCount DESC;
END;
GO

-- 2. SP: sp_GetModelComparisonReportData - Trích xuất bảng đối sánh mô hình phục vụ báo cáo hiệu năng
CREATE OR ALTER PROCEDURE dbo.sp_GetModelComparisonReportData
    @RecordingID VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ExperimentID,
        ExperimentName AS [Tên thực nghiệm],
        ModelAlgorithm AS [Mô hình],
        AggregationWindow AS [Cửa sổ],
        TrainTestRatio AS [Tỷ lệ Train],
        Hyperparameters AS [Siêu tham số],
        RandomSeed AS [Seed tái lập],
        MAE AS [Sai số MAE],
        RMSE AS [Sai số RMSE],
        [MAPE_PhanTram] AS [Sai số MAPE (%)],
        R2_Score AS [Hệ số R²],
        [ExecutionTime] AS [Thời gian thực thi]
    FROM dbo.vw_ForecastingPerformanceReport
    WHERE (@RecordingID IS NULL OR RecordingID = @RecordingID)
    ORDER BY RMSE ASC;
END;
GO

-- 3. SP: sp_LogReportExport - Ghi nhận lịch sử xuất báo cáo vào CSDL và Audit Trail
CREATE OR ALTER PROCEDURE dbo.sp_LogReportExport
    @ReportTitle    NVARCHAR(200),
    @ReportType     VARCHAR(50),
    @FileFormat     VARCHAR(10),
    @FilePath       NVARCHAR(500),
    @RecordingID    VARCHAR(20) = NULL,
    @ExperimentID   INT = NULL,
    @FileSizeBytes  BIGINT = 0,
    @SummaryNotes   NVARCHAR(1000) = NULL,
    @NewReportID    INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.GENERATED_REPORTS
        (
            ReportTitle, ReportType, FileFormat, FilePath,
            RecordingID, ExperimentID, GeneratedBy, GeneratedAt, FileSizeBytes, SummaryNotes
        )
        VALUES
        (
            @ReportTitle, @ReportType, @FileFormat, @FilePath,
            @RecordingID, @ExperimentID, SUSER_SNAME(), GETDATE(), @FileSizeBytes, @SummaryNotes
        );

        SET @NewReportID = SCOPE_IDENTITY();

        -- Ghi nhật ký vào AUDIT_LOGS
        INSERT INTO dbo.AUDIT_LOGS (ActionType, TargetTable, RecordKey, Description)
        VALUES ('EXPORT_REPORT', 'GENERATED_REPORTS', CAST(@NewReportID AS VARCHAR(20)),
                N'Xuất thành công báo cáo [' + @ReportTitle + N'] dạng ' + @FileFormat + N' tại đường dẫn: ' + @FilePath);

        COMMIT TRANSACTION;

        SELECT @NewReportID AS ReportID, N'Ghi nhận xuất báo cáo thành công' AS MessageStatus;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH;
END;
GO
