-- ===================================================================================
-- ĐỒ ÁN MÔN HỌC: HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU
-- ĐỀ TÀI: Phân tích mô hình giao thông đô thị và dự báo ùn tắc ngắn hạn sử dụng dữ liệu UAV
-- HỆ QUẢN TRỊ: Microsoft SQL Server (Transact-SQL)
-- TÁC GIẢ: Dương Đình Khôi & Nhóm nghiên cứu
-- FILE 01: TẠO CƠ SỞ DỮ LIỆU, CÁC BẢNG, RÀNG BUỘC VÀ CHỈ MỤC (INDEX)
-- ===================================================================================

USE master;
GO

-- 1. Tạo Database nếu chưa tồn tại
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'UAV_TrafficDB')
BEGIN
    CREATE DATABASE UAV_TrafficDB COLLATE SQL_Latin1_General_CP1_CI_AS;
    PRINT N'==> Khởi tạo CSDL UAV_TrafficDB thành công.';
END
ELSE
BEGIN
    PRINT N'==> CSDL UAV_TrafficDB đã tồn tại.';
END
GO

USE UAV_TrafficDB;
GO

-- ===================================================================================
-- 2. XÓA CÁC BẢNG CŨ NẾU ĐÃ TỒN TẠI
-- ===================================================================================
IF OBJECT_ID('dbo.EXPERIMENT_METRICS', 'U') IS NOT NULL DROP TABLE dbo.EXPERIMENT_METRICS;
IF OBJECT_ID('dbo.FORECAST_RESULTS', 'U') IS NOT NULL DROP TABLE dbo.FORECAST_RESULTS;
IF OBJECT_ID('dbo.EXPERIMENTS', 'U') IS NOT NULL DROP TABLE dbo.EXPERIMENTS;
IF OBJECT_ID('dbo.TRAFFIC_TIME_SERIES', 'U') IS NOT NULL DROP TABLE dbo.TRAFFIC_TIME_SERIES;
IF OBJECT_ID('dbo.TRAJECTORY_FRAMES', 'U') IS NOT NULL DROP TABLE dbo.TRAJECTORY_FRAMES;
IF OBJECT_ID('dbo.VEHICLE_TRACKS', 'U') IS NOT NULL DROP TABLE dbo.VEHICLE_TRACKS;
IF OBJECT_ID('dbo.RECORDINGS', 'U') IS NOT NULL DROP TABLE dbo.RECORDINGS;
IF OBJECT_ID('dbo.AUDIT_LOGS', 'U') IS NOT NULL DROP TABLE dbo.AUDIT_LOGS;
IF OBJECT_ID('dbo.USERS', 'U') IS NOT NULL DROP TABLE dbo.USERS;
GO

-- ===================================================================================
-- 3. TẠO CÁC BẢNG QUẢN TRỊ VÀ PHÂN QUYỀN
-- ===================================================================================

-- Bảng 1: USERS (Quản lý người dùng và phân quyền RBAC)
CREATE TABLE dbo.USERS
(
    UserID          INT IDENTITY(1,1)   CONSTRAINT PK_Users PRIMARY KEY,
    Username        VARCHAR(50)         NOT NULL CONSTRAINT UQ_Users_Username UNIQUE,
    PasswordHash    VARCHAR(256)        NOT NULL,
    FullName        NVARCHAR(100)       NOT NULL,
    Email           VARCHAR(100)        CONSTRAINT UQ_Users_Email UNIQUE,
    RoleName        VARCHAR(20)         NOT NULL 
                    CONSTRAINT CK_Users_Role CHECK (RoleName IN ('Administrator', 'Researcher', 'Analyst', 'Student')),
    IsActive        BIT                 DEFAULT 1 NOT NULL,
    CreatedAt       DATETIME            DEFAULT GETDATE() NOT NULL
);
GO

-- Bảng 2: AUDIT_LOGS (Nhật ký hệ thống - Phục vụ Audit Trail môn HQTCSDL)
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
GO

-- ===================================================================================
-- 4. TẠO CÁC BẢNG LƯU TRỮ DỮ LIỆU GIAO THÔNG TỪ UAV (DRONE)
-- ===================================================================================

-- Bảng 3: RECORDINGS (Quản lý các đợt quay drone / Dataset metadata)
CREATE TABLE dbo.RECORDINGS
(
    RecordingID     VARCHAR(20)         CONSTRAINT PK_Recordings PRIMARY KEY,
    LocationName    NVARCHAR(150)       NOT NULL,
    City            NVARCHAR(100)       DEFAULT N'TP. Hồ Chí Minh',
    RecordingDate   DATE                NOT NULL,
    StartTime       TIME                NOT NULL,
    EndTime         TIME                NOT NULL,
    DroneAltitude_m DECIMAL(6,2)        CONSTRAINT CK_Recordings_Altitude CHECK (DroneAltitude_m > 0),
    FrameRate_Hz    DECIMAL(5,2)        DEFAULT 25.0 CONSTRAINT CK_Recordings_FPS CHECK (FrameRate_Hz > 0),
    TotalVehicles   INT                 DEFAULT 0 CONSTRAINT CK_Recordings_Vehicles CHECK (TotalVehicles >= 0),
    DatasetSource   VARCHAR(50)         DEFAULT 'inD' NOT NULL,
    CreatedAt       DATETIME            DEFAULT GETDATE() NOT NULL,
    
    CONSTRAINT CK_Recordings_Time CHECK (EndTime >= StartTime)
);
GO

-- Bảng 4: VEHICLE_TRACKS (Danh mục các phương tiện được phát hiện trong đợt bay)
CREATE TABLE dbo.VEHICLE_TRACKS
(
    TrackID         BIGINT IDENTITY(1,1) CONSTRAINT PK_VehicleTracks PRIMARY KEY,
    RecordingID     VARCHAR(20)          NOT NULL,
    VehicleID_InRec INT                  NOT NULL,
    VehicleType     NVARCHAR(50)         NOT NULL,
    FirstAppearance DATETIME             NOT NULL,
    LastAppearance  DATETIME             NOT NULL,
    AvgSpeed_kmh    DECIMAL(6,2)         DEFAULT 0 CONSTRAINT CK_Vehicle_AvgSpeed CHECK (AvgSpeed_kmh >= 0),
    TotalDistance_m DECIMAL(10,2)        DEFAULT 0 CONSTRAINT CK_Vehicle_TotalDist CHECK (TotalDistance_m >= 0),

    CONSTRAINT FK_Tracks_Recordings FOREIGN KEY (RecordingID) REFERENCES dbo.RECORDINGS(RecordingID) ON DELETE CASCADE,
    CONSTRAINT UQ_Tracks_Rec_Veh UNIQUE (RecordingID, VehicleID_InRec),
    CONSTRAINT CK_Tracks_Appearance CHECK (LastAppearance >= FirstAppearance)
);
GO

-- Bảng 5: TRAJECTORY_FRAMES (Quỹ đạo chi tiết từng khung hình - Tọa độ X, Y, Vận tốc)
CREATE TABLE dbo.TRAJECTORY_FRAMES
(
    FrameID         BIGINT IDENTITY(1,1) CONSTRAINT PK_TrajectoryFrames PRIMARY KEY,
    TrackID         BIGINT               NOT NULL,
    FrameTimestamp  DATETIME             NOT NULL,
    CoordinateX_m   DECIMAL(10,3)        NOT NULL,
    CoordinateY_m   DECIMAL(10,3)        NOT NULL,
    Speed_kmh       DECIMAL(6,2)         NOT NULL CONSTRAINT CK_Frames_Speed CHECK (Speed_kmh >= 0 AND Speed_kmh <= 200),
    Heading_deg     DECIMAL(6,2),
    Acceleration_ms2 DECIMAL(6,2),

    CONSTRAINT FK_Frames_Tracks FOREIGN KEY (TrackID) REFERENCES dbo.VEHICLE_TRACKS(TrackID) ON DELETE CASCADE
);
GO

-- Bảng 6: TRAFFIC_TIME_SERIES (Chuỗi thời gian mật độ & lưu lượng đã gom cụm)
CREATE TABLE dbo.TRAFFIC_TIME_SERIES
(
    TimeSeriesID    BIGINT IDENTITY(1,1) CONSTRAINT PK_TrafficTimeSeries PRIMARY KEY,
    RecordingID     VARCHAR(20)          NOT NULL,
    WindowTimestamp DATETIME             NOT NULL,
    AggregationWindow VARCHAR(10)        NOT NULL 
                    CONSTRAINT CK_TimeSeries_Window CHECK (AggregationWindow IN ('1min', '5min', '15min', '30min')),
    VehicleCount    INT                  NOT NULL CONSTRAINT CK_TS_Count CHECK (VehicleCount >= 0),
    Flow_veh_per_h  DECIMAL(8,2)         NOT NULL CONSTRAINT CK_TS_Flow CHECK (Flow_veh_per_h >= 0),
    Density_veh_per_km DECIMAL(8,2)      NOT NULL CONSTRAINT CK_TS_Density CHECK (Density_veh_per_km >= 0),
    AvgSpeed_kmh    DECIMAL(6,2)         NOT NULL CONSTRAINT CK_TS_Speed CHECK (AvgSpeed_kmh >= 0),
    CongestionLevel NVARCHAR(50)         NOT NULL,

    CONSTRAINT FK_TS_Recordings FOREIGN KEY (RecordingID) REFERENCES dbo.RECORDINGS(RecordingID) ON DELETE CASCADE,
    CONSTRAINT UQ_TS_Rec_Time_Win UNIQUE (RecordingID, WindowTimestamp, AggregationWindow)
);
GO

-- ===================================================================================
-- 5. TẠO CÁC BẢNG QUẢN LÝ THỰC NGHIỆM DỰ BÁO (EXPERIMENT MANAGEMENT)
-- ===================================================================================

CREATE TABLE dbo.EXPERIMENTS
(
    ExperimentID    INT IDENTITY(1,1)    CONSTRAINT PK_Experiments PRIMARY KEY,
    ExperimentName  NVARCHAR(150)        NOT NULL,
    RecordingID     VARCHAR(20)          NOT NULL,
    ModelAlgorithm  VARCHAR(50)          NOT NULL 
                    CONSTRAINT CK_Exp_Model CHECK (ModelAlgorithm IN ('ARIMA', 'Prophet', 'Moving Average', 'Holt-Winters')),
    AggregationWindow VARCHAR(10)        DEFAULT '5min' NOT NULL,
    TrainTestRatio  DECIMAL(3,2)         DEFAULT 0.80 NOT NULL,
    Hyperparameters NVARCHAR(500),
    RandomSeed      INT                  DEFAULT 42 NOT NULL,
    CreatedBy       VARCHAR(50)          DEFAULT SUSER_SNAME(),
    CreatedAt       DATETIME             DEFAULT GETDATE() NOT NULL,
    ExecutionStatus VARCHAR(20)          DEFAULT 'Completed' 
                    CONSTRAINT CK_Exp_Status CHECK (ExecutionStatus IN ('Pending', 'Running', 'Completed', 'Failed')),

    CONSTRAINT FK_Exp_Recordings FOREIGN KEY (RecordingID) REFERENCES dbo.RECORDINGS(RecordingID)
);
GO

CREATE TABLE dbo.FORECAST_RESULTS
(
    ResultID        BIGINT IDENTITY(1,1) CONSTRAINT PK_ForecastResults PRIMARY KEY,
    ExperimentID    INT                  NOT NULL,
    ForecastTime    DATETIME             NOT NULL,
    ActualDensity   DECIMAL(8,2),
    PredictedDensity DECIMAL(8,2)        NOT NULL CONSTRAINT CK_Pred_Density CHECK (PredictedDensity >= 0),
    AbsoluteError   DECIMAL(8,2),
    PercentageError DECIMAL(6,2),

    CONSTRAINT FK_Results_Experiments FOREIGN KEY (ExperimentID) REFERENCES dbo.EXPERIMENTS(ExperimentID) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.EXPERIMENT_METRICS
(
    ExperimentID    INT                  CONSTRAINT PK_ExpMetrics PRIMARY KEY,
    MAE             DECIMAL(8,4)         NOT NULL,
    RMSE            DECIMAL(8,4)         NOT NULL,
    MAPE            DECIMAL(6,2)         NOT NULL,
    R2_Score        DECIMAL(6,4),
    EvaluatedAt     DATETIME             DEFAULT GETDATE() NOT NULL,

    CONSTRAINT FK_Metrics_Experiments FOREIGN KEY (ExperimentID) REFERENCES dbo.EXPERIMENTS(ExperimentID) ON DELETE CASCADE
);
GO

-- ===================================================================================
-- 6. TỐI ƯU HÓA TRUY VẤN: TẠO CÁC CHỈ MỤC (INDEXING STRATEGY)
-- ===================================================================================

CREATE NONCLUSTERED INDEX IX_TrajectoryFrames_Track_Time 
ON dbo.TRAJECTORY_FRAMES (TrackID, FrameTimestamp)
INCLUDE (CoordinateX_m, CoordinateY_m, Speed_kmh);
GO

CREATE NONCLUSTERED INDEX IX_TrafficTimeSeries_Rec_Win_Time
ON dbo.TRAFFIC_TIME_SERIES (RecordingID, AggregationWindow, WindowTimestamp)
INCLUDE (VehicleCount, Density_veh_per_km, AvgSpeed_kmh, CongestionLevel);
GO

CREATE NONCLUSTERED INDEX IX_ForecastResults_Exp_Time
ON dbo.FORECAST_RESULTS (ExperimentID, ForecastTime)
INCLUDE (ActualDensity, PredictedDensity, AbsoluteError);
GO

PRINT N'==> Đã khởi tạo hoàn tất 9 bảng, ràng buộc và Index cho CSDL UAV_TrafficDB.';
GO
