# Module 5 — Experiment Management & Reproducibility

**Project:** Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting Using Drone-Collected Traffic Data  
**Module Lead:** Dương Đình Khôi (Khôi)  
**DBMS:** Microsoft SQL Server (T-SQL Engine)  

---

## 1. Scope

This module implements the **Experiment Management & Reproducibility** foundation for traffic congestion forecasting:
- Storing experiment configurations: target dataset (`RecordingID`), algorithm (`ARIMA`, `Prophet`), aggregation window (`1min`, `5min`, `15min`, `30min`), and train/test split ratio.
- Enforcing the **Reproducibility Contract**: fixed `RandomSeed` and hyperparameter snapshots ensuring that every experiment can be reproduced with deterministic results.
- Storing granular multi-step forecast results (`ActualDensity`, `PredictedDensity`, errors).
- Automated in-database evaluation computing standard metrics: **MAE**, **RMSE**, **MAPE (%)**, and **R² Score** via T-SQL User-Defined Functions and Stored Procedures.
- Side-by-side benchmarking and comparison across different models.
- Automatic audit logging for tracking experiment creation and parameter evolution.

---

## 2. Directory structure

```text
Module5_Experiment_Management/
│
├── 01_experiment_schema.sql         # Tables (EXPERIMENTS, RESULTS, METRICS, AUDIT_LOGS) & Indexes
├── 02_experiment_functions.sql      # UDFs calculating MAE, RMSE, MAPE in T-SQL
├── 03_experiment_procedures.sql     # Stored Procedures & Triggers for experiment lifecycle
├── 04_sample_benchmarks.sql         # Benchmark evaluation data: ARIMA(2,1,2) vs Facebook Prophet
│
├── src/
│   ├── __init__.py
│   └── experiment_manager.py        # Python CLI & manifest generator for experiments
│
├── tests/
│   ├── __init__.py
│   └── test_experiment_manager.py   # Unit test suite for evaluation metrics & manifests
│
├── requirements.txt                 # Module dependencies
├── CONTRIBUTION_LOG.md              # Work log and evidence for instructor assessment
└── README.md                        # Documentation & setup guide
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
sqlcmd -S ".\SQLEXPRESS" -E -f 65001 -i "01_experiment_schema.sql"
sqlcmd -S ".\SQLEXPRESS" -E -f 65001 -i "02_experiment_functions.sql"
sqlcmd -S ".\SQLEXPRESS" -E -f 65001 -i "03_experiment_procedures.sql"
sqlcmd -S ".\SQLEXPRESS" -E -f 65001 -i "04_sample_benchmarks.sql"
```

---

## 5. Run Experiment Manager (CLI)

Run an evaluation for an ARIMA experiment:
```bash
python src/experiment_manager.py --name "ARIMA Baseline" --model ARIMA --window 5min --seed 42
```

Run an evaluation for a Facebook Prophet experiment:
```bash
python src/experiment_manager.py --name "Prophet Baseline" --model Prophet --window 5min --seed 42
```

The command generates structured experiment manifests:
- `reports/experiment_manifest.json`

---

## 6. Run tests

Run the test suite using pytest or standard Python unittest:

```bash
pytest -q
```
or
```bash
python -m unittest discover -s tests
```

---

## 7. Suggested GitHub workflow

1. Commit this module, SQL scripts, test suite, and README.
2. Verify all T-SQL procedures execute without syntax errors on SQL Server.
3. Review benchmark results in `CONTRIBUTION_LOG.md`.
4. Submit pull request / merge into `main` after review by the technical lead (Huy).

---

## 8. Current limitations & Next steps

- Current benchmark sample focuses on 5-step ahead forecasting (15–30 min horizon); multi-step autoregressive rolling forecast will be extended in Module 3 integration.
- Deep learning architectures (LSTM, ST-GCN) are deliberately out of scope according to project boundaries, keeping focus on explainable models (ARIMA & Prophet).
- Integration with Web Dashboard (Module 4) enables live interactive side-by-side plotting.
