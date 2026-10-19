
/*
    Test 03: Average speed statistics
    Demo valid range: 0 to 200 km/h.
*/

USE TrafficPatternDemoDB;
GO

IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficSpeed5Min
    WHERE AverageSpeedKmh < 0
       OR AverageSpeedKmh > 200
)
BEGIN
    THROW 51005, 'FAIL: Average speed is outside demo limits.', 1;
END;

IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficSpeed5Min
    WHERE ValidSpeedCount + InvalidSpeedCount <> ObservationCount
)
BEGIN
    THROW 51006, 'FAIL: Speed counts do not match observations.', 1;
END;

PRINT 'PASS: Average speed tests completed.';

SELECT *
FROM dbo.vw_TrafficSpeed5Min
ORDER BY IntervalStart, RoadSegmentID;
GO
