IF DB_ID(N'UAV_TrafficDB') IS NULL
    CREATE DATABASE UAV_TrafficDB;
GO
USE UAV_TrafficDB;
GO

IF OBJECT_ID(N'dbo.TrafficObservation', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TrafficObservation (
        ObservationID BIGINT IDENTITY(1,1) PRIMARY KEY,
        Dataset NVARCHAR(20) NOT NULL,          -- inD / pNEUMA
        RecordingID NVARCHAR(100) NOT NULL,
        TrackID BIGINT NOT NULL,
        TimestampSec FLOAT NOT NULL,            -- relative time within recording
        VehicleType NVARCHAR(50) NULL,
        X FLOAT NULL,                            -- normalized coordinate
        Y FLOAT NULL,                            -- normalized coordinate
        SpeedKmh FLOAT NULL,
        DensityVehPerKm FLOAT NULL,
        FlowVehPerMin FLOAT NULL,
        IngestedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_TrafficObservation_Dataset_Time
        ON dbo.TrafficObservation(Dataset, RecordingID, TimestampSec);
    CREATE INDEX IX_TrafficObservation_Track
        ON dbo.TrafficObservation(Dataset, RecordingID, TrackID);
END;
GO

IF OBJECT_ID(N'dbo.TrafficForecast', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TrafficForecast (
        ForecastID BIGINT IDENTITY(1,1) PRIMARY KEY,
        Dataset NVARCHAR(20) NOT NULL,
        RecordingID NVARCHAR(100) NOT NULL,
        ForecastTimestampSec FLOAT NOT NULL,
        PredictedSpeedKmh FLOAT NULL,
        PredictedFlowVehPerMin FLOAT NULL,
        ModelName NVARCHAR(100) NOT NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    CREATE INDEX IX_TrafficForecast_Recording_Time
        ON dbo.TrafficForecast(Dataset, RecordingID, ForecastTimestampSec);
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_DashboardKPI
    @Dataset NVARCHAR(20) = NULL,
    @RecordingID NVARCHAR(100) = NULL,
    @StartSec FLOAT = NULL,
    @EndSec FLOAT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        COUNT(DISTINCT TrackID) AS UniqueVehicles,
        AVG(SpeedKmh) AS AvgSpeedKmh,
        AVG(DensityVehPerKm) AS AvgDensityVehPerKm,
        SUM(CASE WHEN SpeedKmh < 10 THEN 1 ELSE 0 END) * 100.0 /
            NULLIF(COUNT(SpeedKmh), 0) AS PctObservationsBelow10Kmh
    FROM dbo.TrafficObservation
    WHERE (@Dataset IS NULL OR Dataset = @Dataset)
      AND (@RecordingID IS NULL OR RecordingID = @RecordingID)
      AND (@StartSec IS NULL OR TimestampSec >= @StartSec)
      AND (@EndSec IS NULL OR TimestampSec <= @EndSec);
END;
GO

CREATE OR ALTER VIEW dbo.vw_TrafficMinuteSummary
AS
SELECT
    Dataset,
    RecordingID,
    FLOOR(TimestampSec / 60.0) AS MinuteFromStart,
    COUNT(DISTINCT TrackID) AS UniqueTracksObserved,
    AVG(SpeedKmh) AS AvgSpeedKmh,
    AVG(DensityVehPerKm) AS AvgDensityVehPerKm
FROM dbo.TrafficObservation
GROUP BY Dataset, RecordingID, FLOOR(TimestampSec / 60.0);
GO
