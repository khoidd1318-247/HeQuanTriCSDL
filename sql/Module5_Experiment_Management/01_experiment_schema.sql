-- ===================================================================================
-- Module 5: Experiment Management & Reproducibility
-- File 01: Table Schema, Primary/Foreign Keys, Constraints & Indexes
-- Project: Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting
-- DBMS: Microsoft SQL Server (T-SQL)
-- ===================================================================================

USE UAV_TrafficDB;
GO

-- 1. Table EXPERIMENTS: Quản lý cấu hình thử nghiệm, siêu tham số và hạt giống tái lập
IF OBJECT_ID('dbo.EXPERIMENTS', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.EXPERIMENTS
    (
        ExperimentID        INT IDENTITY(1,1)   CONSTRAINT PK_Experiments PRIMARY KEY,
        ExperimentName      NVARCHAR(150)       NOT NULL,
        RecordingID         VARCHAR(20)         NOT NULL,
        ModelAlgorithm      VARCHAR(50)         NOT NULL 
                            CONSTRAINT CK_Exp_Model CHECK (ModelAlgorithm IN ('ARIMA', 'Prophet', 'Moving Average', 'Holt-Winters')),
        AggregationWindow   VARCHAR(10)         DEFAULT '5min' NOT NULL
                            CONSTRAINT CK_Exp_Window CHECK (AggregationWindow IN ('1min', '5min', '15min', '30min')),
        TrainTestRatio      DECIMAL(3,2)        DEFAULT 0.80 NOT NULL
                            CONSTRAINT CK_Exp_Ratio CHECK (TrainTestRatio > 0.0 AND TrainTestRatio < 1.0),
        Hyperparameters     NVARCHAR(500),       -- ví dụ: 'p=2, d=1, q=2' hoặc JSON string
        RandomSeed          INT                 DEFAULT 42 NOT NULL, -- Seed cố định để đảm bảo tính tái lập (Reproducibility)
        CreatedBy           VARCHAR(50)         DEFAULT SUSER_SNAME(),
        CreatedAt           DATETIME            DEFAULT GETDATE() NOT NULL,
        ExecutionStatus     VARCHAR(20)         DEFAULT 'Completed' 
                            CONSTRAINT CK_Exp_Status CHECK (ExecutionStatus IN ('Pending', 'Running', 'Completed', 'Failed')),
        Notes               NVARCHAR(500)
    );
END
GO

-- 2. Table FORECAST_RESULTS: Lưu kết quả dự báo chi tiết từng bước thời gian
IF OBJECT_ID('dbo.FORECAST_RESULTS', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FORECAST_RESULTS
    (
        ResultID            BIGINT IDENTITY(1,1) CONSTRAINT PK_ForecastResults PRIMARY KEY,
        ExperimentID        INT                  NOT NULL,
        ForecastTime        DATETIME             NOT NULL,
        ActualDensity       DECIMAL(8,2),        -- Mật độ thực tế (Ground Truth)
        PredictedDensity    DECIMAL(8,2)         NOT NULL CONSTRAINT CK_Pred_Density CHECK (PredictedDensity >= 0),
        AbsoluteError       DECIMAL(8,2),        -- |Actual - Predicted|
        PercentageError     DECIMAL(6,2),        -- (|Actual - Predicted| / Actual) * 100

        CONSTRAINT FK_Results_Experiments FOREIGN KEY (ExperimentID) REFERENCES dbo.EXPERIMENTS(ExperimentID) ON DELETE CASCADE
    );
END
GO

-- 3. Table EXPERIMENT_METRICS: Đánh giá chỉ số hiệu năng chuẩn hóa quốc tế của thực nghiệm
IF OBJECT_ID('dbo.EXPERIMENT_METRICS', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.EXPERIMENT_METRICS
    (
        ExperimentID        INT                  CONSTRAINT PK_ExpMetrics PRIMARY KEY,
        MAE                 DECIMAL(8,4)         NOT NULL, -- Mean Absolute Error
        RMSE                DECIMAL(8,4)         NOT NULL, -- Root Mean Squared Error
        MAPE                DECIMAL(6,2)         NOT NULL, -- Mean Absolute Percentage Error (%)
        R2_Score            DECIMAL(6,4),                  -- Hệ số xác định R-Squared
        EvaluatedAt         DATETIME             DEFAULT GETDATE() NOT NULL,

        CONSTRAINT FK_Metrics_Experiments FOREIGN KEY (ExperimentID) REFERENCES dbo.EXPERIMENTS(ExperimentID) ON DELETE CASCADE
    );
END
GO

-- 4. Table AUDIT_LOGS: Nhật ký kiểm toán phục vụ theo dõi hoạt động thực nghiệm
IF OBJECT_ID('dbo.AUDIT_LOGS', 'U') IS NULL
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
END
GO

-- 5. Indexes: Tối ưu hóa truy vấn thực nghiệm và kết quả dự báo
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ForecastResults_Exp_Time' AND object_id = OBJECT_ID('dbo.FORECAST_RESULTS'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_ForecastResults_Exp_Time
    ON dbo.FORECAST_RESULTS (ExperimentID, ForecastTime)
    INCLUDE (ActualDensity, PredictedDensity, AbsoluteError, PercentageError);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Experiments_Algorithm_Window' AND object_id = OBJECT_ID('dbo.EXPERIMENTS'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Experiments_Algorithm_Window
    ON dbo.EXPERIMENTS (ModelAlgorithm, AggregationWindow, ExecutionStatus)
    INCLUDE (ExperimentName, TrainTestRatio, CreatedAt);
END
GO
