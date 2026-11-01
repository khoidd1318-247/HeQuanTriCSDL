
/*
    Module 2: Traffic Pattern Analysis
    File: 06_analysis_indexes.sql

    Purpose:
    Create a nonclustered index to support
    traffic time-range queries.
*/

-- STEP 1: Use the shared project database.
USE UAV_TrafficDB;
GO

-- STEP 2: Check whether the source table exists.
IF OBJECT_ID(N'dbo.TrafficRecords', N'U') IS NULL
BEGIN
    THROW 50001,
          'Table dbo.TrafficRecords does not exist. Please run Module 2 schema first.',
          1;
END;
GO

-- STEP 3: Create the index if it does not already exist.
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

    PRINT N'IX_TrafficRecords_Time_Segment created successfully.';
END
ELSE
BEGIN
    PRINT N'IX_TrafficRecords_Time_Segment already exists.';
END;
GO

-- STEP 4: Inspect indexes on TrafficRecords.
SELECT
    name AS IndexName,
    type_desc AS IndexType,
    is_primary_key AS IsPrimaryKey
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'dbo.TrafficRecords')
ORDER BY index_id;
GO

-- STEP 5: Inspect index key and included columns.
SELECT
    i.name AS IndexName,
    c.name AS ColumnName,
    ic.key_ordinal AS KeyOrdinal,
    ic.is_included_column AS IsIncludedColumn
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic
    ON i.object_id = ic.object_id
   AND i.index_id = ic.index_id
INNER JOIN sys.columns AS c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID(N'dbo.TrafficRecords')
  AND i.name = N'IX_TrafficRecords_Time_Segment'
ORDER BY
    ic.is_included_column,
    ic.key_ordinal,
    c.name;
GO
