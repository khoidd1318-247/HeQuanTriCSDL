
/*
    Module 2: Traffic Pattern Analysis
    Test 01: Base analysis view

    Purpose:
    - Check whether the base analysis view exists.
    - Check whether the view returns expected records.
    - Check for missing road names.
    - Compare view results with source table JOIN results.

    Run after:
    src/00_demo_schema.sql
    src/01_analysis_views.sql
*/

USE UAV_TrafficDB;
GO

PRINT N'===== TEST 01: BASE ANALYSIS VIEW =====';
GO

-- TEST 1: Check whether the view exists.
IF OBJECT_ID(N'dbo.vw_TrafficAnalysisBase', N'V') IS NULL
BEGIN
    THROW 51001,
          'FAIL: vw_TrafficAnalysisBase does not exist.',
          1;
END;

PRINT N'PASS: Base analysis view exists.';
GO

-- TEST 2: Check whether source tables contain records.
DECLARE @SourceRecordCount BIGINT;
DECLARE @ViewRecordCount BIGINT;

SELECT @SourceRecordCount = COUNT_BIG(*)
FROM dbo.TrafficRecords;

SELECT @ViewRecordCount = COUNT_BIG(*)
FROM dbo.vw_TrafficAnalysisBase;

IF @SourceRecordCount = 0
BEGIN
    PRINT N'WARNING: TrafficRecords is empty. No data available for analysis.';
END
ELSE IF @ViewRecordCount = 0
BEGIN
    THROW 51002,
          'FAIL: Source records exist but the base analysis view is empty.',
          1;
END
ELSE
BEGIN
    PRINT N'PASS: Base analysis view returns records.';
END;
GO

-- TEST 3: Check for missing road names.
IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficAnalysisBase
    WHERE RoadSegmentName IS NULL
)
BEGIN
    THROW 51003,
          'FAIL: A road name is missing.',
          1;
END;

PRINT N'PASS: No missing road names found.';
GO

-- TEST 4: Compare view results with source table JOIN results.
DECLARE @ExpectedCount BIGINT;
DECLARE @ActualCount BIGINT;

SELECT @ExpectedCount = COUNT_BIG(*)
FROM dbo.TrafficRecords AS tr
INNER JOIN dbo.RoadSegments AS rs
    ON tr.RoadSegmentID = rs.RoadSegmentID;

SELECT @ActualCount = COUNT_BIG(*)
FROM dbo.vw_TrafficAnalysisBase;

IF @ExpectedCount <> @ActualCount
BEGIN
    THROW 51004,
          'FAIL: View record count does not match source JOIN result.',
          1;
END;

PRINT N'PASS: View record count matches source JOIN result.';
GO

-- TEST 5: Display sample analysis records.
SELECT TOP (10) *
FROM dbo.vw_TrafficAnalysisBase
ORDER BY ObservedAt, RoadSegmentID;
GO

PRINT N'===== TEST 01 COMPLETED =====';
GO
