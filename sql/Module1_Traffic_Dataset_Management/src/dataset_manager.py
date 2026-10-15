"""
Module 1 - Traffic Dataset Management
Generic CSV/TSV dataset inspection and validation for UAV traffic trajectory data.

This module does not assume a fixed inD/pNEUMA schema. Pass column names via CLI
when validating timestamps or coordinates.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import pandas as pd


SUPPORTED_SUFFIXES = {".csv", ".tsv", ".txt"}


def sha256_file(path: str | Path, chunk_size: int = 1024 * 1024) -> str:
    """Return SHA-256 checksum without loading the whole file into memory."""
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(chunk_size), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_dataset(path: str | Path, sep: str | None = None, nrows: int | None = None) -> pd.DataFrame:
    """Read a CSV/TSV file. If sep is omitted, infer comma or tab from extension."""
    file_path = Path(path)
    if not file_path.exists():
        raise FileNotFoundError(f"Dataset not found: {file_path}")
    if file_path.suffix.lower() not in SUPPORTED_SUFFIXES:
        raise ValueError(f"Unsupported file type {file_path.suffix!r}. Use CSV, TSV, or TXT.")
    if sep is None:
        sep = "\t" if file_path.suffix.lower() == ".tsv" else ","
    return pd.read_csv(file_path, sep=sep, nrows=nrows, low_memory=False)


def validate_dataset(
    df: pd.DataFrame,
    timestamp_col: str | None = None,
    x_col: str | None = None,
    y_col: str | None = None,
) -> dict[str, Any]:
    """Return a structured quality report for a dataframe."""
    missing_by_column = {
        str(column): int(count)
        for column, count in df.isna().sum().items()
        if int(count) > 0
    }

    # Full-row duplicate count; duplicated trajectory IDs alone are not considered duplicates.
    duplicate_rows = int(df.duplicated().sum())

    timestamp_report = None
    if timestamp_col:
        if timestamp_col not in df.columns:
            timestamp_report = {
                "column": timestamp_col,
                "error": "Timestamp column not found",
                "invalid_count": None,
            }
        else:
            parsed = pd.to_datetime(df[timestamp_col], errors="coerce", utc=True)
            timestamp_report = {
                "column": timestamp_col,
                "invalid_count": int(parsed.isna().sum()),
                "valid_count": int(parsed.notna().sum()),
                "min_utc": parsed.min().isoformat() if parsed.notna().any() else None,
                "max_utc": parsed.max().isoformat() if parsed.notna().any() else None,
            }

    coordinate_report = None
    if x_col or y_col:
        missing_columns = [c for c in (x_col, y_col) if c and c not in df.columns]
        if missing_columns:
            coordinate_report = {
                "x_column": x_col,
                "y_column": y_col,
                "error": f"Coordinate column(s) not found: {missing_columns}",
            }
        elif x_col and y_col:
            x = pd.to_numeric(df[x_col], errors="coerce")
            y = pd.to_numeric(df[y_col], errors="coerce")
            invalid = x.isna() | y.isna()
            coordinate_report = {
                "x_column": x_col,
                "y_column": y_col,
                "invalid_or_missing_count": int(invalid.sum()),
                "valid_count": int((~invalid).sum()),
                "note": "Numeric coordinates checked only; geographic bounds depend on the dataset coordinate system.",
            }

    return {
        "row_count": int(len(df)),
        "column_count": int(len(df.columns)),
        "columns": [str(c) for c in df.columns],
        "dtypes": {str(c): str(dtype) for c, dtype in df.dtypes.items()},
        "missing_cells_total": int(df.isna().sum().sum()),
        "missing_by_column": missing_by_column,
        "duplicate_full_rows": duplicate_rows,
        "timestamp_check": timestamp_report,
        "coordinate_check": coordinate_report,
    }


def create_metadata(path: str | Path, df: pd.DataFrame, source_name: str | None = None) -> dict[str, Any]:
    """Create metadata describing the source file and the inspected table."""
    file_path = Path(path)
    stat = file_path.stat()
    return {
        "dataset_name": source_name or file_path.stem,
        "source_file": file_path.name,
        "file_size_bytes": stat.st_size,
        "sha256": sha256_file(file_path),
        "format": file_path.suffix.lower().lstrip("."),
        "inspected_at_utc": datetime.now(timezone.utc).isoformat(),
        "row_count": int(len(df)),
        "column_count": int(len(df.columns)),
        "columns": [str(c) for c in df.columns],
        "purpose": "UAV-collected urban traffic dataset; purpose/coverage should be completed by the team.",
    }


def write_json(payload: dict[str, Any], output_path: str | Path) -> None:
    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Inspect and validate a traffic dataset.")
    parser.add_argument("dataset", help="Path to CSV/TSV/TXT dataset")
    parser.add_argument("--sep", default=None, help="Delimiter, e.g. ',' or '\\t'. Defaults by extension.")
    parser.add_argument("--timestamp-col", default=None, help="Timestamp column name, if known")
    parser.add_argument("--x-col", default=None, help="X/longitude coordinate column name, if known")
    parser.add_argument("--y-col", default=None, help="Y/latitude coordinate column name, if known")
    parser.add_argument("--sample-rows", type=int, default=None, help="Inspect only first N rows (for quick preview)")
    parser.add_argument("--report", default="reports/data_quality_report.json", help="Output quality report JSON")
    parser.add_argument("--metadata", default="reports/dataset_metadata.json", help="Output metadata JSON")
    parser.add_argument("--name", default=None, help="Friendly dataset name for metadata")
    args = parser.parse_args()

    df = read_dataset(args.dataset, sep=args.sep, nrows=args.sample_rows)
    report = validate_dataset(df, args.timestamp_col, args.x_col, args.y_col)
    metadata = create_metadata(args.dataset, df, args.name)
    write_json(report, args.report)
    write_json(metadata, args.metadata)

    print("=== Dataset preview (first 5 rows) ===")
    print(df.head().to_string(index=False))
    print("\n=== Dataset schema ===")
    print(df.dtypes.to_string())
    print(f"\nQuality report saved to: {args.report}")
    print(f"Metadata saved to: {args.metadata}")
    print(f"Rows inspected: {report['row_count']}; columns: {report['column_count']}")


if __name__ == "__main__":
    main()
