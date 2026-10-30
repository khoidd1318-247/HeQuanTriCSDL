
/*
    File: 05_analysis_procedures.sql
    Purpose: Query traffic analysis for a selected time range.
*/

USE UAV_TrafficDB;
GO

CREATE OR ALTER PROCEDURE dbo.usp_TrafficPatternSummary
    @StartTime DATETIME2(0),
    @EndTime DATETIME2(0),
    @RoadSegmentID VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @StartTime >= @EndTime
    BEGIN
        THROW 50001,
              'StartTime must be earlier than EndTime.',
              1;
    END;

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
        SELECT DISTINCT RoadSegmentID, RoadSegmentName
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
    ORDER BY f.IntervalStart, f.RoadSegmentID;
END;
GO

-- Example 1: query all road segments.
EXEC dbo.usp_TrafficPatternSummary
    @StartTime = '2026-10-19T08:00:00',
    @EndTime = '2026-10-19T08:10:00';

-- Example 2: query only R02.
EXEC dbo.usp_TrafficPatternSummary
    @StartTime = '2026-10-19T08:00:00',
    @EndTime = '2026-10-19T08:10:00',
    @RoadSegmentID = 'R02';
GO
