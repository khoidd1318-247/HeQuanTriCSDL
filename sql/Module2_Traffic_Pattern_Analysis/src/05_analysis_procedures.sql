
/*
    Module 2: Traffic Pattern Analysis
    File: 05_analysis_procedures.sql

    Purpose:
    Query traffic analysis for a selected time range.
*/

-- STEP 1: Use the shared project database.
USE UAV_TrafficDB;
GO

-- STEP 2: Create or update the stored procedure.
CREATE OR ALTER PROCEDURE dbo.usp_TrafficPatternSummary
    @StartTime DATETIME2(0),
    @EndTime DATETIME2(0),
    @RoadSegmentID VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate input parameters.
    IF @StartTime IS NULL OR @EndTime IS NULL
    BEGIN
        THROW 50001,
              'StartTime and EndTime cannot be NULL.',
              1;
    END;

    IF @StartTime >= @EndTime
    BEGIN
        THROW 50002,
              'StartTime must be earlier than EndTime.',
              1;
    END;

    -- Query traffic pattern summary.
    SELECT
        f.DatasetVersionID,
        f.RoadSegmentID,
        b.RoadSegmentName,
        f.IntervalStart,
        f.ObservedVehicleCount,
        f.ObservationCount,
        s.ValidSpeedCount,
        s.InvalidSpeedCount,
        s.AverageSpeedKmh,
        s.MinimumSpeedKmh,
        s.MaximumSpeedKmh,

        CASE
            WHEN h.RoadSegmentID IS NOT NULL
                THEN N'Potential congestion'
            ELSE N'No demo threshold triggered'
        END AS CongestionStatus

    FROM dbo.vw_TrafficFlow5Min AS f

    INNER JOIN dbo.vw_TrafficSpeed5Min AS s
        ON f.DatasetVersionID = s.DatasetVersionID
       AND f.RoadSegmentID = s.RoadSegmentID
       AND f.IntervalStart = s.IntervalStart

    INNER JOIN (
        SELECT DISTINCT
            RoadSegmentID,
            RoadSegmentName
        FROM dbo.vw_TrafficAnalysisBase
    ) AS b
        ON f.RoadSegmentID = b.RoadSegmentID

    LEFT JOIN dbo.vw_TrafficCongestionHotspots AS h
        ON f.DatasetVersionID = h.DatasetVersionID
       AND f.RoadSegmentID = h.RoadSegmentID
       AND f.IntervalStart = h.IntervalStart

    WHERE f.IntervalStart >= @StartTime
      AND f.IntervalStart < @EndTime
      AND (
          @RoadSegmentID IS NULL
          OR f.RoadSegmentID = @RoadSegmentID
      )

    ORDER BY
        f.IntervalStart,
        f.RoadSegmentID;
END;
GO

-- STEP 3: Verify stored procedure creation.
IF OBJECT_ID(N'dbo.usp_TrafficPatternSummary', N'P') IS NOT NULL
    PRINT N'usp_TrafficPatternSummary created successfully.';
ELSE
    PRINT N'Stored procedure creation failed.';
GO

-- STEP 4: Test Example 1 - Query all road segments.
EXEC dbo.usp_TrafficPatternSummary
    @StartTime = '2026-10-19T08:00:00',
    @EndTime = '2026-10-19T08:10:00';
GO

-- STEP 5: Test Example 2 - Query only road segment R02.
EXEC dbo.usp_TrafficPatternSummary
    @StartTime = '2026-10-19T08:00:00',
    @EndTime = '2026-10-19T08:10:00',
    @RoadSegmentID = 'R02';
GO
