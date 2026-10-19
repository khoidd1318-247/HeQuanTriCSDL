
/*
    File: 02_traffic_flow.sql
    Purpose: Aggregate observed vehicles into 5-minute intervals.
*/

USE TrafficPatternDemoDB;
GO

CREATE OR ALTER VIEW dbo.vw_TrafficFlow5Min
AS
SELECT
    DatasetVersionID,
    RoadSegmentID,
    DATEADD(
        MINUTE,
        (DATEDIFF(MINUTE, 0, ObservedAt) / 5) * 5,
        0
    ) AS IntervalStart,
    COUNT(DISTINCT VehicleID) AS ObservedVehicleCount,
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

SELECT *
FROM dbo.vw_TrafficFlow5Min
ORDER BY IntervalStart, RoadSegmentID;
GO
