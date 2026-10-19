import sys
from pathlib import Path
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Hỗ trợ nạp module linh hoạt (cả khi chạy trực tiếp lẫn khi chạy từ thư mục gốc repo)
CURRENT_DIR = Path(__file__).resolve().parent
REPO_ROOT = CURRENT_DIR.parent.parent
if str(CURRENT_DIR) not in sys.path:
    sys.path.insert(0, str(CURRENT_DIR))
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

try:
    from forecasting import (
        build_traffic_time_series,
        evaluate_model_performance,
        run_arima_forecast,
        run_prophet_forecast,
    )
except ImportError:
    from sql.Module3_Traffic_Forecasting.forecasting import (
        build_traffic_time_series,
        evaluate_model_performance,
        run_arima_forecast,
        run_prophet_forecast,
    )

app = FastAPI(
    title="UAV Traffic Analysis & Forecasting API",
    version="1.0.0",
    description="API cho Mô-đun 3: Dự báo ùn tắc ngắn hạn từ dữ liệu UAV",
)


class ForecastRequest(BaseModel):
    dataset_path: str
    model_type: str  # Chọn "ARIMA" hoặc "PROPHET"
    interval: str = "15min"  # Khoảng thời gian gom cụm (5min, 15min, 30min)


@app.post("/api/v1/forecasting/run")
def api_run_forecasting(req: ForecastRequest):
    try:
        # 1. Chuẩn bị dữ liệu chuỗi thời gian từ file CSV quỹ đạo UAV
        df_ts = build_traffic_time_series(req.dataset_path, freq=req.interval)

        if len(df_ts) < 10:
            raise HTTPException(
                status_code=400,
                detail="Dữ liệu quá ít để tiến hành chia tập train/test!",
            )

        # Chia tập dữ liệu: 80% huấn luyện (train), 20% kiểm thử (test)
        train_size = int(len(df_ts) * 0.8)
        train_df = df_ts.iloc[:train_size]
        test_df = df_ts.iloc[train_size:]

        # 2. Chạy thuật toán dự báo tùy theo lựa chọn của người dùng
        model_name = req.model_type.upper()
        if model_name == "ARIMA":
            preds = run_arima_forecast(train_df, test_df)
        elif model_name == "PROPHET":
            preds = run_prophet_forecast(train_df, test_df)
        else:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Mô hình không được hỗ trợ! Vui lòng chọn 'ARIMA' hoặc 'PROPHET'."
                ),
            )

        # 3. Đánh giá sai số mô hình (MAE, RMSE, MAPE, R2)
        metrics = evaluate_model_performance(test_df["y"].values, preds)

        # 4. Trả kết quả về
        return {
            "status": "success",
            "model_used": model_name,
            "aggregation_interval": req.interval,
            "evaluation_metrics": metrics,
            "forecast_results": {
                "timestamps": test_df["ds"].astype(str).tolist(),
                "actual_values": test_df["y"].tolist(),
                "predicted_values": [round(float(p), 2) for p in preds],
            },
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))