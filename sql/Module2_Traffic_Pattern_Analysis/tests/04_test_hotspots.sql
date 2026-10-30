
/*
    Test 04: Potential congestion hotspots
*/

USE UAV_TrafficDB;
GO

IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficCongestionHotspots
    WHERE ObservedVehicleCount < 3
       OR AverageSpeedKmh > 20
       OR AverageSpeedKmh IS NULL
)
BEGIN
    THROW 51007, 'FAIL: Hotspot does not meet demo criteria.', 1;
END;

PRINT 'PASS: Hotspot tests completed.';

SELECT *
FROM dbo.vw_TrafficCongestionHotspots
ORDER BY IntervalStart, RoadSegmentID;
GO
