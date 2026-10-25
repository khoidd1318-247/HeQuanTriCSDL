
USE UAV_TrafficDB;
GO

-- 1. Bang quan ly tap du lieu
IF OBJECT_ID('dbo.Datasets', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Datasets (
        DatasetID INT IDENTITY(1,1) PRIMARY KEY,
        DatasetName NVARCHAR(200) NOT NULL,
        DatasetSource NVARCHAR(500) NULL,
        Description NVARCHAR(1000) NULL,
        CreatedAt DATETIME NOT NULL
            DEFAULT GETDATE(),
        IsActive BIT NOT NULL
            DEFAULT 1
    );
END;
GO

-- 2. Bang quan ly phien ban tap du lieu
IF OBJECT_ID('dbo.DatasetVersions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DatasetVersions (
        VersionID INT IDENTITY(1,1) PRIMARY KEY,
        DatasetID INT NOT NULL,
        VersionNumber INT NOT NULL,
        FileName NVARCHAR(255) NULL,
        FilePath NVARCHAR(1000) NULL,
        RecordCount BIGINT NULL,
        CreatedAt DATETIME NOT NULL
            DEFAULT GETDATE(),
        Notes NVARCHAR(1000) NULL,

        CONSTRAINT FK_DatasetVersions_Datasets
            FOREIGN KEY (DatasetID)
            REFERENCES dbo.Datasets(DatasetID),

        CONSTRAINT UQ_DatasetVersions
            UNIQUE (DatasetID, VersionNumber)
    );
END;
GO

-- 3. Bang ghi lich su nhap du lieu
IF OBJECT_ID('dbo.ImportLogs', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ImportLogs (
        ImportID INT IDENTITY(1,1) PRIMARY KEY,
        VersionID INT NULL,
        FileName NVARCHAR(255) NOT NULL,
        ImportStatus NVARCHAR(30) NOT NULL
            DEFAULT 'Pending',
        TotalRecords BIGINT NULL,
        SuccessfulRecords BIGINT NULL,
        FailedRecords BIGINT NULL,
        ErrorMessage NVARCHAR(MAX) NULL,
        StartedAt DATETIME NOT NULL
            DEFAULT GETDATE(),
        FinishedAt DATETIME NULL,

        CONSTRAINT FK_ImportLogs_DatasetVersions
            FOREIGN KEY (VersionID)
            REFERENCES dbo.DatasetVersions(VersionID)
    );
END;
GO

-- 4. Bang luu ket qua kiem tra chat luong du lieu
IF OBJECT_ID('dbo.ValidationReports', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ValidationReports (
        ReportID INT IDENTITY(1,1) PRIMARY KEY,
        VersionID INT NOT NULL,
        CheckName NVARCHAR(200) NOT NULL,
        TotalRecords BIGINT NULL,
        InvalidRecords BIGINT NULL,
        CheckStatus NVARCHAR(30) NOT NULL,
        Details NVARCHAR(MAX) NULL,
        CheckedAt DATETIME NOT NULL
            DEFAULT GETDATE(),

        CONSTRAINT FK_ValidationReports_DatasetVersions
            FOREIGN KEY (VersionID)
            REFERENCES dbo.DatasetVersions(VersionID)
    );
END;
GO

-- 5. Kiem tra cac bang da tao
SELECT name AS TableName
FROM sys.tables
WHERE name IN (
    'Datasets',
    'DatasetVersions',
    'ImportLogs',
    'ValidationReports'
)
ORDER BY name;
GO

