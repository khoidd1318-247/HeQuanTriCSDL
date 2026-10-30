-- ===================================================================================
-- ĐỒ ÁN MÔN HỌC: HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU
-- ĐỀ TÀI: Phân tích mô hình giao thông đô thị và dự báo ùn tắc ngắn hạn sử dụng dữ liệu UAV
-- HỆ QUẢN TRỊ: Microsoft SQL Server (Transact-SQL)
-- TÁC GIẢ: Dương Đình Khôi & Nhóm nghiên cứu
-- FILE 05: ĐỊNH NGHĨA CÁC TRIGGER (RÀNG BUỘC TỰ ĐỘNG & NHẬT KÝ HỆ THỐNG AUDIT TRAIL)
-- ===================================================================================

USE UAV_TrafficDB;
GO

-- ===================================================================================
-- 1. TRIGGER: TỰ ĐỘNG CẬP NHẬT TỔNG SỐ XE TRONG RECORDINGS VÀ GHI AUDIT LOG
-- Kỹ thuật: AFTER INSERT, DELETE trên bảng VEHICLE_TRACKS
-- ===================================================================================
IF OBJECT_ID('dbo.trg_AfterVehicleTracks_Change', 'TR') IS NOT NULL 
    DROP TRIGGER dbo.trg_AfterVehicleTracks_Change;
GO

CREATE TRIGGER dbo.trg_AfterVehicleTracks_Change
ON dbo.VEHICLE_TRACKS
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Cập nhật lại tổng số xe (TotalVehicles) trong bảng RECORDINGS
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        UPDATE R
        SET TotalVehicles = (SELECT COUNT(*) FROM dbo.VEHICLE_TRACKS T WHERE T.RecordingID = R.RecordingID)
        FROM dbo.RECORDINGS R
        JOIN inserted I ON R.RecordingID = I.RecordingID;

        -- Ghi log thêm mới phương tiện
        INSERT INTO dbo.AUDIT_LOGS (ActionType, TargetTable, RecordKey, Description)
        SELECT 'INSERT', 'VEHICLE_TRACKS', CAST(I.TrackID AS VARCHAR(20)),
               N'Thêm mới phương tiện: ' + I.VehicleType + N' vào đợt bay ' + I.RecordingID
        FROM inserted I;
    END

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE R
        SET TotalVehicles = (SELECT COUNT(*) FROM dbo.VEHICLE_TRACKS T WHERE T.RecordingID = R.RecordingID)
        FROM dbo.RECORDINGS R
        JOIN deleted D ON R.RecordingID = D.RecordingID;

        -- Ghi log xóa phương tiện
        INSERT INTO dbo.AUDIT_LOGS (ActionType, TargetTable, RecordKey, Description)
        SELECT 'DELETE', 'VEHICLE_TRACKS', CAST(D.TrackID AS VARCHAR(20)),
               N'Xóa phương tiện TrackID: ' + CAST(D.TrackID AS VARCHAR(20)) + N' khỏi đợt bay ' + D.RecordingID
        FROM deleted D;
    END
END;
GO

-- ===================================================================================
-- 2. TRIGGER: BẢO VỆ DỮ LIỆU TỌA ĐỘ VÀ CẢNH BÁO VẬN TỐC BẤT THƯỜNG
-- Kỹ thuật: AFTER INSERT trên bảng TRAJECTORY_FRAMES
-- ===================================================================================
IF OBJECT_ID('dbo.trg_CheckAbnormalTrajectorySpeed', 'TR') IS NOT NULL 
    DROP TRIGGER dbo.trg_CheckAbnormalTrajectorySpeed;
GO

CREATE TRIGGER dbo.trg_CheckAbnormalTrajectorySpeed
ON dbo.TRAJECTORY_FRAMES
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra nếu có bản ghi vận tốc vượt quá 120 km/h (bất thường đối với giao thông đô thị)
    IF EXISTS (SELECT 1 FROM inserted WHERE Speed_kmh > 120.0)
    BEGIN
        INSERT INTO dbo.AUDIT_LOGS (ActionType, TargetTable, RecordKey, Description)
        SELECT 'ALERT_ANOMALY', 'TRAJECTORY_FRAMES', CAST(I.FrameID AS VARCHAR(20)),
               N'CẢNH BÁO: Phát hiện vận tốc bất thường trong đô thị (' + CAST(I.Speed_kmh AS NVARCHAR(10)) + N' km/h) tại tọa độ X=' + CAST(I.CoordinateX_m AS NVARCHAR(10))
        FROM inserted I
        WHERE I.Speed_kmh > 120.0;
    END
END;
GO

-- ===================================================================================
-- 3. TRIGGER: TỰ ĐỘNG GHI NHẬT KÝ THỰC THI THỰC NGHIỆM DỰ BÁO
-- Kỹ thuật: AFTER INSERT trên bảng EXPERIMENTS
-- ===================================================================================
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
           N'Khởi tạo phiên thực nghiệm dự báo [' + I.ExperimentName + N'] - Thuật toán: ' + I.ModelAlgorithm + N', Cửa sổ: ' + I.AggregationWindow
    FROM inserted I;
END;
GO

PRINT N'==> Đã khởi tạo hoàn tất 3 Triggers tự động hóa & Audit Trail!';
GO
