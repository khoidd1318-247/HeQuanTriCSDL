-- ===================================================================================
-- Module 5: Experiment Management & Reproducibility
-- File 04: Benchmark Sample Data (ARIMA vs Facebook Prophet)
-- Project: Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting
-- DBMS: Microsoft SQL Server (T-SQL)
-- ===================================================================================

USE UAV_TrafficDB;
GO

SET NOCOUNT ON;

-- 1. Nạp thực nghiệm mẫu 01: ARIMA(2,1,2)
IF NOT EXISTS (SELECT 1 FROM dbo.EXPERIMENTS WHERE ExperimentName LIKE N'%ARIMA(2,1,2)%')
BEGIN
    INSERT INTO dbo.EXPERIMENTS
    (ExperimentName, RecordingID, ModelAlgorithm, AggregationWindow, TrainTestRatio, Hyperparameters, RandomSeed, ExecutionStatus, Notes)
    VALUES
    (N'Thực nghiệm 01: Dự báo ngắn hạn bằng ARIMA(2,1,2)', 'REC_IND_01', 'ARIMA', '5min', 0.80, 'p=2, d=1, q=2, trend=c', 42, 'Completed', N'Mô hình chuỗi thời gian thống kê ARIMA cổ điển');

    DECLARE @Exp1 INT = SCOPE_IDENTITY();

    INSERT INTO dbo.FORECAST_RESULTS (ExperimentID, ForecastTime, ActualDensity, PredictedDensity, AbsoluteError, PercentageError)
    VALUES
    (@Exp1, '2026-10-10 07:45:00', 84.0, 86.5, 2.5, 2.98),
    (@Exp1, '2026-10-10 07:50:00', 70.4, 73.2, 2.8, 3.98),
    (@Exp1, '2026-10-10 07:55:00', 52.0, 55.4, 3.4, 6.54),
    (@Exp1, '2026-10-10 08:00:00', 38.4, 41.0, 2.6, 6.77),
    (@Exp1, '2026-10-10 08:05:00', 28.0, 30.5, 2.5, 8.93);

    INSERT INTO dbo.EXPERIMENT_METRICS (ExperimentID, MAE, RMSE, MAPE, R2_Score)
    VALUES (@Exp1, 2.7600, 2.7845, 6.24, 0.9412);
END;

-- 2. Nạp thực nghiệm mẫu 02: Facebook Prophet
IF NOT EXISTS (SELECT 1 FROM dbo.EXPERIMENTS WHERE ExperimentName LIKE N'%Facebook Prophet%')
BEGIN
    INSERT INTO dbo.EXPERIMENTS
    (ExperimentName, RecordingID, ModelAlgorithm, AggregationWindow, TrainTestRatio, Hyperparameters, RandomSeed, ExecutionStatus, Notes)
    VALUES
    (N'Thực nghiệm 02: Dự báo ngắn hạn bằng Facebook Prophet', 'REC_IND_01', 'Prophet', '5min', 0.80, 'seasonality_mode=multiplicative, changepoint_prior=0.05', 42, 'Completed', N'Mô hình chuỗi thời gian hiện đại Facebook Prophet');

    DECLARE @Exp2 INT = SCOPE_IDENTITY();

    INSERT INTO dbo.FORECAST_RESULTS (ExperimentID, ForecastTime, ActualDensity, PredictedDensity, AbsoluteError, PercentageError)
    VALUES
    (@Exp2, '2026-10-10 07:45:00', 84.0, 85.1, 1.1, 1.31),
    (@Exp2, '2026-10-10 07:50:00', 70.4, 71.8, 1.4, 1.99),
    (@Exp2, '2026-10-10 07:55:00', 52.0, 53.6, 1.6, 3.08),
    (@Exp2, '2026-10-10 08:00:00', 38.4, 39.8, 1.4, 3.65),
    (@Exp2, '2026-10-10 08:05:00', 28.0, 29.5, 1.5, 5.36);

    INSERT INTO dbo.EXPERIMENT_METRICS (ExperimentID, MAE, RMSE, MAPE, R2_Score)
    VALUES (@Exp2, 1.4000, 1.4170, 3.08, 0.9854);
END;
GO
