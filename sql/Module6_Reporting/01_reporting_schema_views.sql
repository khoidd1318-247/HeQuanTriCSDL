-- ===================================================================================
-- Module 6: Reporting (Export to PDF & Excel)
-- File 01: Table Schema for Generated Reports & Analytical Views
-- Project: Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting
-- DBMS: Microsoft SQL Server (T-SQL)
-- ===================================================================================

USE UAV_TrafficDB;
GO

-- 1. Table GENERATED_REPORTS: Quản lý lịch sử và metadata của các báo cáo đã xuất
IF OBJECT_ID('dbo.GENERATED_REPORTS', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.GENERATED_REPORTS
    (
        ReportID            INT IDENTITY(1,1)   CONSTRAINT PK_GeneratedReports PRIMARY KEY,
        ReportTitle         NVARCHAR(200)       NOT NULL,
        ReportType          VARCHAR(50)         NOT NULL
                            CONSTRAINT CK_Report_Type CHECK (ReportType IN ('TrafficPattern', 'Forecasting', 'ModelPerformance', 'ExecutiveSummary')),
        FileFormat          VARCHAR(10)         NOT NULL
                            CONSTRAINT CK_Report_Format CHECK (FileFormat IN ('PDF', 'Excel', 'CSV', 'JSON')),
        FilePath            NVARCHAR(500)       NOT NULL,
        RecordingID         VARCHAR(20),
        ExperimentID        INT,
        GeneratedBy         VARCHAR(50)         DEFAULT SUSER_SNAME(),
        GeneratedAt         DATETIME            DEFAULT GETDATE() NOT NULL,
        FileSizeBytes       BIGINT              DEFAULT 0,
        SummaryNotes        NVARCHAR(1000)
    );
END
GO

-- 2. View: vw_TrafficPatternReport - Tổng hợp chuỗi thời gian phân tích lưu lượng và mật độ
IF OBJECT_ID('dbo.vw_TrafficPatternReport', 'V') IS NOT NULL DROP VIEW dbo.vw_TrafficPatternReport;
GO
CREATE VIEW dbo.vw_TrafficPatternReport
AS
SELECT 
    TS.RecordingID,
    R.LocationName,
    R.RecordingDate,
    TS.WindowTimestamp,
    TS.AggregationWindow,
    TS.VehicleCount AS [SoLuongXe],
    TS.Flow_veh_per_h AS [LuuLuong_xe_gio],
    TS.Density_veh_per_km AS [MatDo_xe_km],
    TS.AvgSpeed_kmh AS [VanTocTB_kmh],
    TS.CongestionLevel AS [MucDoUnTac]
FROM dbo.TRAFFIC_TIME_SERIES TS
LEFT JOIN dbo.RECORDINGS R ON TS.RecordingID = R.RecordingID;
GO

-- 3. View: vw_ForecastingPerformanceReport - Tổng hợp kết quả đối sánh hiệu năng các mô hình dự báo
IF OBJECT_ID('dbo.vw_ForecastingPerformanceReport', 'V') IS NOT NULL DROP VIEW dbo.vw_ForecastingPerformanceReport;
GO
CREATE VIEW dbo.vw_ForecastingPerformanceReport
AS
SELECT 
    E.ExperimentID,
    E.ExperimentName,
    E.RecordingID,
    E.ModelAlgorithm,
    E.AggregationWindow,
    E.TrainTestRatio,
    E.Hyperparameters,
    E.RandomSeed,
    M.MAE,
    M.RMSE,
    M.MAPE AS [MAPE_PhanTram],
    M.R2_Score,
    E.CreatedAt AS [ExecutionTime]
FROM dbo.EXPERIMENTS E
LEFT JOIN dbo.EXPERIMENT_METRICS M ON E.ExperimentID = M.ExperimentID;
GO

-- 4. View: vw_CongestionHotspotReport - Tổng hợp các điểm nóng ùn tắc không gian lưới 20m x 20m
IF OBJECT_ID('dbo.vw_CongestionHotspotReport', 'V') IS NOT NULL DROP VIEW dbo.vw_CongestionHotspotReport;
GO
CREATE VIEW dbo.vw_CongestionHotspotReport
AS
SELECT 
    T.RecordingID,
    CAST(FLOOR(F.CoordinateX_m / 20.0) * 20.0 AS VARCHAR(10)) + 'm - ' + 
    CAST(FLOOR(F.CoordinateX_m / 20.0) * 20.0 + 20.0 AS VARCHAR(10)) + 'm' AS [Spatial_Grid_X],
    CAST(FLOOR(F.CoordinateY_m / 20.0) * 20.0 AS VARCHAR(10)) + 'm - ' + 
    CAST(FLOOR(F.CoordinateY_m / 20.0) * 20.0 + 20.0 AS VARCHAR(10)) + 'm' AS [Spatial_Grid_Y],
    COUNT(F.FrameID) AS [TrajectoryPointsCount],
    CAST(AVG(F.Speed_kmh) AS DECIMAL(6,2)) AS [AvgGridSpeed_kmh],
    CASE 
        WHEN AVG(F.Speed_kmh) < 15.0 THEN N'HOTSPOT (Ùn tắc nghiêm trọng)'
        WHEN AVG(F.Speed_kmh) < 25.0 THEN N'SLOW (Di chuyển chậm)'
        ELSE N'NORMAL (Bình thường)'
    END AS [CongestionCategory]
FROM dbo.TRAJECTORY_FRAMES F
JOIN dbo.VEHICLE_TRACKS T ON F.TrackID = T.TrackID
GROUP BY T.RecordingID, FLOOR(F.CoordinateX_m / 20.0), FLOOR(F.CoordinateY_m / 20.0);
GO
