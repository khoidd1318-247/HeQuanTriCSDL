-- ===================================================================================
-- Module 6: Reporting & Audit Trail (Export to PDF & Excel)
-- File 01: Table Schema for Generated Reports, Audit Logs, Triggers & Analytical Views
-- Project: Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting
-- Module Lead: Dương Đình Khôi (Khôi)
-- DBMS: Microsoft SQL Server (T-SQL)
-- ===================================================================================

IF DB_ID(N'UAV_TrafficDB') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE UAV_TrafficDB');
END;
GO

USE UAV_TrafficDB;
GO

-- 1. Đảm bảo các bảng cơ sở từ Module 2 & Module 5 đã tồn tại (nếu chạy độc lập Module 6)
IF OBJECT_ID(N'dbo.RoadSegments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RoadSegments
    (
        RoadSegmentID VARCHAR(20) NOT NULL CONSTRAINT PK_RoadSegments PRIMARY KEY,
        RoadSegmentName NVARCHAR(100) NOT NULL,
        SegmentLengthKm DECIMAL(8,3) NULL CONSTRAINT CK_RoadSegments_Length CHECK (SegmentLengthKm IS NULL OR SegmentLengthKm > 0)
    );
END;
GO

IF OBJECT_ID(N'dbo.TrafficRecords', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TrafficRecords
    (
        RecordID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TrafficRecords PRIMARY KEY,
        DatasetVersionID INT NOT NULL,
        VehicleID VARCHAR(30) NOT NULL,
        ObservedAt DATETIME2(0) NOT NULL,
        RoadSegmentID VARCHAR(20) NOT NULL,
        SpeedKmh DECIMAL(6,2) NULL,
        CONSTRAINT FK_TrafficRecords_RoadSegments FOREIGN KEY (RoadSegmentID) REFERENCES dbo.RoadSegments(RoadSegmentID)
    );
END;
GO

IF OBJECT_ID(N'dbo.EXPERIMENTS', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.EXPERIMENTS
    (
        ExperimentID        INT IDENTITY(1,1)   CONSTRAINT PK_Experiments PRIMARY KEY,
        ExperimentName      NVARCHAR(150)       NOT NULL,
        RecordingID         VARCHAR(20)         NOT NULL,
        ModelAlgorithm      VARCHAR(50)         NOT NULL,
        AggregationWindow   VARCHAR(10)         DEFAULT '5min' NOT NULL,
        TrainTestRatio      DECIMAL(3,2)        DEFAULT 0.80 NOT NULL,
        Hyperparameters     NVARCHAR(500),
        RandomSeed          INT                 DEFAULT 42 NOT NULL,
        CreatedBy           VARCHAR(50)         DEFAULT SUSER_SNAME(),
        CreatedAt           DATETIME            DEFAULT GETDATE() NOT NULL,
        ExecutionStatus     VARCHAR(20)         DEFAULT 'Completed',
        Notes               NVARCHAR(500)
    );
END;
GO

IF OBJECT_ID(N'dbo.EXPERIMENT_METRICS', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.EXPERIMENT_METRICS
    (
        ExperimentID        INT                  CONSTRAINT PK_ExpMetrics PRIMARY KEY,
        MAE                 DECIMAL(8,4)         NOT NULL,
        RMSE                DECIMAL(8,4)         NOT NULL,
        MAPE                DECIMAL(6,2)         NOT NULL,
        R2_Score            DECIMAL(6,4),
        EvaluatedAt         DATETIME             DEFAULT GETDATE() NOT NULL,
        CONSTRAINT FK_Metrics_Experiments FOREIGN KEY (ExperimentID) REFERENCES dbo.EXPERIMENTS(ExperimentID) ON DELETE CASCADE
    );
END;
GO

-- 2. Table GENERATED_REPORTS: Quản lý lịch sử và metadata của các báo cáo đã xuất (PDF & Excel)
IF OBJECT_ID(N'dbo.GENERATED_REPORTS', N'U') IS NULL
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
END;
GO

-- 3. Table AUDIT_LOGS: Nhật ký kiểm toán hệ thống (Audit Trail)
IF OBJECT_ID(N'dbo.AUDIT_LOGS', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AUDIT_LOGS
    (
        LogID           BIGINT IDENTITY(1,1) CONSTRAINT PK_AuditLogs PRIMARY KEY,
        LogTime         DATETIME             DEFAULT GETDATE() NOT NULL,
        Username        VARCHAR(50)          DEFAULT SUSER_SNAME(),
        ActionType      VARCHAR(50)          NOT NULL,
        TargetTable     VARCHAR(50),
        RecordKey       VARCHAR(100),
        Description     NVARCHAR(500)        NOT NULL,
        HostName        VARCHAR(100)         DEFAULT HOST_NAME()
    );
END;
GO

-- 4. Trigger: trg_AuditGeneratedReport - Tự động ghi Audit Log khi có báo cáo mới được tạo
CREATE OR ALTER TRIGGER dbo.trg_AuditGeneratedReport
ON dbo.GENERATED_REPORTS
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.AUDIT_LOGS (ActionType, TargetTable, RecordKey, Description)
    SELECT 
        'AUTO_AUDIT_REPORT',
        'GENERATED_REPORTS',
        CAST(i.ReportID AS VARCHAR(20)),
        N'Trigger tự động ghi nhận xuất báo cáo: [' + i.ReportTitle + N'] định dạng ' + i.FileFormat
    FROM inserted i;
END;
GO

-- 5. View: vw_TrafficPatternReport - Tổng hợp lưu lượng, mật độ và vận tốc từ dữ liệu Module 2
CREATE OR ALTER VIEW dbo.vw_TrafficPatternReport
AS
SELECT 
    tr.DatasetVersionID,
    tr.RoadSegmentID,
    rs.RoadSegmentName,
    rs.SegmentLengthKm,
    DATEADD(MINUTE, (DATEDIFF(MINUTE, 0, tr.ObservedAt) / 5) * 5, 0) AS WindowTimestamp,
    COUNT(DISTINCT tr.VehicleID) AS [SoLuongXe],
    CAST(COUNT(DISTINCT tr.VehicleID) * 12.0 AS DECIMAL(8,2)) AS [LuuLuong_xe_gio],
    CAST(COUNT(DISTINCT tr.VehicleID) / NULLIF(ISNULL(rs.SegmentLengthKm, 1.0), 0) AS DECIMAL(8,2)) AS [MatDo_xe_km],
    CAST(AVG(tr.SpeedKmh) AS DECIMAL(6,2)) AS [VanTocTB_kmh],
    CASE 
        WHEN AVG(tr.SpeedKmh) < 15.0 THEN N'Ùn tắc nghiêm trọng'
        WHEN AVG(tr.SpeedKmh) < 25.0 THEN N'Đông đúc / Chậm'
        ELSE N'Thông thoáng'
    END AS [MucDoUnTac]
FROM dbo.TrafficRecords tr
INNER JOIN dbo.RoadSegments rs ON tr.RoadSegmentID = rs.RoadSegmentID
GROUP BY 
    tr.DatasetVersionID,
    tr.RoadSegmentID,
    rs.RoadSegmentName,
    rs.SegmentLengthKm,
    DATEADD(MINUTE, (DATEDIFF(MINUTE, 0, tr.ObservedAt) / 5) * 5, 0);
GO

-- 6. View: vw_ForecastingPerformanceReport - Đối sánh hiệu năng các mô hình dự báo từ Module 5
CREATE OR ALTER VIEW dbo.vw_ForecastingPerformanceReport
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

-- 7. View: vw_CongestionHotspotReport - Tổng hợp các điểm nóng ùn tắc trên các đoạn đường
CREATE OR ALTER VIEW dbo.vw_CongestionHotspotReport
AS
SELECT 
    RoadSegmentID,
    RoadSegmentName,
    WindowTimestamp,
    [SoLuongXe] AS ObservedVehicleCount,
    [VanTocTB_kmh] AS AvgGridSpeed_kmh,
    [MatDo_xe_km] AS Density_veh_per_km,
    [MucDoUnTac] AS CongestionCategory
FROM dbo.vw_TrafficPatternReport
WHERE [VanTocTB_kmh] <= 25.0;
GO
