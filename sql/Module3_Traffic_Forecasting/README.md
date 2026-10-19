# Module 3 — Traffic Forecasting (Dự báo giao thông)

**Project:** Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting Using Drone-Collected Traffic Data  
**Module Lead:** Thùy Trâm  
**Reviewer:** Khôi  

---

## 1. Scope

This module implements the **Short-Term Traffic Congestion Forecasting Engine**:
- Converting UAV trajectory data into regular traffic time series with customizable aggregation intervals (`5min`, `15min`, `30min`).
- Running statistical time-series forecasting via **ARIMA(1,1,1)**.
- Running trend and seasonality decomposition forecasting via **Facebook Prophet**.
- Automated evaluation computing standard metrics: **MAE**, **RMSE**, **MAPE (%)**, and **R² Score**.
- Serving model predictions via high-performance RESTful API powered by **FastAPI**.

---

## 2. Directory structure

```text
Module3_Traffic_Forecasting/
│
├── data/
│   ├── .gitkeep
│   └── uav_traffic_sample.csv       # Sample traffic trajectory time-series dataset
│
├── forecasting.py                   # Core time-series processing & forecasting algorithms (ARIMA, Prophet)
├── main.py                          # FastAPI backend application exposing /api/v1/forecasting/run
├── requirements.txt                 # Dependencies: fastapi, uvicorn, statsmodels, prophet, scikit-learn
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

## 4. Run FastAPI Server

Start the API service with Uvicorn:

```bash
uvicorn main:app --reload --port 8000
```

Interactive API documentation (Swagger UI) is available at:
👉 `http://localhost:8000/docs`

---

## 5. API Testing Example

**Endpoint:** `POST /api/v1/forecasting/run`

**Example Request Payload (JSON):**
```json
{
  "dataset_path": "data/uav_traffic_sample.csv",
  "model_type": "PROPHET",
  "interval": "15min"
}
```

**Example Response:**
```json
{
  "status": "success",
  "model_used": "PROPHET",
  "aggregation_interval": "15min",
  "evaluation_metrics": {
    "MAE": 1.40,
    "RMSE": 1.42,
    "MAPE_%": 3.08,
    "R2_Score": 0.9854
  },
  "forecast_results": { ... }
}
```
