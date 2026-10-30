-- ===================================================================================
-- ĐỒ ÁN MÔN HỌC: HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU
-- ĐỀ TÀI: Phân tích mô hình giao thông đô thị và dự báo ùn tắc ngắn hạn sử dụng dữ liệu UAV
-- HỆ QUẢN TRỊ: Microsoft SQL Server (Transact-SQL)
-- TÁC GIẢ: Dương Đình Khôi & Nhóm nghiên cứu
-- FILE 03: ĐỊNH NGHĨA CÁC HÀM DO NGƯỜI DÙNG ĐỊNH NGHĨA (USER-DEFINED FUNCTIONS - UDF)
-- ===================================================================================

USE UAV_TrafficDB;
GO

-- ===================================================================================
-- 1. SCALAR FUNCTION: TÍNH KHOẢNG CÁCH EUCLIDEAN GIỮA 2 TỌA ĐỘ TRONG KHÔNG GIAN (MÉT)
-- Công thức: d = sqrt((x2 - x1)^2 + (y2 - y1)^2)
-- ===================================================================================
IF OBJECT_ID('dbo.fn_CalculateDistance', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CalculateDistance;
GO

CREATE FUNCTION dbo.fn_CalculateDistance
(
    @X1 DECIMAL(10,3),
    @Y1 DECIMAL(10,3),
    @X2 DECIMAL(10,3),
    @Y2 DECIMAL(10,3)
)
RETURNS DECIMAL(10,3)
AS
BEGIN
    DECLARE @Distance DECIMAL(10,3);
    
    SET @Distance = SQRT(POWER(@X2 - @X1, 2) + POWER(@Y2 - @Y1, 2));
    
    RETURN ISNULL(@Distance, 0.0);
END;
GO

-- ===================================================================================
-- 2. SCALAR FUNCTION: PHÂN LOẠI MỨC ĐỘ ÙN TẮC GIAO THÔNG (SỬ DỤNG CASE...WHEN)
-- Dựa trên quy chuẩn ITS: Vận tốc trung bình và Mật độ dòng xe
-- ===================================================================================
IF OBJECT_ID('dbo.fn_ClassifyCongestion', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_ClassifyCongestion;
GO

CREATE FUNCTION dbo.fn_ClassifyCongestion
(
    @AvgSpeed_kmh DECIMAL(6,2),
    @Density_veh_per_km DECIMAL(8,2)
)
RETURNS NVARCHAR(30)
AS
BEGIN
    DECLARE @Status NVARCHAR(30);

    SET @Status = CASE 
        WHEN @AvgSpeed_kmh >= 35.0 AND @Density_veh_per_km < 30.0 
            THEN N'Thông thoáng'
        WHEN @AvgSpeed_kmh >= 25.0 AND @Density_veh_per_km < 55.0 
            THEN N'Bình thường'
        WHEN @AvgSpeed_kmh >= 15.0 AND @Density_veh_per_km < 85.0 
            THEN N'Đông đúc'
        ELSE 
            N'Ùn tắc nghiêm trọng'
    END;

    RETURN @Status;
END;
GO

-- ===================================================================================
-- 3. SCALAR FUNCTION: TÍNH CHỈ SỐ MAE (MEAN ABSOLUTE ERROR) TRỰC TIẾP TRONG T-SQL
-- Công thức: MAE = (1/n) * SUM(|Actual - Predicted|)
-- ===================================================================================
IF OBJECT_ID('dbo.fn_CalculateMAE', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CalculateMAE;
GO

CREATE FUNCTION dbo.fn_CalculateMAE
(
    @ExperimentID INT
)
RETURNS DECIMAL(8,4)
AS
BEGIN
    DECLARE @MAE DECIMAL(8,4);

    SELECT @MAE = AVG(ABS(ActualDensity - PredictedDensity))
    FROM dbo.FORECAST_RESULTS
    WHERE ExperimentID = @ExperimentID
      AND ActualDensity IS NOT NULL;

    RETURN ISNULL(@MAE, 0.0);
END;
GO

-- ===================================================================================
-- 4. SCALAR FUNCTION: TÍNH CHỈ SỐ RMSE (ROOT MEAN SQUARED ERROR) TRỰC TIẾP TRONG T-SQL
-- Công thức: RMSE = SQRT( (1/n) * SUM((Actual - Predicted)^2) )
-- ===================================================================================
IF OBJECT_ID('dbo.fn_CalculateRMSE', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CalculateRMSE;
GO

CREATE FUNCTION dbo.fn_CalculateRMSE
(
    @ExperimentID INT
)
RETURNS DECIMAL(8,4)
AS
BEGIN
    DECLARE @RMSE DECIMAL(8,4);

    SELECT @RMSE = SQRT(AVG(POWER(ActualDensity - PredictedDensity, 2)))
    FROM dbo.FORECAST_RESULTS
    WHERE ExperimentID = @ExperimentID
      AND ActualDensity IS NOT NULL;

    RETURN ISNULL(@RMSE, 0.0);
END;
GO

-- ===================================================================================
-- 5. SCALAR FUNCTION: TÍNH CHỈ SỐ MAPE (MEAN ABSOLUTE PERCENTAGE ERROR - %)
-- Công thức: MAPE = (1/n) * SUM(|Actual - Predicted| / Actual) * 100
-- ===================================================================================
IF OBJECT_ID('dbo.fn_CalculateMAPE', 'FN') IS NOT NULL DROP FUNCTION dbo.fn_CalculateMAPE;
GO

CREATE FUNCTION dbo.fn_CalculateMAPE
(
    @ExperimentID INT
)
RETURNS DECIMAL(6,2)
AS
BEGIN
    DECLARE @MAPE DECIMAL(6,2);

    SELECT @MAPE = AVG((ABS(ActualDensity - PredictedDensity) / NULLIF(ActualDensity, 0)) * 100.0)
    FROM dbo.FORECAST_RESULTS
    WHERE ExperimentID = @ExperimentID
      AND ActualDensity IS NOT NULL
      AND ActualDensity > 0;

    RETURN ISNULL(@MAPE, 0.0);
END;
GO

-- ===================================================================================
-- 6. INLINE TABLE-VALUED FUNCTION: LỌC CHUỖI THỜI GIAN MẬT ĐỘ THEO KHOẢNG THỜI GIAN
-- Phục vụ ứng dụng Dashboard lấy dữ liệu nhanh và tối ưu
-- ===================================================================================
IF OBJECT_ID('dbo.fn_GetTrafficDensityByTimeRange', 'IF') IS NOT NULL DROP FUNCTION dbo.fn_GetTrafficDensityByTimeRange;
GO

CREATE FUNCTION dbo.fn_GetTrafficDensityByTimeRange
(
    @RecordingID VARCHAR(20),
    @StartTime DATETIME,
    @EndTime DATETIME,
    @AggregationWindow VARCHAR(10)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        TimeSeriesID,
        RecordingID,
        WindowTimestamp,
        AggregationWindow,
        VehicleCount,
        Flow_veh_per_h,
        Density_veh_per_km,
        AvgSpeed_kmh,
        CongestionLevel
    FROM dbo.TRAFFIC_TIME_SERIES
    WHERE RecordingID = @RecordingID
      AND AggregationWindow = @AggregationWindow
      AND WindowTimestamp BETWEEN @StartTime AND @EndTime
);
GO

PRINT N'==> Đã khởi tạo hoàn tất 6 User-Defined Functions (Scalar & Table-Valued)!';
GO
