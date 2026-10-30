import os
import pandas as pd
import streamlit as st
import plotly.express as px
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus

st.set_page_config(page_title="Urban Traffic Dashboard", page_icon="🚦", layout="wide")

REQUIRED = ["dataset", "recording_id", "track_id", "timestamp_sec", "vehicle_type",
            "x", "y", "speed_kmh"]

@st.cache_data(ttl=60)
def load_csv(path):
    return pd.read_csv(path)

@st.cache_data(ttl=60)
def load_sql(server, database, driver, trusted, username, password, table):
    if trusted:
        conn = f"DRIVER={{{driver}}};SERVER={server};DATABASE={database};Trusted_Connection=yes;TrustServerCertificate=yes;"
    else:
        conn = f"DRIVER={{{driver}}};SERVER={server};DATABASE={database};UID={username};PWD={password};TrustServerCertificate=yes;"
    url = "mssql+pyodbc:///?odbc_connect=" + quote_plus(conn)
    engine = create_engine(url)
    # Table name is configured by the app owner; keep it a simple schema-qualified identifier.
    if not all(part.replace("_", "").isalnum() for part in table.split(".")):
        raise ValueError("Tên bảng không hợp lệ.")
    return pd.read_sql(text(f"SELECT * FROM {table}"), engine)

def normalize(df):
    df = df.copy()
    df.columns = [str(c).strip().lower() for c in df.columns]
    aliases = {
        "source": "dataset", "dataset_name": "dataset",
        "recordingid": "recording_id", "recording": "recording_id",
        "trackid": "track_id", "frame_time": "timestamp_sec", "time": "timestamp_sec",
        "vehicle": "vehicle_type", "type": "vehicle_type",
        "xcenter": "x", "ycenter": "y", "xcenter_m": "x", "ycenter_m": "y",
        "speed": "speed_kmh", "avg_speed": "speed_kmh",
        "density": "density_veh_per_km", "flow": "flow_veh_per_min"
    }
    df = df.rename(columns={c: aliases[c] for c in df.columns if c in aliases})
    missing = [c for c in REQUIRED if c not in df.columns]
    if missing:
        raise ValueError("Thiếu cột bắt buộc: " + ", ".join(missing) +
                         ". Xem README.md để biết định dạng chuẩn.")
    for c in ["timestamp_sec", "track_id", "x", "y", "speed_kmh"]:
        df[c] = pd.to_numeric(df[c], errors="coerce")
    df["dataset"] = df["dataset"].astype(str)
    df["recording_id"] = df["recording_id"].astype(str)
    df["vehicle_type"] = df["vehicle_type"].fillna("Unknown").astype(str)
    df = df.dropna(subset=["timestamp_sec", "speed_kmh"])
    df["speed_kmh"] = df["speed_kmh"].clip(lower=0)
    return df

def congestion_label(speed):
    if pd.isna(speed): return "Không xác định"
    if speed < 10: return "Ùn tắc cao"
    if speed < 25: return "Chậm"
    return "Thông thoáng"

st.title("🚦 Urban Traffic Pattern Analysis")
st.caption("Module 4 — Visualization Dashboard | inD & pNEUMA | SQL Server / T-SQL")

with st.sidebar:
    st.header("Nguồn dữ liệu")
    source_mode = st.radio("Chọn nguồn", ["Tải CSV chuẩn hóa", "SQL Server"])
    df_raw = None
    if source_mode == "Tải CSV chuẩn hóa":
        uploaded = st.file_uploader("Tải CSV đã chuẩn hóa", type=["csv"])
        if uploaded is not None:
            df_raw = pd.read_csv(uploaded)
        else:
            st.info("Tải file CSV có các cột chuẩn hóa. Xem README.md.")
    else:
        server = st.text_input("Server", value=os.getenv("MSSQL_SERVER", "localhost"))
        database = st.text_input("Database", value=os.getenv("MSSQL_DATABASE", "UAV_TrafficDB"))
        driver = st.text_input("ODBC Driver", value=os.getenv("MSSQL_DRIVER", "ODBC Driver 18 for SQL Server"))
        table = st.text_input("Bảng (schema.table)", value="dbo.TrafficObservation")
        trusted = st.checkbox("Windows Authentication", value=True)
        username, password = "", ""
        if not trusted:
            username = st.text_input("SQL username")
            password = st.text_input("SQL password", type="password")
        if st.button("Kết nối và tải dữ liệu"):
            try:
                df_raw = load_sql(server, database, driver, trusted, username, password, table)
                st.session_state["sql_data"] = df_raw
                st.success("Đã tải dữ liệu.")
            except Exception as e:
                st.error(f"Không thể kết nối/tải dữ liệu: {e}")
        if df_raw is None and "sql_data" in st.session_state:
            df_raw = st.session_state["sql_data"]

if df_raw is None:
    st.markdown("""
    ### Bắt đầu
    1. Chuẩn hóa dữ liệu inD hoặc pNEUMA theo `README.md`.
    2. Tải CSV chuẩn hóa ở thanh bên, hoặc nạp vào SQL Server rồi chọn nguồn SQL Server.
    3. Dashboard sẽ hiển thị KPI, chuỗi thời gian, phân bố loại xe, bản đồ quỹ đạo và dự báo nếu có.
    """)
    st.stop()

try:
    df = normalize(df_raw)
except Exception as e:
    st.error(str(e))
    st.stop()

if "flow_veh_per_min" not in df:
    # Count unique vehicles observed in each 1-minute interval; this is a proxy for observed flow,
    # not a calibrated roadway flow rate unless the sampling design supports that interpretation.
    df["minute_bin"] = (df["timestamp_sec"] // 60).astype(int)
    flow = df.groupby(["dataset", "recording_id", "minute_bin"])["track_id"].nunique().rename("flow_veh_per_min").reset_index()
    df = df.merge(flow, on=["dataset", "recording_id", "minute_bin"], how="left")
if "density_veh_per_km" not in df:
    df["density_veh_per_km"] = float("nan")

with st.sidebar:
    st.header("Bộ lọc")
    datasets = sorted(df["dataset"].dropna().unique().tolist())
    selected_ds = st.multiselect("Bộ dữ liệu", datasets, default=datasets)
    view = df[df["dataset"].isin(selected_ds)] if selected_ds else df.iloc[0:0]
    recs = sorted(view["recording_id"].dropna().astype(str).unique().tolist())
    selected_recs = st.multiselect("Recording / khu vực", recs, default=recs)
    view = view[view["recording_id"].astype(str).isin(selected_recs)] if selected_recs else view
    max_t = float(view["timestamp_sec"].max()) if not view.empty else 0
    t_range = st.slider("Thời gian tương đối (giây)", 0.0, max(1.0, max_t), (0.0, max(1.0, max_t)))
    view = view[view["timestamp_sec"].between(t_range[0], t_range[1])]
    types = sorted(view["vehicle_type"].dropna().unique().tolist())
    selected_types = st.multiselect("Loại phương tiện", types, default=types)
    view = view[view["vehicle_type"].isin(selected_types)] if selected_types else view

if view.empty:
    st.warning("Không có dữ liệu phù hợp bộ lọc.")
    st.stop()

avg_speed = view["speed_kmh"].mean()
vehicle_count = view["track_id"].nunique()
mean_density = view["density_veh_per_km"].mean()
slow_share = (view["speed_kmh"] < 10).mean() * 100

c1, c2, c3, c4 = st.columns(4)
c1.metric("Phương tiện duy nhất", f"{vehicle_count:,.0f}")
c2.metric("Vận tốc trung bình", f"{avg_speed:.1f} km/h")
c3.metric("Mật độ trung bình", f"{mean_density:.1f} xe/km" if pd.notna(mean_density) else "Chưa có dữ liệu")
c4.metric("Tỷ lệ quan sát tốc độ < 10 km/h", f"{slow_share:.1f}%")

st.divider()
left, right = st.columns(2)
with left:
    st.subheader("Lưu lượng quan sát theo thời gian")
    ts = view.copy()
    ts["minute"] = (ts["timestamp_sec"] // 60).astype(int)
    ts = ts.groupby(["dataset", "recording_id", "minute"], as_index=False).agg(
        flow_veh_per_min=("track_id", "nunique"),
        mean_speed_kmh=("speed_kmh", "mean"))
    fig = px.line(ts, x="minute", y="flow_veh_per_min", color="recording_id",
                  facet_row="dataset" if ts["dataset"].nunique() > 1 else None,
                  markers=True, labels={"minute": "Phút kể từ đầu recording", "flow_veh_per_min": "Số track duy nhất / phút", "recording_id": "Recording"},
                  title="Số phương tiện quan sát theo phút")
    st.plotly_chart(fig, use_container_width=True)
with right:
    st.subheader("Vận tốc theo thời gian")
    fig2 = px.line(ts, x="minute", y="mean_speed_kmh", color="recording_id",
                   facet_row="dataset" if ts["dataset"].nunique() > 1 else None,
                   markers=True, labels={"minute": "Phút kể từ đầu recording", "mean_speed_kmh": "Vận tốc (km/h)", "recording_id": "Recording"},
                   title="Vận tốc trung bình")
    st.plotly_chart(fig2, use_container_width=True)

left, right = st.columns(2)
with left:
    st.subheader("Cơ cấu phương tiện")
    vc = view.groupby("vehicle_type", as_index=False)["track_id"].nunique().rename(columns={"track_id": "vehicle_count"})
    fig3 = px.bar(vc, x="vehicle_type", y="vehicle_count", color="vehicle_type",
                  labels={"vehicle_type": "Loại phương tiện", "vehicle_count": "Số track"})
    st.plotly_chart(fig3, use_container_width=True)
with right:
    st.subheader("Bản đồ vị trí/quỹ đạo")
    map_df = view.dropna(subset=["x", "y"]).copy()
    if not map_df.empty:
        # x/y are local coordinates in metres for inD; pNEUMA coordinate fields must be mapped consistently.
        map_df = map_df.sort_values("timestamp_sec")
        if len(map_df) > 20000:
            map_df = map_df.sample(20000, random_state=42)
        fig4 = px.scatter(map_df, x="x", y="y", color="speed_kmh",
                          hover_data=["dataset", "recording_id", "track_id", "timestamp_sec", "vehicle_type"],
                          color_continuous_scale="RdYlGn", labels={"x": "X (m hoặc tọa độ đã chuẩn hóa)", "y": "Y (m hoặc tọa độ đã chuẩn hóa)", "speed_kmh": "Vận tốc km/h"},
                          title="Vị trí quan sát (màu biểu thị vận tốc)")
        fig4.update_yaxes(scaleanchor="x", scaleratio=1)
        st.plotly_chart(fig4, use_container_width=True)
    else:
        st.info("Không có tọa độ x/y để vẽ.")

st.divider()
st.subheader("Dự báo ùn tắc")
forecast_cols = {"forecast_timestamp_sec", "predicted_speed_kmh"}
if forecast_cols.issubset(set(df_raw.columns.str.lower())):
    fdf = df_raw.copy()
    fdf.columns = [str(c).strip().lower() for c in fdf.columns]
    fdf["forecast_timestamp_sec"] = pd.to_numeric(fdf["forecast_timestamp_sec"], errors="coerce")
    fdf["predicted_speed_kmh"] = pd.to_numeric(fdf["predicted_speed_kmh"], errors="coerce")
    fdf = fdf.dropna(subset=["forecast_timestamp_sec", "predicted_speed_kmh"])
    if not fdf.empty:
        fig5 = px.line(fdf, x="forecast_timestamp_sec", y="predicted_speed_kmh", color="recording_id" if "recording_id" in fdf else None,
                       labels={"forecast_timestamp_sec": "Thời gian tương đối (giây)", "predicted_speed_kmh": "Vận tốc dự báo (km/h)"},
                       title="Vận tốc dự báo")
        st.plotly_chart(fig5, use_container_width=True)
    else:
        st.info("Chưa có bản ghi dự báo hợp lệ.")
else:
    st.info("Chưa tìm thấy cột forecast_timestamp_sec và predicted_speed_kmh. Khi Module 3 xuất dự báo, đưa kết quả vào bảng/file riêng rồi tích hợp tại đây.")

st.caption("Lưu ý: ngưỡng tốc độ trong dashboard là ngưỡng minh họa, không phải phân loại ùn tắc chuẩn cho mọi loại đường. Dữ liệu inD và pNEUMA có hệ tọa độ, tần số lấy mẫu và cấu trúc thời gian khác nhau; chỉ so sánh sau khi chuẩn hóa.")
