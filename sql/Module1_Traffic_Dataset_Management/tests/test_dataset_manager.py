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

def test_coordinate_check_detects_negative_values():
    df = pd.DataFrame({
        "x": [-1.0, 2.0, 3.0],
        "y": [4.0, -5.0, 6.0],
    })

    report = validate_dataset(df, x_col="x", y_col="y")

    assert report["coordinate_check"]["negative_x_count"] == 1
    assert report["coordinate_check"]["negative_y_count"] == 1
    assert report["coordinate_check"]["valid_count"] == 3


def test_speed_check_counts_invalid_negative_and_zero_values():
    df = pd.DataFrame({
        "speed_kmh": [30.0, -5.0, 0.0, "bad", None, 50.0]
    })

    report = validate_dataset(df)

    speed = report["speed_check"]

    assert speed["invalid_or_missing_count"] == 2
    assert speed["valid_count"] == 4
    assert speed["negative_count"] == 1
    assert speed["zero_count"] == 1
    assert speed["min_kmh"] == -5.0
    assert speed["max_kmh"] == 50.0


def test_speed_check_returns_none_when_column_missing():
    df = pd.DataFrame({
        "vehicle_id": [1, 2, 3]
    })

    report = validate_dataset(df)

    assert report["speed_check"] is None

from src.dataset_manager import read_dataset


def test_read_dataset_csv(tmp_path):
    file_path = tmp_path / "sample.csv"
    file_path.write_text(
        "id,name\n1,Car\n2,Bus\n",
        encoding="utf-8"
    )

    df = read_dataset(file_path)

    assert len(df) == 2
    assert list(df.columns) == ["id", "name"]


def test_read_dataset_tsv(tmp_path):
    file_path = tmp_path / "sample.tsv"
    file_path.write_text(
        "id\tname\n1\tCar\n2\tBus\n",
        encoding="utf-8"
    )

    df = read_dataset(file_path)

    assert len(df) == 2
    assert list(df.columns) == ["id", "name"]


def test_read_dataset_txt_with_tab_separator(tmp_path):
    file_path = tmp_path / "sample.txt"
    file_path.write_text(
        "id\tname\n1\tCar\n2\tBus\n",
        encoding="utf-8"
    )

    df = read_dataset(file_path, sep="\t")

    assert len(df) == 2
    assert list(df.columns) == ["id", "name"]
