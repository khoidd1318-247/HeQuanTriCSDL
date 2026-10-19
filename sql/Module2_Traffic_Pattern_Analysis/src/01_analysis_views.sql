
/*
    File: 01_analysis_views.sql
    Purpose: Create a reusable view for traffic analysis.
*/

USE TrafficPatternDemoDB;
GO

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

-- Test the view.
SELECT *
FROM dbo.vw_TrafficAnalysisBase
ORDER BY ObservedAt, RoadSegmentID;
GO
