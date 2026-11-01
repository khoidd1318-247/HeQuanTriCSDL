
/*
    Module 2: Traffic Pattern Analysis
    File: 03_average_speed.sql

    Purpose:
    Calculate speed statistics for each 5-minute interval.

    Demo rule:
    Speeds from 0 to 200 km/h are considered plausible.
*/

-- STEP 1: Use the shared project database.
USE UAV_TrafficDB;
GO

-- STEP 2: Create or update the traffic speed analysis view.
CREATE OR ALTER VIEW dbo.vw_TrafficSpeed5Min
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

    -- Total number of observations.
    COUNT_BIG(*) AS ObservationCount,

    -- Number of valid speed observations.
    SUM(
        CAST(
            CASE
                WHEN SpeedKmh BETWEEN 0 AND 200 THEN 1
                ELSE 0
            END AS BIGINT
        )
    ) AS ValidSpeedCount,

    -- Number of invalid or missing speed observations.
    SUM(
        CAST(
            CASE
                WHEN SpeedKmh IS NULL
                  OR SpeedKmh < 0
                  OR SpeedKmh > 200
                THEN 1
                ELSE 0
            END AS BIGINT
        )
    ) AS InvalidSpeedCount,

    -- Average valid speed.
    AVG(
        CASE
            WHEN SpeedKmh BETWEEN 0 AND 200
            THEN SpeedKmh
            ELSE NULL
        END
    ) AS AverageSpeedKmh,

    -- Minimum valid speed.
    MIN(
        CASE
            WHEN SpeedKmh BETWEEN 0 AND 200
            THEN SpeedKmh
            ELSE NULL
        END
    ) AS MinimumSpeedKmh,

    -- Maximum valid speed.
    MAX(
        CASE
            WHEN SpeedKmh BETWEEN 0 AND 200
            THEN SpeedKmh
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

-- STEP 3: Verify that the view exists.
IF OBJECT_ID(N'dbo.vw_TrafficSpeed5Min', N'V') IS NOT NULL
    PRINT N'vw_TrafficSpeed5Min created successfully.';
ELSE
    PRINT N'View creation failed.';
GO

-- STEP 4: Display speed analysis results.
SELECT *
FROM dbo.vw_TrafficSpeed5Min
ORDER BY IntervalStart, RoadSegmentID;
GO
