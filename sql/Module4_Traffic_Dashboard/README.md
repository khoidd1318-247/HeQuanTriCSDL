# Module 4 — Urban Traffic Visualization Dashboard

Dashboard for the DBMS project using inD and pNEUMA trajectory data. The application supports CSV upload and SQL Server connection.

## What is included
- KPI cards: unique observed tracks, average speed, share of observations under 10 km/h.
- Time-series charts: observed tracks per minute and mean speed.
- Vehicle type distribution.
- Coordinate scatter plot colored by speed (use normalized coordinates).
- Forecast section that displays predictions if the source has `forecast_timestamp_sec` and `predicted_speed_kmh`.
- SQL Server schema, summary view, and KPI stored procedure in `sql/01_schema.sql`.

## Important data note
inD and pNEUMA do not share the same schema or coordinate system. Do not append raw files without preprocessing:
- inD `*_tracks.csv` generally has `recordingId`, `trackId`, `frame`, `xCenter`, `yCenter`, velocity components, etc. Convert frame to relative seconds using the correct recording FPS. If `xVelocity` and `yVelocity` are m/s, speed in km/h is `sqrt(xVelocity^2 + yVelocity^2) * 3.6`.
- pNEUMA files use one row per vehicle and repeated groups of trajectory values across columns. Reshape the repeated groups into one row per `(recording, track, timestamp)`. The fields include vehicle type, distance, average speed and repeated time/location/speed/acceleration measurements. Verify the actual column headers from your downloaded file before writing the parser.
- Keep recording-relative seconds, not invented wall-clock timestamps. Keep dataset and recording identifiers.
- Do not directly compare x/y between datasets as if they are the same map. inD uses local coordinates in metres; pNEUMA provides geographic coordinates in its trajectory format. For a shared map, transform to a common coordinate reference system first.
- A vehicle's average speed is not the same thing as a time-series speed observation.

## Standard CSV schema
Create a long-format CSV where each row is one vehicle observation at one time:
`dataset,recording_id,track_id,timestamp_sec,vehicle_type,x,y,speed_kmh`

Optional columns:
- `density_veh_per_km`: requires a defensible road-segment/lane assignment and segment length.
- `flow_veh_per_min`: use a clear count definition and aggregation interval.
- `forecast_timestamp_sec`, `predicted_speed_kmh`: produced by Module 3, not fabricated by Module 4.

Example:
```csv
dataset,recording_id,track_id,timestamp_sec,vehicle_type,x,y,speed_kmh
inD,recording01,1001,0.00,car,132.04,-31.99,28.7
pNEUMA,20181029_D1_0900,501,0.00,taxi,23.72,37.98,18.4
```
The values above are illustrative only, not actual observations.

## Run locally
1. Install Python 3.10+.
2. In the project folder:
   `python -m venv .venv`
3. Activate the environment:
   - Windows: `.venv\\Scripts\\activate`
   - macOS/Linux: `source .venv/bin/activate`
4. Install packages: `pip install -r requirements.txt`
5. Run: `streamlit run app.py`

## SQL Server
1. Run `sql/01_schema.sql` in SSMS.
2. Load normalized long-format observations into `dbo.TrafficObservation`.
3. Add forecast output from Module 3 to `dbo.TrafficForecast`.
4. Set environment variables or enter connection information in the app sidebar.
5. The app currently queries the configured observation table. To plot SQL forecast records, extend the forecast query to read `dbo.TrafficForecast`.

For Windows Authentication, install Microsoft ODBC Driver for SQL Server. Avoid committing credentials into Git.

## Interpretation
The `<10 km/h` KPI is only a configurable illustrative flag. A robust congestion label should be calibrated to road context and should ideally consider speed, density/flow, queueing and road segment. Density cannot be inferred reliably from vehicle trajectories alone without defining the spatial region/lane and observation interval.
