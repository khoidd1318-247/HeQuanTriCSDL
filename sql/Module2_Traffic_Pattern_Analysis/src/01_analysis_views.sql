
/*
    Module 2: Traffic Pattern Analysis
    File: 01_analysis_views.sql

    Purpose:
    Create a reusable view for traffic analysis.
*/

-- STEP 1: Use the shared database.
USE UAV_TrafficDB;
GO

-- STEP 2: Create or update the analysis view.
CREATE OR ALTER VIEW dbo.vw_TrafficAnalysisBase
AS
SELECT
    tr.RecordID,
    tr.DatasetVersionID,
    tr.VehicleID,
    tr.ObservedAt,
    tr.RoadSegmentID,
    rs.RoadSegmentName,
    rs.SegmentLengthKm,
    tr.SpeedKmh
FROM dbo.TrafficRecords AS tr
INNER JOIN dbo.RoadSegments AS rs
    ON tr.RoadSegmentID = rs.RoadSegmentID;
GO

-- STEP 3: Verify that the view exists.
IF OBJECT_ID(N'dbo.vw_TrafficAnalysisBase', N'V') IS NOT NULL
    PRINT N'vw_TrafficAnalysisBase created successfully.';
ELSE
    PRINT N'View creation failed.';
GO

-- STEP 4: Test the view.
SELECT *
FROM dbo.vw_TrafficAnalysisBase
ORDER BY ObservedAt, RoadSegmentID;
GO
