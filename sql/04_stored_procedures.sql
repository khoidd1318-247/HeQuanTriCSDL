-- ===================================================================================
-- ĐỒ ÁN MÔN HỌC: HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU
-- ĐỀ TÀI: Phân tích mô hình giao thông đô thị và dự báo ùn tắc ngắn hạn sử dụng dữ liệu UAV
-- HỆ QUẢN TRỊ: Microsoft SQL Server (Transact-SQL)
-- TÁC GIẢ: Dương Đình Khôi & Nhóm nghiên cứu
-- FILE 04: ĐỊNH NGHĨA CÁC THỦ TỤC LƯU TRỮ (STORED PROCEDURES)
-- ===================================================================================

USE UAV_TrafficDB;
GO

-- ===================================================================================
-- 1. STORED PROCEDURE: KIỂM ĐỊNH CHẤT LƯỢNG DỮ LIỆU (DATA VALIDATION)
-- Mục tiêu: Phát hiện bản ghi thiếu, vận tốc âm, tọa độ bất thường trước khi phân tích
-- ===================================================================================
IF OBJECT_ID('dbo.sp_ValidateTrafficData', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_ValidateTrafficData;
GO

CREATE PROCEDURE dbo.sp_ValidateTrafficData
    @RecordingID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    PRINT N'=== BẮT ĐẦU KIỂM ĐỊNH DỮ LIỆU ĐỢT BAY: ' + @RecordingID + N' ===';

    -- Bảng tạm lưu kết quả kiểm định
    DECLARE @ValidationResults TABLE
    (
        CheckItem       NVARCHAR(100),
        ErrorCount      INT,
        Status          NVARCHAR(30),
        Recommendation  NVARCHAR(200)
    );

    -- 1. Kiểm tra vận tốc bất thường (< 0 hoặc > 150 km/h)
    DECLARE @InvalidSpeedCount INT;
    SELECT @InvalidSpeedCount = COUNT(*)
    FROM dbo.TRAJECTORY_FRAMES F
    JOIN dbo.VEHICLE_TRACKS T ON F.TrackID = T.TrackID
    WHERE T.RecordingID = @RecordingID
      AND (F.Speed_kmh < 0 OR F.Speed_kmh > 150);

    INSERT INTO @ValidationResults VALUES
    (N'Vận tốc phương tiện bất thường (<0 hoặc >150 km/h)', @InvalidSpeedCount, 
     CASE WHEN @InvalidSpeedCount = 0 THEN N'HỢP LỆ' ELSE N'CẢNH BÁO' END,
     CASE WHEN @InvalidSpeedCount = 0 THEN N'Dữ liệu tốt' ELSE N'Cần lọc bỏ hoặc hiệu chỉnh nhiễu GPS' END);

    -- 2. Kiểm tra các xe không có điểm tọa độ nào
    DECLARE @OrphanTracksCount INT;
    SELECT @OrphanTracksCount = COUNT(*)
    FROM dbo.VEHICLE_TRACKS T
    LEFT JOIN dbo.TRAJECTORY_FRAMES F ON T.TrackID = F.TrackID
    WHERE T.RecordingID = @RecordingID AND F.FrameID IS NULL;

    INSERT INTO @ValidationResults VALUES
    (N'Phương tiện thiếu dữ liệu tọa độ (Orphan Tracks)', @OrphanTracksCount,
     CASE WHEN @OrphanTracksCount = 0 THEN N'HỢP LỆ' ELSE N'LỖI NGHIÊM TRỌNG' END,
     CASE WHEN @OrphanTracksCount = 0 THEN N'Dữ liệu toàn vẹn' ELSE N'Cần xóa các Track rỗng' END);

    -- 3. Kiểm tra mốc thời gian không hợp lệ (LastAppearance < FirstAppearance)
    DECLARE @InvalidTimeCount INT;
    SELECT @InvalidTimeCount = COUNT(*)
    FROM dbo.VEHICLE_TRACKS
    WHERE RecordingID = @RecordingID AND LastAppearance < FirstAppearance;

    INSERT INTO @ValidationResults VALUES
    (N'Mốc thời gian xuất hiện xe bị nghịch đảo', @InvalidTimeCount,
     CASE WHEN @InvalidTimeCount = 0 THEN N'HỢP LỆ' ELSE N'LỖI NGHIÊM TRỌNG' END,
     CASE WHEN @InvalidTimeCount = 0 THEN N'Mốc thời gian chuẩn' ELSE N'Cần kiểm tra định dạng Timestamp' END);

    -- Ghi nhận lịch sử kiểm định vào AUDIT_LOGS
    INSERT INTO dbo.AUDIT_LOGS (ActionType, TargetTable, RecordKey, Description)
    VALUES ('DATA_VALIDATION', 'RECORDINGS', @RecordingID, 
            N'Thực thi sp_ValidateTrafficData: Phát hiện ' + CAST(@InvalidSpeedCount + @OrphanTracksCount + @InvalidTimeCount AS NVARCHAR(10)) + N' cảnh báo/lỗi.');

    -- Trả kết quả kiểm định cho ứng dụng
    SELECT CheckItem AS [Hạng mục kiểm tra], 
           ErrorCount AS [Số lỗi phát hiện], 
           Status AS [Trạng thái], 
           Recommendation AS [Khuyến nghị xử lý]
    FROM @ValidationResults;
END;
GO

-- ===================================================================================
-- 2. STORED PROCEDURE: GOM CỤM CHUỖI THỜI GIAN MẬT ĐỘ TỪ TỌA ĐỘ UAV
-- Chuyển đổi dữ liệu quỹ đạo chi tiết thành chuỗi thời gian (1min, 5min, 15min)
-- ===================================================================================
IF OBJECT_ID('dbo.sp_AggregateTrafficTimeSeries', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_AggregateTrafficTimeSeries;
GO

CREATE PROCEDURE dbo.sp_AggregateTrafficTimeSeries
    @RecordingID VARCHAR(20),
    @WindowMinutes INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @WindowCode VARCHAR(10) = CAST(@WindowMinutes AS VARCHAR(5)) + 'min';

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Xóa dữ liệu gom cụm cũ của đợt bay này cùng cửa sổ
        DELETE FROM dbo.TRAFFIC_TIME_SERIES
        WHERE RecordingID = @RecordingID AND AggregationWindow = @WindowCode;

        -- 2. Gom cụm dữ liệu quỹ đạo theo khung thời gian
        ;WITH TimeWindows AS
        (
            SELECT 
                T.RecordingID,
                -- Làm tròn mốc thời gian về đầu chu kỳ @WindowMinutes phút
                DATEADD(minute, (DATEDIFF(minute, 0, F.FrameTimestamp) / @WindowMinutes) * @WindowMinutes, 0) AS WindowTimestamp,
                COUNT(DISTINCT T.TrackID) AS DistinctVehicles,
                AVG(F.Speed_kmh) AS AvgSpeed,
                COUNT(F.FrameID) AS TotalFrames
            FROM dbo.VEHICLE_TRACKS T
            JOIN dbo.TRAJECTORY_FRAMES F ON T.TrackID = F.TrackID
            WHERE T.RecordingID = @RecordingID
            GROUP BY 
                T.RecordingID,
                DATEADD(minute, (DATEDIFF(minute, 0, F.FrameTimestamp) / @WindowMinutes) * @WindowMinutes, 0)
        )
        INSERT INTO dbo.TRAFFIC_TIME_SERIES
        (
            RecordingID,
            WindowTimestamp,
            AggregationWindow,
            VehicleCount,
            Flow_veh_per_h,
            Density_veh_per_km,
            AvgSpeed_kmh,
            CongestionLevel
        )
        SELECT 
            TW.RecordingID,
            TW.WindowTimestamp,
            @WindowCode,
            TW.DistinctVehicles,
            -- Tính lưu lượng q (xe/giờ): Số xe * (60 / số phút gom)
            CAST(TW.DistinctVehicles * (60.0 / @WindowMinutes) AS DECIMAL(8,2)),
            -- Tính mật độ k (xe/km): Ước tính theo công thức dòng xe: k = q / v
            CAST(CASE 
                WHEN TW.AvgSpeed > 5.0 THEN (TW.DistinctVehicles * (60.0 / @WindowMinutes)) / TW.AvgSpeed 
                ELSE TW.DistinctVehicles * 1.5 
            END AS DECIMAL(8,2)),
            CAST(TW.AvgSpeed AS DECIMAL(6,2)),
            -- Gọi UDF để phân loại mức độ ùn tắc
            dbo.fn_ClassifyCongestion(TW.AvgSpeed, 
                CASE 
                    WHEN TW.AvgSpeed > 5.0 THEN (TW.DistinctVehicles * (60.0 / @WindowMinutes)) / TW.AvgSpeed 
                    ELSE TW.DistinctVehicles * 1.5 
                END)
        FROM TimeWindows TW;

        DECLARE @InsertedCount INT = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Ghi log
        INSERT INTO dbo.AUDIT_LOGS (ActionType, TargetTable, RecordKey, Description)
        VALUES ('UPDATE', 'TRAFFIC_TIME_SERIES', @RecordingID, 
                N'Gom cụm hoàn tất ' + CAST(@InsertedCount AS NVARCHAR(10)) + N' mốc thời gian (' + @WindowCode + N').');

        SELECT @InsertedCount AS InsertedRows, N'Thành công' AS MessageStatus;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH;
END;
GO

-- ===================================================================================
-- 3. STORED PROCEDURE: PHÁT HIỆN GIỜ CAO ĐIỂM VÀ ĐIỂM NÓNG ÙN TẮC (HOTSPOTS)
-- ===================================================================================
IF OBJECT_ID('dbo.sp_DetectPeakHoursAndHotspots', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_DetectPeakHoursAndHotspots;
GO

CREATE PROCEDURE dbo.sp_DetectPeakHoursAndHotspots
    @RecordingID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Phần 1: Top 3 khung giờ cao điểm có mật độ xe cao nhất
    SELECT TOP 3
        WindowTimestamp AS [Khung giờ],
        VehicleCount AS [Số xe phát hiện],
        Density_veh_per_km AS [Mật độ (xe/km)],
        AvgSpeed_kmh AS [Vận tốc trung bình (km/h)],
        CongestionLevel AS [Mức độ ùn tắc],
        RANK() OVER (ORDER BY Density_veh_per_km DESC) AS [Xếp hạng cao điểm]
    FROM dbo.TRAFFIC_TIME_SERIES
    WHERE RecordingID = @RecordingID
    ORDER BY Density_veh_per_km DESC;

    -- Phần 2: Điểm nóng ùn tắc không gian (Spatial Congestion Hotspots)
    -- Gom cụm theo các ô tọa độ lưới 20m x 20m
    SELECT TOP 5
        CAST(FLOOR(F.CoordinateX_m / 20.0) * 20.0 AS VARCHAR(10)) + 'm - ' + 
        CAST(FLOOR(F.CoordinateX_m / 20.0) * 20.0 + 20.0 AS VARCHAR(10)) + 'm' AS [Vùng X],
        CAST(FLOOR(F.CoordinateY_m / 20.0) * 20.0 AS VARCHAR(10)) + 'm - ' + 
        CAST(FLOOR(F.CoordinateY_m / 20.0) * 20.0 + 20.0 AS VARCHAR(10)) + 'm' AS [Vùng Y],
        COUNT(F.FrameID) AS [Mật độ điểm di chuyển],
        CAST(AVG(F.Speed_kmh) AS DECIMAL(6,2)) AS [Vận tốc TB vùng (km/h)],
        CASE 
            WHEN AVG(F.Speed_kmh) < 15.0 THEN N'ĐIỂM NÓNG TẮC NGHẼN (HOTSPOT)'
            ELSE N'KHU VỰC BÌNH THƯỜNG'
        END AS [Cảnh báo giao thông]
    FROM dbo.TRAJECTORY_FRAMES F
    JOIN dbo.VEHICLE_TRACKS T ON F.TrackID = T.TrackID
    WHERE T.RecordingID = @RecordingID
    GROUP BY FLOOR(F.CoordinateX_m / 20.0), FLOOR(F.CoordinateY_m / 20.0)
    ORDER BY [Mật độ điểm di chuyển] DESC, [Vận tốc TB vùng (km/h)] ASC;
END;
GO

-- ===================================================================================
-- 4. STORED PROCEDURE: TÍNH TOÁN VÀ CẬP NHẬT CHỈ SỐ ĐÁNH GIÁ MÔ HÌNH DỰ BÁO
-- Sử dụng các Scalar UDF đã viết và cập nhật bảng EXPERIMENT_METRICS
-- ===================================================================================
IF OBJECT_ID('dbo.sp_EvaluateAndSaveMetrics', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_EvaluateAndSaveMetrics;
GO

CREATE PROCEDURE dbo.sp_EvaluateAndSaveMetrics
    @ExperimentID INT,
    @MAE_Out DECIMAL(8,4) OUTPUT,
    @RMSE_Out DECIMAL(8,4) OUTPUT,
    @MAPE_Out DECIMAL(6,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Gọi các hàm UDF
    SET @MAE_Out = dbo.fn_CalculateMAE(@ExperimentID);
    SET @RMSE_Out = dbo.fn_CalculateRMSE(@ExperimentID);
    SET @MAPE_Out = dbo.fn_CalculateMAPE(@ExperimentID);

    -- 2. Tính hệ số xác định R2 Score
    DECLARE @R2 DECIMAL(6,4);
    DECLARE @AvgActual DECIMAL(8,2);
    SELECT @AvgActual = AVG(ActualDensity) FROM dbo.FORECAST_RESULTS WHERE ExperimentID = @ExperimentID;

    SELECT @R2 = CASE 
        WHEN SUM(POWER(ActualDensity - @AvgActual, 2)) > 0 
            THEN 1.0 - (SUM(POWER(ActualDensity - PredictedDensity, 2)) / SUM(POWER(ActualDensity - @AvgActual, 2)))
        ELSE 0.0 
    END
    FROM dbo.FORECAST_RESULTS
    WHERE ExperimentID = @ExperimentID;

    -- 3. Cập nhật hoặc thêm mới vào bảng EXPERIMENT_METRICS
    IF EXISTS (SELECT 1 FROM dbo.EXPERIMENT_METRICS WHERE ExperimentID = @ExperimentID)
    BEGIN
        UPDATE dbo.EXPERIMENT_METRICS
        SET MAE = @MAE_Out, RMSE = @RMSE_Out, MAPE = @MAPE_Out, R2_Score = @R2, EvaluatedAt = GETDATE()
        WHERE ExperimentID = @ExperimentID;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.EXPERIMENT_METRICS (ExperimentID, MAE, RMSE, MAPE, R2_Score)
        VALUES (@ExperimentID, @MAE_Out, @RMSE_Out, @MAPE_Out, @R2);
    END;

    PRINT N'==> Đã cập nhật metrics cho ExperimentID ' + CAST(@ExperimentID AS VARCHAR(10)) + 
          N': MAE=' + CAST(@MAE_Out AS VARCHAR(10)) + N', RMSE=' + CAST(@RMSE_Out AS VARCHAR(10));
END;
GO

-- ===================================================================================
-- 5. STORED PROCEDURE: LẤY TỔNG QUAN HỆ THỐNG CHO WEB DASHBOARD (APPLICATION KPIs)
-- ===================================================================================
IF OBJECT_ID('dbo.sp_GetDashboardOverview', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_GetDashboardOverview;
GO

CREATE PROCEDURE dbo.sp_GetDashboardOverview
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        (SELECT COUNT(*) FROM dbo.RECORDINGS) AS TotalRecordings,
        (SELECT COUNT(*) FROM dbo.VEHICLE_TRACKS) AS TotalVehiclesTracked,
        (SELECT COUNT(*) FROM dbo.TRAJECTORY_FRAMES) AS TotalTrajectoryPoints,
        (SELECT COUNT(*) FROM dbo.EXPERIMENTS) AS TotalExperimentsRun,
        (SELECT TOP 1 Density_veh_per_km FROM dbo.TRAFFIC_TIME_SERIES ORDER BY WindowTimestamp DESC) AS LatestDensity,
        (SELECT TOP 1 AvgSpeed_kmh FROM dbo.TRAFFIC_TIME_SERIES ORDER BY WindowTimestamp DESC) AS LatestSpeed,
        (SELECT TOP 1 CongestionLevel FROM dbo.TRAFFIC_TIME_SERIES ORDER BY WindowTimestamp DESC) AS LatestCongestionStatus;
END;
GO

PRINT N'==> Đã khởi tạo hoàn tất 5 Stored Procedures nghiệp vụ!';
GO
