
/*
    Module 2: Traffic Pattern Analysis
    File: 02_traffic_flow.sql

    Purpose:
    Aggregate distinct observed vehicles into 5-minute intervals.
*/

-- STEP 1: Use the shared project database.
USE UAV_TrafficDB;
GO

-- STEP 2: Create or update the 5-minute traffic flow view.
CREATE OR ALTER VIEW dbo.vw_TrafficFlow5Min
AS
SELECT
    DatasetVersionID,
    RoadSegmentID,

    -- Calculate the beginning of each 5-minute interval.
    DATEADD(
        MINUTE,
        (DATEDIFF(MINUTE, 0, ObservedAt) / 5) * 5,
        0
    ) AS IntervalStart,

    -- Count distinct vehicles in each interval.
    COUNT(DISTINCT VehicleID) AS ObservedVehicleCount,

    -- Count all traffic observations in each interval.
    COUNT_BIG(*) AS ObservationCount

FROM dbo.vw_TrafficAnalysisBase

GROUP BY
    DatasetVersionID,
    RoadSegmentID,
    DATEADD(
        MINUTE,
        (DATEDIFF(MINUTE, 0, ObservedAt) / 5) * 5,
        0
    );
GO

-- STEP 3: Verify that the view exists.
IF OBJECT_ID(N'dbo.vw_TrafficFlow5Min', N'V') IS NOT NULL
    PRINT N'vw_TrafficFlow5Min created successfully.';
ELSE
    PRINT N'View creation failed.';
GO

-- STEP 4: Display traffic flow analysis results.
SELECT *
FROM dbo.vw_TrafficFlow5Min
ORDER BY IntervalStart, RoadSegmentID;
GO
