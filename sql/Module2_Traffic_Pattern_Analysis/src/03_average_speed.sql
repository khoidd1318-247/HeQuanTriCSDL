
/*
    File: 03_average_speed.sql
    Purpose: Calculate speed statistics for each 5-minute interval.

    Demo rule: speeds from 0 to 200 km/h are considered plausible.
    Adjust this rule after the real dataset is confirmed.
*/

USE TrafficPatternDemoDB;
GO

CREATE OR ALTER VIEW dbo.vw_TrafficSpeed5Min
AS
SELECT
    DatasetVersionID,
    RoadSegmentID,
    DATEADD(
        MINUTE,
        (DATEDIFF(MINUTE, 0, ObservedAt) / 5) * 5,
        0
    ) AS IntervalStart,
    COUNT_BIG(*) AS ObservationCount,
    SUM(
        CASE
            WHEN SpeedKmh BETWEEN 0 AND 200 THEN 1
            ELSE 0
        END
    ) AS ValidSpeedCount,
    SUM(
        CASE
            WHEN SpeedKmh IS NULL
              OR SpeedKmh < 0
              OR SpeedKmh > 200
            THEN 1
            ELSE 0
        END
    ) AS InvalidSpeedCount,
    AVG(
        CASE
            WHEN SpeedKmh BETWEEN 0 AND 200 THEN SpeedKmh
            ELSE NULL
        END
    ) AS AverageSpeedKmh,
    MIN(
        CASE
            WHEN SpeedKmh BETWEEN 0 AND 200 THEN SpeedKmh
            ELSE NULL
        END
    ) AS MinimumSpeedKmh,
    MAX(
        CASE
            WHEN SpeedKmh BETWEEN 0 AND 200 THEN SpeedKmh
            ELSE NULL
        END
    ) AS MaximumSpeedKmh
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
FROM dbo.vw_TrafficSpeed5Min
ORDER BY IntervalStart, RoadSegmentID;
GO
