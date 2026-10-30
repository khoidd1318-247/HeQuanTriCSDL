
/*
    Module 2: Traffic Pattern Analysis
    File: 00_demo_schema.sql

    Purpose:
    1. Create a separate demo database.
    2. Create road segment and traffic observation tables.
    3. Insert sample data for testing analysis queries.

    IMPORTANT:
    This is a demo environment, not the official project schema.
*/

-- Step 1: Create the demo database if it does not exist.
IF DB_ID(N'UAV_TrafficDB') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE UAV_TrafficDB');
END;
GO

-- Step 2: Use the demo database.
USE UAV_TrafficDB;
GO

-- Step 3: Create the road segments table.
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
            CHECK (SegmentLengthKm IS NULL OR SegmentLengthKm > 0)
    );
END;
GO

-- Step 4: Create the traffic observations table.
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
            REFERENCES dbo.RoadSegments(RoadSegmentID)
    );
END;
GO

-- Step 5: Insert demo road segments if the table is empty.
IF NOT EXISTS (SELECT 1 FROM dbo.RoadSegments)
BEGIN
    INSERT INTO dbo.RoadSegments
        (RoadSegmentID, RoadSegmentName, SegmentLengthKm)
    VALUES
        ('R01', N'Road Segment 01', 0.500),
        ('R02', N'Road Segment 02', 0.800),
        ('R03', N'Road Segment 03', 1.200);
END;
GO

-- Step 6: Insert demo traffic observations if the table is empty.
IF NOT EXISTS (SELECT 1 FROM dbo.TrafficRecords)
BEGIN
    INSERT INTO dbo.TrafficRecords
        (DatasetVersionID, VehicleID, ObservedAt,
         RoadSegmentID, SpeedKmh)
    VALUES
        -- Road segment R01: relatively normal speeds.
        (1, 'V001', '2026-10-19T08:00:10', 'R01', 42.00),
        (1, 'V002', '2026-10-19T08:01:10', 'R01', 38.00),
        (1, 'V003', '2026-10-19T08:03:10', 'R01', 45.00),

        -- Road segment R02: multiple vehicles at low speeds.
        (1, 'V011', '2026-10-19T08:00:10', 'R02', 12.00),
        (1, 'V012', '2026-10-19T08:01:10', 'R02', 15.00),
        (1, 'V013', '2026-10-19T08:02:10', 'R02', 10.00),
        (1, 'V014', '2026-10-19T08:04:10', 'R02', 18.00),

        -- Road segment R03: relatively normal speeds.
        (1, 'V021', '2026-10-19T08:00:10', 'R03', 50.00),
        (1, 'V022', '2026-10-19T08:02:10', 'R03', 48.00),

        -- A later interval for comparison.
        (1, 'V031', '2026-10-19T08:06:10', 'R02', 35.00),
        (1, 'V032', '2026-10-19T08:07:10', 'R02', 40.00);
END;
GO

-- Step 7: Verify the demo data.
SELECT *
FROM dbo.RoadSegments;

SELECT *
FROM dbo.TrafficRecords
ORDER BY ObservedAt, RoadSegmentID;
GO
