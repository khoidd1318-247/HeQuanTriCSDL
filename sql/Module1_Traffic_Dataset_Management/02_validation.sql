
USE UAV_TrafficDB;
GO

-- 1. Kiem tra tap du lieu chua co ten
SELECT *
FROM dbo.Datasets
WHERE DatasetName IS NULL
   OR LTRIM(RTRIM(DatasetName)) = '';
GO

-- 2. Kiem tra phien ban khong co tap du lieu tuong ung
SELECT v.*
FROM dbo.DatasetVersions AS v
LEFT JOIN dbo.Datasets AS d
    ON v.DatasetID = d.DatasetID
WHERE d.DatasetID IS NULL;
GO

-- 3. Thong ke so phien ban theo tap du lieu
SELECT
    d.DatasetID,
    d.DatasetName,
    COUNT(v.VersionID) AS TotalVersions
FROM dbo.Datasets AS d
LEFT JOIN dbo.DatasetVersions AS v
    ON d.DatasetID = v.DatasetID
GROUP BY d.DatasetID, d.DatasetName
ORDER BY d.DatasetID;
GO

-- 4. Kiem tra lich su nhap du lieu
SELECT
    ImportID,
    FileName,
    ImportStatus,
    TotalRecords,
    SuccessfulRecords,
    FailedRecords,
    StartedAt
FROM dbo.ImportLogs
ORDER BY StartedAt DESC;
GO

-- 5. Xem cac bao cao kiem tra chat luong
SELECT
    ReportID,
    VersionID,
    CheckName,
    TotalRecords,
    InvalidRecords,
    CheckStatus,
    CheckedAt
FROM dbo.ValidationReports
ORDER BY CheckedAt DESC;
GO

