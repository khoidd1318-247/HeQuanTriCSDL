-- ===================================================================================
-- ĐỒ ÁN MÔN HỌC: HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU
-- ĐỀ TÀI: Phân tích mô hình giao thông đô thị và dự báo ùn tắc ngắn hạn sử dụng dữ liệu UAV
-- HỆ QUẢN TRỊ: Microsoft SQL Server (Transact-SQL)
-- TÁC GIẢ: Dương Đình Khôi & Nhóm nghiên cứu
-- FILE 06: GIAO TÁC (TRANSACTIONS), ĐIỀU KHIỂN TƯƠNG TRANH VÀ MÔ PHỎNG DEADLOCK
-- (Phục vụ trả lời vấn đáp các Chương 2, 3, 4 trong Đề cương chi tiết học phần 121003)
-- ===================================================================================

USE UAV_TrafficDB;
GO

-- ===================================================================================
-- KỊCH BẢN 1: GIAO TÁC AN TOÀN ĐẢM BẢO TÍNH NGUYÊN TỬ (ATOMICITY TRONG ACID)
-- Nghiệp vụ: Thêm mới 1 phương tiện (VEHICLE_TRACKS) và đồng thời thêm các điểm tọa độ (TRAJECTORY_FRAMES)
-- Nếu bất kỳ điểm tọa độ nào bị lỗi, toàn bộ phương tiện phải được ROLLBACK hoàn toàn.
-- ===================================================================================

DECLARE @TargetRecording VARCHAR(20) = 'REC_IND_01';
DECLARE @NewVehicleID INT = 999;
DECLARE @NewTrackID BIGINT;

BEGIN TRY
    BEGIN TRANSACTION SafeInsertVehicleTx;

    PRINT N'-- [BƯỚC 1]: Thêm thông tin phương tiện vào VEHICLE_TRACKS';
    INSERT INTO dbo.VEHICLE_TRACKS 
    (RecordingID, VehicleID_InRec, VehicleType, FirstAppearance, LastAppearance, AvgSpeed_kmh, TotalDistance_m)
    VALUES 
    (@TargetRecording, @NewVehicleID, N'Ô tô con', '2026-10-10 07:15:00', '2026-10-10 07:15:30', 36.5, 300.0);

    -- Lấy TrackID vừa sinh ra tự động
    SET @NewTrackID = SCOPE_IDENTITY();
    PRINT N'==> Đã tạo TrackID: ' + CAST(@NewTrackID AS VARCHAR(20));

    PRINT N'-- [BƯỚC 2]: Thêm các khung hình quỹ đạo (Trajectory Frames)';
    INSERT INTO dbo.TRAJECTORY_FRAMES (TrackID, FrameTimestamp, CoordinateX_m, CoordinateY_m, Speed_kmh)
    VALUES 
    (@NewTrackID, '2026-10-10 07:15:00', 10.5, 50.0, 36.0),
    (@NewTrackID, '2026-10-10 07:15:15', 55.0, 50.5, 37.0);

    -- [BƯỚC 3]: Kiểm tra số dòng thực thi và xác nhận Commit
    IF @@ROWCOUNT > 0
    BEGIN
        COMMIT TRANSACTION SafeInsertVehicleTx;
        PRINT N'==> GIAO TÁC THÀNH CÔNG: Dữ liệu xe và tọa độ đã được COMMIT vào CSDL.';
    END
    ELSE
    BEGIN
        ROLLBACK TRANSACTION SafeInsertVehicleTx;
        PRINT N'==> CẢNH BÁO: Không có dòng nào được thêm. Giao tác đã ROLLBACK.';
    END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION SafeInsertVehicleTx;
        PRINT N'==> LỖI HỆ THỐNG: Giao tác đã tự động ROLLBACK hoàn toàn để bảo vệ toàn vẹn dữ liệu.';
    END

    -- Ghi nhật ký lỗi vào AUDIT_LOGS
    INSERT INTO dbo.AUDIT_LOGS (ActionType, TargetTable, RecordKey, Description)
    VALUES ('TX_ERROR', 'VEHICLE_TRACKS', CAST(@NewVehicleID AS VARCHAR(20)), 
            N'Lỗi giao tác: ' + ERROR_MESSAGE());

    SELECT 
        ERROR_NUMBER() AS [Mã Lỗi],
        ERROR_SEVERITY() AS [Mức độ nghiêm trọng],
        ERROR_STATE() AS [Trạng thái],
        ERROR_MESSAGE() AS [Nội dung lỗi chi tiết];
END CATCH;
GO

-- ===================================================================================
-- KỊCH BẢN 2: THIẾT LẬP MỨC ĐỘ CÔ LẬP (TRANSACTION ISOLATION LEVELS)
-- Khắc phục các vấn đề tương tranh: Dirty Read, Non-repeatable Read, Phantom Read
-- ===================================================================================

-- Thí dụ: Báo cáo phân tích giao thông yêu cầu dữ liệu nhất quán tuyệt đối (Repeatable Read)
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
GO

BEGIN TRANSACTION TrafficAnalysisReportTx;

SELECT 
    RecordingID, 
    COUNT(*) AS TotalVehicles,
    AVG(AvgSpeed_kmh) AS AvgNetworkSpeed
FROM dbo.VEHICLE_TRACKS
GROUP BY RecordingID;

-- Trong suốt thời gian giao dịch này giữ khóa chia sẻ (Shared Locks), 
-- không một transaction nào khác có thể UPDATE dữ liệu của các xe trên.

COMMIT TRANSACTION TrafficAnalysisReportTx;
GO

-- Trả lại mức cô lập mặc định của SQL Server
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO

-- ===================================================================================
-- KỊCH BẢN 3: HƯỚNG DẪN MÔ PHỎNG DEADLOCK CHO THẦY CÔ XEM KHI BẢO VỆ
-- Cách thực hiện: Mở 2 cửa sổ Query trong SSMS và chạy tuần tự
-- ===================================================================================

/*
--- CỬA SỔ 1 (TRANSACTION 1) ---
BEGIN TRAN;
UPDATE dbo.RECORDINGS SET TotalVehicles = TotalVehicles + 1 WHERE RecordingID = 'REC_IND_01';
-- Giữ khóa độc quyền trên RECORDINGS, sau đó chờ 5 giây
WAITFOR DELAY '00:00:05';
-- Cố gắng khóa bảng VEHICLE_TRACKS
UPDATE dbo.VEHICLE_TRACKS SET AvgSpeed_kmh = AvgSpeed_kmh + 1 WHERE TrackID = 1;
COMMIT TRAN;

--- CỬA SỔ 2 (TRANSACTION 2) ---
BEGIN TRAN;
UPDATE dbo.VEHICLE_TRACKS SET AvgSpeed_kmh = AvgSpeed_kmh + 2 WHERE TrackID = 1;
-- Giữ khóa độc quyền trên VEHICLE_TRACKS, sau đó chờ 5 giây
WAITFOR DELAY '00:00:05';
-- Cố gắng khóa bảng RECORDINGS
UPDATE dbo.RECORDINGS SET TotalVehicles = TotalVehicles + 2 WHERE RecordingID = 'REC_IND_01';
COMMIT TRAN;

==> KẾT QUẢ SQL SERVER:
SQL Server Lock Monitor tự động phát hiện chu trình khóa (Wait-For Graph),
chọn một Transaction có chi phí rollback thấp hơn làm "Deadlock Victim" 
và báo lỗi 1205.
*/

PRINT N'==> Đã chuẩn bị sẵn sàng các kịch bản kiểm thử Giao tác và Tương tranh!';
GO
