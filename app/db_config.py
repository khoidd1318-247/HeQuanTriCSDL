"""
===================================================================================
ĐỒ ÁN MÔN HỌC: HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU
ĐỀ TÀI: Phân tích mô hình giao thông đô thị và dự báo ùn tắc ngắn hạn sử dụng dữ liệu UAV
MODULE: CẤU HÌNH KẾT NỐI VÀ TRUY VẤN MICROSOFT SQL SERVER (T-SQL)
HỖ TRỢ: CẢ PYODBC VÀ PYMSSQL TỰ ĐỘNG DÒ TÌM
===================================================================================
"""

import pandas as pd

# Danh sách SQL Server instance phổ biến
SERVERS = [r".\SQLEXPRESS", r".\SQLEXPRESS01", r"localhost\SQLEXPRESS", r"127.0.0.1\SQLEXPRESS", "(local)"]
DATABASE_NAME = "UAV_TrafficDB"

def get_connection():
    """
    Thử kết nối qua pyodbc hoặc pymssql một cách tự động và ổn định nhất.
    """
    last_err = None

    # 1. Thử dùng pyodbc (nếu có)
    try:
        import pyodbc
        drivers = pyodbc.drivers()
        driver = "ODBC Driver 18 for SQL Server" if "ODBC Driver 18 for SQL Server" in drivers else (
                 "ODBC Driver 17 for SQL Server" if "ODBC Driver 17 for SQL Server" in drivers else "SQL Server")

        for srv in SERVERS:
            conn_str = (
                f"DRIVER={{{driver}}};"
                f"SERVER={srv};"
                f"DATABASE={DATABASE_NAME};"
                "Trusted_Connection=yes;"
                "TrustServerCertificate=yes;"
            )
            try:
                conn = pyodbc.connect(conn_str, timeout=3)
                return "pyodbc", conn, srv, driver
            except Exception as e:
                last_err = e
                continue
    except ImportError:
        pass

    # 2. Thử dùng pymssql (nếu có)
    try:
        import pymssql
        for srv in SERVERS:
            try:
                # Với Windows Auth trong pymssql
                conn = pymssql.connect(server=srv, database=DATABASE_NAME)
                return "pymssql", conn, srv, "pymssql"
            except Exception as e:
                last_err = e
                continue
    except ImportError:
        pass

    raise ConnectionError(f"Không thể kết nối SQL Server ({DATABASE_NAME}). Lỗi: {last_err}")

def test_db_connection():
    """Kiểm tra trạng thái kết nối tới Database"""
    try:
        conn_type, conn, srv, driver = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT @@VERSION")
        ver = cursor.fetchone()[0]
        conn.close()
        return True, f"Kết nối thành công [{srv}] qua [{driver}] ({conn_type}).", ver
    except Exception as e:
        return False, str(e), None

def run_query(sql_query, params=None):
    """Thực thi câu truy vấn SELECT và trả về pandas DataFrame"""
    try:
        conn_type, conn, srv, driver = get_connection()
        if params:
            df = pd.read_sql(sql_query, conn, params=params)
        else:
            df = pd.read_sql(sql_query, conn)
        conn.close()
        return df
    except Exception as e:
        print(f"Lỗi truy vấn SQL: {e}")
        return pd.DataFrame()

def call_procedure(proc_name, params=None):
    """Gọi Stored Procedure bên dưới SQL Server và trả về DataFrame kết quả"""
    try:
        conn_type, conn, srv, driver = get_connection()
        cursor = conn.cursor()
        if params:
            placeholders = ", ".join(["?"] * len(params)) if conn_type == "pyodbc" else ", ".join(["%s"] * len(params))
            sql = f"EXEC {proc_name} {placeholders}"
            cursor.execute(sql, params)
        else:
            sql = f"EXEC {proc_name}"
            cursor.execute(sql)
            
        try:
            columns = [column[0] for column in cursor.description]
            rows = cursor.fetchall()
            df = pd.DataFrame.from_records(rows, columns=columns)
        except Exception:
            df = pd.DataFrame()

        conn.commit()
        conn.close()
        return df
    except Exception as e:
        print(f"Lỗi gọi Stored Procedure [{proc_name}]: {e}")
        return pd.DataFrame()
