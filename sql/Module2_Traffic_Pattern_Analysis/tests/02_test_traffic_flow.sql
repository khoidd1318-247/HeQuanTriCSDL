
/*
    Module 2: Traffic Pattern Analysis
    Test 02: Traffic flow aggregation

    Purpose:
    - Check whether the traffic flow view exists.
    - Check traffic count validity.
    - Check 5-minute interval alignment.
    - Verify distinct vehicle counts and observation counts.
*/

USE UAV_TrafficDB;
GO

PRINT N'===== TEST 02: TRAFFIC FLOW AGGREGATION =====';
GO

-- TEST 1: Check whether the view exists.
IF OBJECT_ID(N'dbo.vw_TrafficFlow5Min', N'V') IS NULL
BEGIN
    THROW 52001,
          'FAIL: vw_TrafficFlow5Min does not exist.',
          1;
END;

PRINT N'PASS: Traffic flow view exists.';
GO

-- TEST 2: Check whether source data is available.
DECLARE @SourceCount BIGINT;
DECLARE @ViewCount BIGINT;

SELECT @SourceCount = COUNT_BIG(*)
FROM dbo.TrafficRecords;

SELECT @ViewCount = COUNT_BIG(*)
FROM dbo.vw_TrafficFlow5Min;

IF @SourceCount = 0
BEGIN
    PRINT N'WARNING: TrafficRecords is empty. No traffic flow data available.';
END
ELSE IF @ViewCount = 0
BEGIN
    THROW 52002,
          'FAIL: Source records exist but traffic flow view is empty.',
          1;
END
ELSE
BEGIN
    PRINT N'PASS: Traffic flow view returns records.';
END;
GO

-- TEST 3: Check for negative traffic counts.
IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficFlow5Min
    WHERE ObservedVehicleCount < 0
       OR ObservationCount < 0
)
BEGIN
    THROW 52003,
          'FAIL: Negative traffic counts found.',
          1;
END;

PRINT N'PASS: No negative traffic counts found.';
GO

-- TEST 4: Check consistency between observation
-- count and distinct vehicle count.
IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficFlow5Min
    WHERE ObservedVehicleCount > ObservationCount
)
BEGIN
    THROW 52004,
          'FAIL: Distinct vehicle count exceeds observation count.',
          1;
END;

PRINT N'PASS: Vehicle counts are consistent with observation counts.';
GO

-- TEST 5: Check 5-minute interval alignment.
IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficFlow5Min
    WHERE DATEPART(MINUTE, IntervalStart) % 5 <> 0
       OR DATEPART(SECOND, IntervalStart) <> 0
)
BEGIN
    THROW 52005,
          'FAIL: An interval is not aligned to 5 minutes.',
          1;
END;

PRINT N'PASS: All intervals are aligned to 5 minutes.';
GO

-- TEST 6: Verify aggregation against source analysis data.
IF EXISTS (
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
        )

    EXCEPT

    SELECT
        DatasetVersionID,
        RoadSegmentID,
        IntervalStart,
        ObservedVehicleCount,
        ObservationCount
    FROM dbo.vw_TrafficFlow5Min
)
OR EXISTS (
    SELECT
        DatasetVersionID,
        RoadSegmentID,
        IntervalStart,
        ObservedVehicleCount,
        ObservationCount
    FROM dbo.vw_TrafficFlow5Min

    EXCEPT

    SELECT
        DatasetVersionID,
        RoadSegmentID,
        DATEADD(
            MINUTE,
            (DATEDIFF(MINUTE, 0, ObservedAt) / 5) * 5,
            0
        ),
        COUNT(DISTINCT VehicleID),
        COUNT_BIG(*)
    FROM dbo.vw_TrafficAnalysisBase
    GROUP BY
        DatasetVersionID,
        RoadSegmentID,
        DATEADD(
            MINUTE,
            (DATEDIFF(MINUTE, 0, ObservedAt) / 5) * 5,
            0
        )
)
BEGIN
    THROW 52006,
          'FAIL: Traffic flow aggregation does not match source data.',
          1;
END;

PRINT N'PASS: Traffic flow aggregation matches source data.';
GO

-- TEST 7: Display traffic flow results.
SELECT *
FROM dbo.vw_TrafficFlow5Min
ORDER BY IntervalStart, RoadSegmentID;
GO

PRINT N'===== TEST 02 COMPLETED =====';
GO
