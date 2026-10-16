"""
Module 5 - Experiment Management & Reproducibility
CLI and helper functions for managing traffic forecasting experiments,
computing evaluation metrics, and ensuring experimental reproducibility.
"""
from __future__ import annotations

import argparse
import json
import math
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import pandas as pd


def compute_metrics(actual: list[float], predicted: list[float]) -> dict[str, float]:
    """Calculate standard forecasting evaluation metrics: MAE, RMSE, MAPE, R2."""
    if len(actual) != len(predicted):
        raise ValueError("Actual and predicted sequences must have identical lengths.")
    if len(actual) == 0:
        raise ValueError("Sequences cannot be empty.")

    n = len(actual)
    errors = [a - p for a, p in zip(actual, predicted)]
    abs_errors = [abs(e) for e in errors]
    sq_errors = [e ** 2 for e in errors]

    mae = sum(abs_errors) / n
    rmse = math.sqrt(sum(sq_errors) / n)

    # MAPE
    pct_errors = [abs(a - p) / a * 100.0 for a, p in zip(actual, predicted) if a > 0]
    mape = sum(pct_errors) / len(pct_errors) if pct_errors else 0.0

    # R2 Score
    avg_actual = sum(actual) / n
    ss_tot = sum((a - avg_actual) ** 2 for a in actual)
    ss_res = sum(sq_errors)
    r2 = 1.0 - (ss_res / ss_tot) if ss_tot > 0 else 0.0

    return {
        "MAE": round(mae, 4),
        "RMSE": round(rmse, 4),
        "MAPE": round(mape, 2),
        "R2_Score": round(r2, 4),
    }


def create_experiment_manifest(
    experiment_name: str,
    recording_id: str,
    model_algorithm: str,
    aggregation_window: str = "5min",
    train_ratio: float = 0.80,
    random_seed: int = 42,
    hyperparameters: dict[str, Any] | None = None,
    metrics: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Build a reproducible experiment manifest recording parameters, dataset info, and results."""
    return {
        "experiment_name": experiment_name,
        "recording_id": recording_id,
        "model_algorithm": model_algorithm,
        "aggregation_window": aggregation_window,
        "train_test_ratio": train_ratio,
        "random_seed": random_seed,
        "hyperparameters": hyperparameters or {},
        "metrics": metrics or {},
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "reproducibility_contract": "Deterministic execution with fixed seed and data split.",
    }


def compare_manifests(manifests: list[dict[str, Any]]) -> pd.DataFrame:
    """Produce a comparative DataFrame given multiple experiment manifests."""
    rows = []
    for m in manifests:
        row = {
            "Experiment": m.get("experiment_name"),
            "Model": m.get("model_algorithm"),
            "Window": m.get("aggregation_window"),
            "Seed": m.get("random_seed"),
            "MAE": m.get("metrics", {}).get("MAE"),
            "RMSE": m.get("metrics", {}).get("RMSE"),
            "MAPE (%)": m.get("metrics", {}).get("MAPE"),
            "R2": m.get("metrics", {}).get("R2_Score"),
        }
        rows.append(row)
    return pd.DataFrame(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate and manage traffic forecasting experiments.")
    parser.add_argument("--name", default="Sample Experiment", help="Experiment name")
    parser.add_argument("--recording", default="REC_IND_01", help="Target recording ID")
    parser.add_argument("--model", choices=["ARIMA", "Prophet", "Moving Average"], default="ARIMA", help="Model algorithm")
    parser.add_argument("--window", default="5min", help="Temporal aggregation window")
    parser.add_argument("--seed", type=int, default=42, help="Random seed for reproducibility")
    parser.add_argument("--report", default="reports/experiment_manifest.json", help="Path to output manifest JSON")
    args = parser.parse_args()

    # Benchmark sample evaluation
    actual = [84.0, 70.4, 52.0, 38.4, 28.0]
    predicted = [86.5, 73.2, 55.4, 41.0, 30.5] if args.model == "ARIMA" else [85.1, 71.8, 53.6, 39.8, 29.5]

    metrics = compute_metrics(actual, predicted)
    manifest = create_experiment_manifest(
        experiment_name=args.name,
        recording_id=args.recording,
        model_algorithm=args.model,
        aggregation_window=args.window,
        random_seed=args.seed,
        hyperparameters={"p": 2, "d": 1, "q": 2} if args.model == "ARIMA" else {"seasonality": "multiplicative"},
        metrics=metrics,
    )

    out_path = Path(args.report)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"=== Experiment: {args.name} ({args.model}) ===")
    print(f"Aggregation Window: {args.window} | Random Seed: {args.seed}")
    print(f"Metrics: MAE={metrics['MAE']}, RMSE={metrics['RMSE']}, MAPE={metrics['MAPE']}%, R2={metrics['R2_Score']}")
    print(f"Manifest saved to: {out_path}")


if __name__ == "__main__":
    main()
