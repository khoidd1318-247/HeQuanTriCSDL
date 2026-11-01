
/*
    Module 2: Traffic Pattern Analysis
    File: 00_demo_schema.sql

    Purpose:
    1. Use the shared project database: UAV_TrafficDB.
    2. Create road segment information.
    3. Create traffic observation records.
    4. Link traffic records to Module 1 dataset versions.

    IMPORTANT:
    - Do not create a separate database.
    - Do not insert demo data into the official database.
    - Do not drop or overwrite existing tables.
*/

-- STEP 1: Use the shared project database.
USE UAV_TrafficDB;
GO

-- STEP 2: Check whether Module 1 schema exists.
IF OBJECT_ID(N'dbo.DatasetVersions', N'U') IS NULL
BEGIN
    THROW 50001,
        'Module 1 table dbo.DatasetVersions does not exist. Please run Module 1 schema first.',
        1;
END;
GO

-- STEP 3: Create the road segments table if it does not exist.
IF OBJECT_ID(N'dbo.RoadSegments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RoadSegments
    (
        RoadSegmentID VARCHAR(20) NOT NULL,
        RoadSegmentName NVARCHAR(100) NOT NULL,
        SegmentLengthKm DECIMAL(8,3) NULL,

        CONSTRAINT PK_RoadSegments
            PRIMARY KEY (RoadSegmentID),

        CONSTRAINT CK_RoadSegments_Length
            CHECK (
                SegmentLengthKm IS NULL
                OR SegmentLengthKm > 0
            )
    );
END;
GO

-- STEP 4: Create traffic observation records if the table does not exist.
IF OBJECT_ID(N'dbo.TrafficRecords', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TrafficRecords
    (
        RecordID BIGINT IDENTITY(1,1) NOT NULL,
        DatasetVersionID INT NOT NULL,
        VehicleID VARCHAR(30) NOT NULL,
        ObservedAt DATETIME2(0) NOT NULL,
        RoadSegmentID VARCHAR(20) NOT NULL,
        SpeedKmh DECIMAL(6,2) NULL,

        CONSTRAINT PK_TrafficRecords
            PRIMARY KEY (RecordID),

        CONSTRAINT FK_TrafficRecords_RoadSegments
            FOREIGN KEY (RoadSegmentID)
            REFERENCES dbo.RoadSegments(RoadSegmentID),

        CONSTRAINT FK_TrafficRecords_DatasetVersions
            FOREIGN KEY (DatasetVersionID)
            REFERENCES dbo.DatasetVersions(VersionID),

        CONSTRAINT CK_TrafficRecords_Speed
            CHECK (SpeedKmh IS NULL OR SpeedKmh >= 0)
    );
END;
GO

-- STEP 5: Verify the tables.
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN (
    'DatasetVersions',
    'RoadSegments',
    'TrafficRecords'
)
ORDER BY TABLE_NAME;
GO

-- STEP 6: Verify the table structures.
EXEC sp_help 'dbo.RoadSegments';
EXEC sp_help 'dbo.TrafficRecords';
GO

-- STEP 7: Check the foreign key relationships.
SELECT
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable
FROM sys.foreign_keys AS fk
WHERE fk.parent_object_id IN (
    OBJECT_ID(N'dbo.RoadSegments'),
    OBJECT_ID(N'dbo.TrafficRecords')
);
GO
