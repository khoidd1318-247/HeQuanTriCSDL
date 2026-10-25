
USE UAV_TrafficDB;
GO

IF OBJECT_ID('dbo.RecordImportResult', 'P') IS NOT NULL
    DROP PROCEDURE dbo.RecordImportResult;
GO

CREATE PROCEDURE dbo.RecordImportResult
    @VersionID INT = NULL,
    @FileName NVARCHAR(255),
    @ImportStatus NVARCHAR(30),
    @TotalRecords BIGINT = NULL,
    @SuccessfulRecords BIGINT = NULL,
    @FailedRecords BIGINT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ImportLogs (
        VersionID,
        FileName,
        ImportStatus,
        TotalRecords,
        SuccessfulRecords,
        FailedRecords,
        ErrorMessage,
        StartedAt,
        FinishedAt
    )
    VALUES (
        @VersionID,
        @FileName,
        @ImportStatus,
        @TotalRecords,
        @SuccessfulRecords,
        @FailedRecords,
        @ErrorMessage,
        GETDATE(),
        GETDATE()
    );

    SELECT *
    FROM dbo.ImportLogs
    WHERE ImportID = SCOPE_IDENTITY();
END;
GO

-- Kiem tra thu tuc da duoc tao
SELECT name
FROM sys.procedures
WHERE name = 'RecordImportResult';
GO

