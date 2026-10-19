
/*
    Test 01: Base analysis view
    Run after src/00_demo_schema.sql
    and src/01_analysis_views.sql.
*/

USE TrafficPatternDemoDB;
GO

-- Test 1: Check whether the view returns records.
IF NOT EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficAnalysisBase
)
BEGIN
    THROW 51001, 'FAIL: Base analysis view is empty.', 1;
END;

-- Test 2: Check for missing road names after the join.
IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficAnalysisBase
    WHERE RoadSegmentName IS NULL
)
BEGIN
    THROW 51002, 'FAIL: A road name is missing.', 1;
END;

PRINT 'PASS: Base analysis view tests completed.';

SELECT TOP (10) *
FROM dbo.vw_TrafficAnalysisBase
ORDER BY ObservedAt, RoadSegmentID;
GO
