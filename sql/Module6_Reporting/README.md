# Module 6 — Reporting (Export to PDF & Excel)

**Project:** Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting Using Drone-Collected Traffic Data  
**Module Lead:** Nguyễn Văn Chiến  
**DBMS:** Microsoft SQL Server (T-SQL Engine)  

---

## 1. Scope

This module implements the **Reporting & Analytical Export Engine** supporting automated generation of formal reports in **Microsoft Excel (.xlsx)** and **Adobe PDF (.pdf)** formats:
- **Traffic Pattern Analysis Report:** Summarizing vehicle volumes, flow ($q$), density ($k$), average speed ($v$), and spatial-temporal congestion trends over time.
- **Bottleneck / Congestion Hotspots Report:** Identifying top spatial grid cells with severe traffic delay and lowest moving speeds.
- **Forecasting Performance Benchmark Report:** Comparing short-term forecasting models (**ARIMA** vs **Facebook Prophet**) with standard metrics ($MAE$, $RMSE$, $MAPE$, $R^2$).
- **Audit & Metadata Trail:** Storing report metadata and logging export operations in SQL Server (`GENERATED_REPORTS` and `AUDIT_LOGS`).

---

## 2. Directory structure

```text
Module6_Reporting/
│
├── 01_reporting_schema_views.sql      # Table GENERATED_REPORTS and Analytical Views
├── 02_reporting_procedures.sql        # Stored Procedures for data extraction and export audit logging
├── 03_sample_report_data.sql          # Sample report history logs
│
├── src/
│   ├── __init__.py
│   └── report_generator.py            # Python reporting engine generating multi-sheet Excel & PDF documents
│
├── tests/
│   ├── __init__.py
│   └── test_report_generator.py       # Unit tests verifying Excel & PDF generation and data integrity
│
├── requirements.txt                   # Module dependencies (openpyxl, reportlab, pandas, pyodbc)
├── CONTRIBUTION_LOG.md                # Work log and evidence for instructor assessment
└── README.md                          # Documentation & setup guide
```

---

## 3. Setup

Python 3.10+ is recommended.

```bash
python -m venv .venv
```

Activate the environment:

**Windows PowerShell**
```powershell
.venv\Scripts\Activate.ps1
```

**macOS/Linux**
```bash
source .venv/bin/activate
```

Install dependencies:
```bash
python -m pip install -r requirements.txt
```

---

## 4. Deploy Database Objects (T-SQL)

Execute the scripts sequentially in SQL Server Management Studio (SSMS) or via `sqlcmd`:

```powershell
sqlcmd -S ".\SQLEXPRESS" -E -f 65001 -i "01_reporting_schema_views.sql"
sqlcmd -S ".\SQLEXPRESS" -E -f 65001 -i "02_reporting_procedures.sql"
sqlcmd -S ".\SQLEXPRESS" -E -f 65001 -i "03_sample_report_data.sql"
```

---

## 5. Run Report Generator (CLI)

Generate both Excel and PDF reports:
```bash
python src/report_generator.py --type all --output-dir reports
```

Generate only multi-sheet Excel report:
```bash
python src/report_generator.py --type excel --output-dir reports
```

Generate only executive summary PDF report:
```bash
python src/report_generator.py --type pdf --output-dir reports
```

Output files generated:
- `reports/Traffic_Pattern_Report.xlsx` (contains 4 styled sheets: `Tong_Quan`, `Chuoi_Thoi_Gian`, `Diem_Nong_Un_Tac`, `Doi_Sanh_Mo_Hinh`)
- `reports/Traffic_Analytics_Executive_Summary.pdf` (contains executive summary, metadata table, and model benchmark table)

---

## 6. Run tests

Run the unit test suite verifying document generation and schema correctness:

```bash
pytest -q
```
or
```bash
python -m unittest discover -s tests
```

---

## 7. Suggested GitHub workflow

1. Commit this module, SQL scripts, test suite, and documentation.
2. Verify all T-SQL Views and Procedures execute without syntax errors on SQL Server.
3. Verify generated Excel and PDF output files.
4. Record activities in `CONTRIBUTION_LOG.md`.
5. Submit changes for review and merge into the `main` branch.

---

## 8. Current limitations & Next steps

- The PDF layout currently implements an executive summary single-page/multi-page format; rich chart vector embedding can be integrated with matplotlib/plotly image exporter.
- Web Dashboard integration (Module 4) provides one-click browser download buttons for instant export.
