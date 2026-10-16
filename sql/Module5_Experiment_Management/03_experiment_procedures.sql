-- ===================================================================================
-- Module 5: Experiment Management & Reproducibility
-- File 03: Stored Procedures & Triggers
-- Project: Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting
-- DBMS: Microsoft SQL Server (T-SQL)
-- ===================================================================================

USE UAV_TrafficDB;
GO

-- 1. SP: sp_CreateExperiment - Tạo mới một phiên thực nghiệm trong Transaction
IF OBJECT_ID('dbo.sp_CreateExperiment', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_CreateExperiment;
GO
CREATE PROCEDURE dbo.sp_CreateExperiment
    @ExperimentName     NVARCHAR(150),
    @RecordingID        VARCHAR(20),
    @ModelAlgorithm     VARCHAR(50),
    @AggregationWindow  VARCHAR(10) = '5min',
    @TrainTestRatio     DECIMAL(3,2) = 0.80,
    @Hyperparameters    NVARCHAR(500) = NULL,
    @RandomSeed         INT = 42,
    @Notes              NVARCHAR(500) = NULL,
    @NewExperimentID    INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.EXPERIMENTS
        (
            ExperimentName, RecordingID, ModelAlgorithm, AggregationWindow,
            TrainTestRatio, Hyperparameters, RandomSeed, CreatedBy, CreatedAt, ExecutionStatus, Notes
        )
        VALUES
        (
            @ExperimentName, @RecordingID, @ModelAlgorithm, @AggregationWindow,
            @TrainTestRatio, @Hyperparameters, @RandomSeed, SUSER_SNAME(), GETDATE(), 'Running', @Notes
        );

        SET @NewExperimentID = SCOPE_IDENTITY();

        -- Ghi Audit Log an toàn
        INSERT INTO dbo.AUDIT_LOGS (ActionType, TargetTable, RecordKey, Description)
        VALUES ('CREATE_EXPERIMENT', 'EXPERIMENTS', CAST(@NewExperimentID AS VARCHAR(20)),
                N'Khởi tạo phiên thực nghiệm [' + @ExperimentName + N'] - Thuật toán: ' + @ModelAlgorithm + N', Seed: ' + CAST(@RandomSeed AS VARCHAR(10)));

        COMMIT TRANSACTION;

        SELECT @NewExperimentID AS ExperimentID, N'Tạo thực nghiệm thành công' AS MessageStatus;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH;
END;
GO

-- 2. SP: sp_LogForecastResult - Ghi nhận kết quả dự báo từng bước thời gian
IF OBJECT_ID('dbo.sp_LogForecastResult', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_LogForecastResult;
GO
CREATE PROCEDURE dbo.sp_LogForecastResult
    @ExperimentID       INT,
    @ForecastTime       DATETIME,
    @ActualDensity      DECIMAL(8,2) = NULL,
    @PredictedDensity   DECIMAL(8,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AbsErr DECIMAL(8,2) = NULL;
    DECLARE @PctErr DECIMAL(6,2) = NULL;

    IF @ActualDensity IS NOT NULL
    BEGIN
        SET @AbsErr = ABS(@ActualDensity - @PredictedDensity);
        IF @ActualDensity > 0
            SET @PctErr = (@AbsErr / @ActualDensity) * 100.0;
    END

    INSERT INTO dbo.FORECAST_RESULTS
    (ExperimentID, ForecastTime, ActualDensity, PredictedDensity, AbsoluteError, PercentageError)
    VALUES
    (@ExperimentID, @ForecastTime, @ActualDensity, @PredictedDensity, @AbsErr, @PctErr);
END;
GO

-- 3. SP: sp_EvaluateAndSaveMetrics - Tính toán toàn bộ chỉ số hiệu năng và lưu trữ
IF OBJECT_ID('dbo.sp_EvaluateAndSaveMetrics', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_EvaluateAndSaveMetrics;
GO
CREATE PROCEDURE dbo.sp_EvaluateAndSaveMetrics
    @ExperimentID INT,
    @MAE_Out DECIMAL(8,4) = NULL OUTPUT,
    @RMSE_Out DECIMAL(8,4) = NULL OUTPUT,
    @MAPE_Out DECIMAL(6,2) = NULL OUTPUT,
    @R2_Out DECIMAL(6,4) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Gọi các UDF tính sai số
    SET @MAE_Out = dbo.fn_CalculateMAE(@ExperimentID);
    SET @RMSE_Out = dbo.fn_CalculateRMSE(@ExperimentID);
    SET @MAPE_Out = dbo.fn_CalculateMAPE(@ExperimentID);

    -- 2. Tính hệ số xác định R2 Score
    DECLARE @AvgActual DECIMAL(8,2);
    SELECT @AvgActual = AVG(ActualDensity) FROM dbo.FORECAST_RESULTS WHERE ExperimentID = @ExperimentID;

    SELECT @R2_Out = CASE 
        WHEN SUM(POWER(ActualDensity - @AvgActual, 2)) > 0 
            THEN 1.0 - (SUM(POWER(ActualDensity - PredictedDensity, 2)) / SUM(POWER(ActualDensity - @AvgActual, 2)))
        ELSE 0.0 
    END
    FROM dbo.FORECAST_RESULTS
    WHERE ExperimentID = @ExperimentID;

    -- 3. Lưu vào bảng EXPERIMENT_METRICS
    IF EXISTS (SELECT 1 FROM dbo.EXPERIMENT_METRICS WHERE ExperimentID = @ExperimentID)
    BEGIN
        UPDATE dbo.EXPERIMENT_METRICS
        SET MAE = @MAE_Out, RMSE = @RMSE_Out, MAPE = @MAPE_Out, R2_Score = @R2_Out, EvaluatedAt = GETDATE()
        WHERE ExperimentID = @ExperimentID;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.EXPERIMENT_METRICS (ExperimentID, MAE, RMSE, MAPE, R2_Score)
        VALUES (@ExperimentID, @MAE_Out, @RMSE_Out, @MAPE_Out, @R2_Out);
    END

    UPDATE dbo.EXPERIMENTS SET ExecutionStatus = 'Completed' WHERE ExperimentID = @ExperimentID;

    SELECT 
        @ExperimentID AS ExperimentID,
        @MAE_Out AS MAE,
        @RMSE_Out AS RMSE,
        @MAPE_Out AS [MAPE (%)],
        @R2_Out AS [R2_Score],
        N'Đánh giá thực nghiệm thành công' AS MessageStatus;
END;
GO

-- 4. SP: sp_CompareExperiments - So sánh đối kháng trực tiếp các phiên thực nghiệm
IF OBJECT_ID('dbo.sp_CompareExperiments', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_CompareExperiments;
GO
CREATE PROCEDURE dbo.sp_CompareExperiments
    @ExperimentID1 INT,
    @ExperimentID2 INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        E.ExperimentID,
        E.ExperimentName AS [Tên thực nghiệm],
        E.ModelAlgorithm AS [Thuật toán],
        E.AggregationWindow AS [Cửa sổ gom],
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
    WHERE E.ExperimentID IN (@ExperimentID1, @ExperimentID2)
    ORDER BY M.RMSE ASC;
END;
GO

-- 5. Trigger: trg_Audit_Experiment_Created - Tự động ghi nhật ký hệ thống
IF OBJECT_ID('dbo.trg_Audit_Experiment_Created', 'TR') IS NOT NULL 
    DROP TRIGGER dbo.trg_Audit_Experiment_Created;
GO
CREATE TRIGGER dbo.trg_Audit_Experiment_Created
ON dbo.EXPERIMENTS
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.AUDIT_LOGS (ActionType, TargetTable, RecordKey, Description)
    SELECT 'RUN_EXPERIMENT', 'EXPERIMENTS', CAST(I.ExperimentID AS VARCHAR(20)),
           N'Đã tạo phiên thực nghiệm [' + I.ExperimentName + N'] - Thuật toán: ' + I.ModelAlgorithm + N', Cửa sổ: ' + I.AggregationWindow + N', Seed: ' + CAST(I.RandomSeed AS VARCHAR(10))
    FROM inserted I;
END;
GO
