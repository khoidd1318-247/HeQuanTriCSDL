import pandas as pd

from src.dataset_manager import validate_dataset


def test_validate_dataset_counts_missing_duplicates_and_invalid_values():
    df = pd.DataFrame({
        "timestamp": ["2026-01-01 08:00:00", "not-a-time", "2026-01-01 08:00:00"],
        "x": [1.0, 2.0, None],
        "y": [4.0, "bad", 6.0],
        "vehicle_id": [10, 11, 10],
    })
    report = validate_dataset(df, timestamp_col="timestamp", x_col="x", y_col="y")

    assert report["row_count"] == 3
    assert report["column_count"] == 4
    assert report["missing_cells_total"] == 1
    assert report["duplicate_full_rows"] == 0
    assert report["timestamp_check"]["invalid_count"] == 1
    assert report["coordinate_check"]["invalid_or_missing_count"] == 2
