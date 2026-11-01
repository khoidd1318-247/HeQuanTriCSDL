
/*
    Test 04: Potential congestion hotspots
    Database: UAV_TrafficDB

    Demo congestion criteria:
    - At least 3 distinct vehicles in 5 minutes.
    - Average valid speed <= 20 km/h.
*/

USE UAV_TrafficDB;
GO

PRINT '===== TEST 04: CONGESTION HOTSPOTS =====';


-- 1. Check whether the hotspot view exists
IF OBJECT_ID('dbo.vw_TrafficCongestionHotspots', 'V') IS NULL
BEGIN
    THROW 51001, 'FAIL: vw_TrafficCongestionHotspots does not exist.', 1;
END;

PRINT 'PASS: Congestion hotspot view exists.';


-- 2. Check source data and hotspot data
DECLARE @SourceCount BIGINT;
DECLARE @HotspotCount BIGINT;

SELECT @SourceCount = COUNT_BIG(*)
FROM dbo.TrafficRecords;

SELECT @HotspotCount = COUNT_BIG(*)
FROM dbo.vw_TrafficCongestionHotspots;

IF @SourceCount = 0
BEGIN
    PRINT 'WARNING: TrafficRecords is empty. No hotspot data available.';
END
ELSE IF @HotspotCount = 0
BEGIN
    PRINT 'INFO: No potential congestion hotspots found.';
END
ELSE
BEGIN
    PRINT 'PASS: Potential congestion hotspots found.';
END;


-- 3. Check demo congestion criteria
IF EXISTS (
    SELECT 1
    FROM dbo.vw_TrafficCongestionHotspots
    WHERE ObservedVehicleCount < 3
       OR AverageSpeedKmh > 20
       OR AverageSpeedKmh IS NULL
)
BEGIN
    THROW 51002, 'FAIL: Hotspot does not meet demo criteria.', 1;
END;

PRINT 'PASS: All hotspots meet demo congestion criteria.';


-- 4. Display hotspot results
SELECT *
FROM dbo.vw_TrafficCongestionHotspots
ORDER BY IntervalStart, RoadSegmentID;


PRINT '===== TEST 04 COMPLETED =====';
GO
