
/*
    Test 03: Average speed statistics
    Database: UAV_TrafficDB
    Demo valid speed range: 0 to 200 km/h.
*/

USE UAV_TrafficDB;
GO

PRINT '===== TEST 03: AVERAGE SPEED STATISTICS =====';

-- 1. Check whether the view exists
IF OBJECT_ID('dbo.vw_TrafficSpeed5Min', 'V') IS NULL
BEGIN
    THROW 51001, 'FAIL: vw_TrafficSpeed5Min does not exist.', 1;
END;

PRINT 'PASS: Average speed view exists.';


-- 2. Check source data
DECLARE @SourceCount BIGINT;
DECLARE @ViewCount BIGINT;

SELECT @SourceCount = COUNT_BIG(*)
FROM dbo.TrafficRecords;

SELECT @ViewCount = COUNT_BIG(*)
FROM dbo.vw_TrafficSpeed5Min;

IF @SourceCount = 0
BEGIN
    PRINT 'WARNING: TrafficRecords is empty. No average speed data available.';
END
ELSE IF @ViewCount = 0
BEGIN
    THROW 51002, 'FAIL: Source has data but average speed view is empty.', 1;
END
ELSE
BEGIN
    PRINT 'PASS: Average speed view contains data.';
END;


-- 3. Check speed counts are not negative
IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficSpeed5Min
    WHERE ValidSpeedCount < 0
       OR InvalidSpeedCount < 0
       OR ObservationCount < 0
)
BEGIN
    THROW 51003, 'FAIL: Speed counts cannot be negative.', 1;
END;

PRINT 'PASS: Speed counts are non-negative.';


-- 4. Check valid and invalid counts match total observations
IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficSpeed5Min
    WHERE ValidSpeedCount + InvalidSpeedCount <> ObservationCount
)
BEGIN
    THROW 51004, 'FAIL: Speed counts do not match observations.', 1;
END;

PRINT 'PASS: Speed counts match total observations.';


-- 5. Check average, minimum and maximum speed
IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficSpeed5Min
    WHERE
        (
            ValidSpeedCount = 0
            AND (
                AverageSpeedKmh IS NOT NULL
                OR MinimumSpeedKmh IS NOT NULL
                OR MaximumSpeedKmh IS NOT NULL
            )
        )
        OR
        (
            ValidSpeedCount > 0
            AND (
                AverageSpeedKmh IS NULL
                OR MinimumSpeedKmh IS NULL
                OR MaximumSpeedKmh IS NULL
                OR MinimumSpeedKmh < 0
                OR MaximumSpeedKmh > 200
                OR MinimumSpeedKmh > MaximumSpeedKmh
                OR AverageSpeedKmh < MinimumSpeedKmh
                OR AverageSpeedKmh > MaximumSpeedKmh
            )
        )
)
BEGIN
    THROW 51005, 'FAIL: Average, minimum or maximum speed is inconsistent.', 1;
END;

PRINT 'PASS: Average, minimum and maximum speeds are consistent.';


-- 6. Display average speed statistics
SELECT *
FROM dbo.vw_TrafficSpeed5Min
ORDER BY IntervalStart, RoadSegmentID;

PRINT '===== TEST 03 COMPLETED =====';
GO
