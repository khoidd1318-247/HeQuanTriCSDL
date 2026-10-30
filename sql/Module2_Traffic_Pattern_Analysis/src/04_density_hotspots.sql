
/*
    File: 04_density_hotspots.sql
    Purpose: Identify potential congestion hotspots.

    Demo thresholds:
    - At least 3 distinct observed vehicles in 5 minutes.
    - Average valid speed is 20 km/h or lower.
*/

USE UAV_TrafficDB;
GO

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
  AND s.AverageSpeedKmh <= 20;
GO

SELECT *
FROM dbo.vw_TrafficCongestionHotspots
ORDER BY IntervalStart, RoadSegmentID;
GO
