-- ===================================================================================
-- Module 6: Reporting (Export to PDF & Excel)
-- File 02: Stored Procedures for Data Extraction & Report Logging
-- Project: Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting
-- DBMS: Microsoft SQL Server (T-SQL)
-- ===================================================================================

USE UAV_TrafficDB;
GO

-- 1. SP: sp_GetTrafficReportData - Trích xuất dữ liệu tổng hợp phục vụ xuất báo cáo phân tích giao thông
IF OBJECT_ID('dbo.sp_GetTrafficReportData', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetTrafficReportData;
GO
CREATE PROCEDURE dbo.sp_GetTrafficReportData
    @RecordingID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Phần 1: Thông tin tổng quan đợt bay
    SELECT 
        RecordingID,
        LocationName,
        City,
        RecordingDate,
        StartTime,
        EndTime,
        DroneAltitude_m,
        FrameRate_Hz,
        TotalVehicles,
        DatasetSource
    FROM dbo.RECORDINGS
    WHERE RecordingID = @RecordingID;

    -- Phần 2: Chuỗi thời gian gom cụm
    SELECT 
        WindowTimestamp,
        AggregationWindow,
        VehicleCount,
        Flow_veh_per_h,
        Density_veh_per_km,
        AvgSpeed_kmh,
        CongestionLevel
    FROM dbo.TRAFFIC_TIME_SERIES
    WHERE RecordingID = @RecordingID
    ORDER BY WindowTimestamp ASC;

    -- Phần 3: Top 5 điểm nóng ùn tắc không gian
    SELECT TOP 5
        Spatial_Grid_X,
        Spatial_Grid_Y,
        TrajectoryPointsCount,
        AvgGridSpeed_kmh,
        CongestionCategory
    FROM dbo.vw_CongestionHotspotReport
    WHERE RecordingID = @RecordingID
    ORDER BY TrajectoryPointsCount DESC;
END;
GO

-- 2. SP: sp_GetModelComparisonReportData - Trích xuất bảng đối sánh mô hình phục vụ báo cáo hiệu năng
IF OBJECT_ID('dbo.sp_GetModelComparisonReportData', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetModelComparisonReportData;
GO
CREATE PROCEDURE dbo.sp_GetModelComparisonReportData
    @RecordingID VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        E.ExperimentID,
        E.ExperimentName AS [Tên thực nghiệm],
        E.ModelAlgorithm AS [Mô hình],
        E.AggregationWindow AS [Cửa sổ],
        E.TrainTestRatio AS [Tỷ lệ Train],
        E.Hyperparameters AS [Siêu tham số],
        E.RandomSeed AS [Seed tái lập],
        M.MAE AS [Sai số MAE],
        M.RMSE AS [Sai số RMSE],
        M.MAPE AS [Sai số MAPE (%)],
        M.R2_Score AS [Hệ số R²],
        E.CreatedAt AS [Thời gian thực thi]
    FROM dbo.EXPERIMENTS E
    LEFT JOIN dbo.EXPERIMENT_METRICS M ON E.ExperimentID = M.ExperimentID
    WHERE (@RecordingID IS NULL OR E.RecordingID = @RecordingID)
    ORDER BY M.RMSE ASC;
END;
GO

-- 3. SP: sp_LogReportExport - Ghi nhận lịch sử xuất báo cáo vào CSDL và Audit Trail
IF OBJECT_ID('dbo.sp_LogReportExport', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_LogReportExport;
GO
CREATE PROCEDURE dbo.sp_LogReportExport
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
