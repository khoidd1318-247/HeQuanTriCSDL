
# Module 2 — Traffic Pattern Analysis

**Project:** Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting Using Drone-Collected Traffic Data

## 1. Objective

This module analyzes drone-collected traffic observations to identify traffic patterns and potential congestion hotspots.

## 2. Scope

- Analyze traffic flow over time.
- Calculate average, minimum, and maximum vehicle speeds.
- Identify road segments with potential congestion.
- Provide reusable SQL views and stored procedures.
- Improve query performance using appropriate indexes.
- Validate analysis results using SQL test scripts.

## 3. Directory Structure

- `src/`: SQL scripts for traffic analysis.
- `tests/`: SQL scripts for testing and validating results.
- `README.md`: Module documentation.
- `CONTRIBUTION_LOG.md`: Development activity log.

## 4. Technology

- Microsoft SQL Server
- Transact-SQL (T-SQL)
- SQL Server Management Studio (SSMS)
- GitHub for source code management

## 5. Dataset and Database Schema

The project team has not yet finalized the traffic dataset and database schema.

The analysis scripts must be aligned with the actual source table, column names, and data types before integration.

Demo tables, if used during initial development, must be clearly separated from the official project database tables.

## 6. Implementation Plan

1. Establish the module directory and documentation.
2. Prepare a reproducible dataset for testing SQL logic.
3. Create reusable analysis views.
4. Calculate traffic flow by time interval and road segment.
5. Calculate vehicle speed statistics.
6. Identify potential congestion hotspots.
7. Implement stored procedures.
8. Review indexes and query performance.
9. Test and document the results.
10. Integrate with the official dataset after the schema is confirmed.

## 7. Execution

Open the SQL scripts in SQL Server Management Studio and execute them in the documented order.

The demo environment must be used only for testing. Do not run demo setup scripts against production or shared project data without confirming the target database.

## 8. Limitations

- Dataset structure and column names are not yet finalized.
- Traffic flow is not the same as physical traffic density.
- Physical density calculations require appropriate spatial measurements.
- Congestion thresholds must be documented and validated against the selected dataset.
- Analysis accuracy depends on data quality and timestamp interpretation.
