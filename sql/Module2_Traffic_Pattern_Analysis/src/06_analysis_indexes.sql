
/*
    File: 06_analysis_indexes.sql
    Purpose: Create a demo index for traffic time-range queries.
*/

USE UAV_TrafficDB;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_TrafficRecords_Time_Segment'
      AND object_id = OBJECT_ID(N'dbo.TrafficRecords')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_TrafficRecords_Time_Segment
    ON dbo.TrafficRecords (ObservedAt, RoadSegmentID)
    INCLUDE (DatasetVersionID, VehicleID, SpeedKmh);

    PRINT N'Demo index created.';
END
ELSE
BEGIN
    PRINT N'Demo index already exists.';
END;
GO

-- Inspect indexes on the demo table.
SELECT
    name AS IndexName,
    type_desc AS IndexType,
    is_primary_key AS IsPrimaryKey
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.TrafficRecords')
ORDER BY index_id;
GO
