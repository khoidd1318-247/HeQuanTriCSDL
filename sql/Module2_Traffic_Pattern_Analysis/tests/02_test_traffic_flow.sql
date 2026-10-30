
/*
    Test 02: Traffic flow aggregation
*/

USE UAV_TrafficDB;
GO

IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficFlow5Min
    WHERE ObservedVehicleCount < 0
       OR ObservationCount < 0
)
BEGIN
    THROW 51003, 'FAIL: Negative traffic counts found.', 1;
END;

IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficFlow5Min
    WHERE DATEPART(MINUTE, IntervalStart) % 5 <> 0
)
BEGIN
    THROW 51004, 'FAIL: An interval is not aligned to 5 minutes.', 1;
END;

PRINT 'PASS: Traffic flow tests completed.';

SELECT *
FROM dbo.vw_TrafficFlow5Min
ORDER BY IntervalStart, RoadSegmentID;
GO
