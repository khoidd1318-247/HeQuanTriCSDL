import numpy as np
import pandas as pd
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from statsmodels.tsa.arima.model import ARIMA
from prophet import Prophet


def build_traffic_time_series(file_path: str, freq: str = "15min"):
  """Đọc file CSV và chuẩn bị dữ liệu chuỗi thời gian cho mô hình dự báo giao thông UAV."""
  df = pd.read_csv(file_path)

  # Tự động nhận diện cột thời gian
  time_col = None
  for col in ["timestamp", "ds", "time", "datetime"]:
    if col in df.columns:
      time_col = col
      break

  if not time_col:
    raise ValueError(
        f"Không tìm thấy cột thời gian trong file! Các cột hiện có: {list(df.columns)}"
    )

  # Tự động nhận diện cột giá trị
  val_col = None
  for col in ["y", "traffic_count", "density", "count", "value"]:
    if col in df.columns:
      val_col = col
      break

  if not val_col:
    val_col = [c for c in df.columns if c != time_col][0]

  # Đổi tên về chuẩn 'ds' và 'y'
  df_ts = df[[time_col, val_col]].copy()
  df_ts.columns = ["ds", "y"]

  df_ts["ds"] = pd.to_datetime(df_ts["ds"])
  df_ts = df_ts.sort_values("ds")
  df_ts = df_ts.set_index("ds")

  # Gom cụm theo khoảng thời gian và điền giá trị trống bằng phương thức mới .ffill()
  df_ts = df_ts.resample(freq).mean().ffill().reset_index()

  return df_ts


def run_arima_forecast(train_df, test_df):
  """Chạy mô hình dự báo ARIMA."""
  history = list(train_df["y"].values)
  predictions = []

  for t in range(len(test_df)):
    try:
      model = ARIMA(history, order=(1, 1, 1))
      model_fit = model.fit()
      output = model_fit.forecast()
      yhat = output[0]
    except Exception:
      yhat = history[-1] if history else 0

    predictions.append(yhat)
    history.append(test_df["y"].iloc[t])

  return predictions


def run_prophet_forecast(train_df, test_df):
  """Chạy mô hình dự báo Facebook Prophet."""
  model = Prophet(weekly_seasonality=False, daily_seasonality=True)
  model.fit(train_df)

  future = test_df[["ds"]].copy()
  forecast = model.predict(future)
  return forecast["yhat"].values


def evaluate_model_performance(y_true, y_pred):
  """Đánh giá hiệu suất mô hình qua các chỉ số MAE, RMSE, MAPE, R2."""
  y_true = np.array(y_true)
  y_pred = np.array(y_pred)

  mae = mean_absolute_error(y_true, y_pred)
  rmse = np.sqrt(mean_squared_error(y_true, y_pred))

  non_zero_idx = y_true != 0
  if np.any(non_zero_idx):
    mape = (
        np.mean(np.abs((y_true[non_zero_idx] - y_pred[non_zero_idx]) / y_true[non_zero_idx]))
        * 100
    )
  else:
    mape = 0.0

  try:
    r2 = r2_score(y_true, y_pred)
  except Exception:
    r2 = 0.0

  return {
      "MAE": round(float(mae), 4),
      "RMSE": round(float(rmse), 4),
      "MAPE_%": round(float(mape), 2),
      "R2_Score": round(float(r2), 4),
  }