-- ===================================================================================
-- Module 5: Experiment Management & Reproducibility
-- File 02: User-Defined Functions (UDF) for Model Evaluation Metrics
-- Project: Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting
-- DBMS: Microsoft SQL Server (T-SQL)
-- ===================================================================================

USE UAV_TrafficDB;
GO

-- 1. UDF: Mean Absolute Error (MAE)
-- Công thức: MAE = (1/n) * SUM(|Actual - Predicted|)
IF OBJECT_ID('dbo.fn_CalculateMAE', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CalculateMAE;
GO
CREATE FUNCTION dbo.fn_CalculateMAE (@ExperimentID INT)
RETURNS DECIMAL(8,4)
AS
BEGIN
    DECLARE @MAE DECIMAL(8,4);
    SELECT @MAE = AVG(ABS(ActualDensity - PredictedDensity))
    FROM dbo.FORECAST_RESULTS
    WHERE ExperimentID = @ExperimentID AND ActualDensity IS NOT NULL;
    RETURN ISNULL(@MAE, 0.0);
END;
GO

-- 2. UDF: Root Mean Squared Error (RMSE)
-- Công thức: RMSE = SQRT((1/n) * SUM((Actual - Predicted)^2))
IF OBJECT_ID('dbo.fn_CalculateRMSE', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CalculateRMSE;
GO
CREATE FUNCTION dbo.fn_CalculateRMSE (@ExperimentID INT)
RETURNS DECIMAL(8,4)
AS
BEGIN
    DECLARE @RMSE DECIMAL(8,4);
    SELECT @RMSE = SQRT(AVG(POWER(ActualDensity - PredictedDensity, 2)))
    FROM dbo.FORECAST_RESULTS
    WHERE ExperimentID = @ExperimentID AND ActualDensity IS NOT NULL;
    RETURN ISNULL(@RMSE, 0.0);
END;
GO

-- 3. UDF: Mean Absolute Percentage Error (MAPE - %)
-- Công thức: MAPE = (100% / n) * SUM(|Actual - Predicted| / Actual)
IF OBJECT_ID('dbo.fn_CalculateMAPE', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CalculateMAPE;
GO
CREATE FUNCTION dbo.fn_CalculateMAPE (@ExperimentID INT)
RETURNS DECIMAL(6,2)
AS
BEGIN
    DECLARE @MAPE DECIMAL(6,2);
    SELECT @MAPE = AVG((ABS(ActualDensity - PredictedDensity) / NULLIF(ActualDensity, 0)) * 100.0)
    FROM dbo.FORECAST_RESULTS
    WHERE ExperimentID = @ExperimentID AND ActualDensity IS NOT NULL AND ActualDensity > 0;
    RETURN ISNULL(@MAPE, 0.0);
END;
GO
