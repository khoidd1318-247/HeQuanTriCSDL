
/*
    Module 2: Traffic Pattern Analysis
    File: 04_density_hotspots.sql

    Purpose:
    Identify potential traffic congestion hotspots.

    Demo thresholds:
    - At least 3 distinct vehicles in 5 minutes.
    - Average valid speed is 20 km/h or lower.

    NOTE:
    This identifies potential congestion, not physical
    traffic density measured in vehicles per kilometer.
*/

-- STEP 1: Use the shared project database.
USE UAV_TrafficDB;
GO

-- STEP 2: Create or update the congestion hotspot view.
CREATE OR ALTER VIEW dbo.vw_TrafficCongestionHotspots
AS
SELECT
    f.DatasetVersionID,
    f.RoadSegmentID,
    b.RoadSegmentName,
    f.IntervalStart,
    f.ObservedVehicleCount,
    s.AverageSpeedKmh,
    s.ValidSpeedCount,
    b.SegmentLengthKm,

    N'Potential congestion' AS CongestionStatus

FROM dbo.vw_TrafficFlow5Min AS f

INNER JOIN dbo.vw_TrafficSpeed5Min AS s
    ON f.DatasetVersionID = s.DatasetVersionID
   AND f.RoadSegmentID = s.RoadSegmentID
   AND f.IntervalStart = s.IntervalStart

INNER JOIN (
    SELECT DISTINCT
        RoadSegmentID,
        RoadSegmentName,
        SegmentLengthKm
    FROM dbo.vw_TrafficAnalysisBase
) AS b
    ON f.RoadSegmentID = b.RoadSegmentID

WHERE f.ObservedVehicleCount >= 3
  AND s.ValidSpeedCount > 0
  AND s.AverageSpeedKmh <= 20;
GO

-- STEP 3: Verify that the view exists.
IF OBJECT_ID(N'dbo.vw_TrafficCongestionHotspots', N'V') IS NOT NULL
    PRINT N'vw_TrafficCongestionHotspots created successfully.';
ELSE
    PRINT N'View creation failed.';
GO

-- STEP 4: Display potential congestion hotspots.
SELECT *
FROM dbo.vw_TrafficCongestionHotspots
ORDER BY IntervalStart, RoadSegmentID;
GO
