"""
Unit tests for Module 5 - Experiment Management & Reproducibility
Compatible with both pytest and python -m unittest
"""
import sys
from pathlib import Path
import unittest

# Ensure src is on sys.path regardless of execution working directory
MODULE_ROOT = Path(__file__).resolve().parent.parent
if str(MODULE_ROOT) not in sys.path:
    sys.path.insert(0, str(MODULE_ROOT))

from src.experiment_manager import compute_metrics, create_experiment_manifest, compare_manifests


class TestExperimentManager(unittest.TestCase):
    def test_compute_metrics_exact(self):
        actual = [10.0, 20.0, 30.0]
        predicted = [12.0, 18.0, 30.0]
        res = compute_metrics(actual, predicted)

        self.assertAlmostEqual(res["MAE"], 4.0 / 3.0, places=2)
        self.assertAlmostEqual(res["RMSE"], (8.0 / 3.0) ** 0.5, places=2)
        self.assertGreater(res["R2_Score"], 0.90)

    def test_compute_metrics_empty_raises(self):
        with self.assertRaises(ValueError):
            compute_metrics([], [])

    def test_compute_metrics_length_mismatch_raises(self):
        with self.assertRaises(ValueError):
            compute_metrics([1.0], [1.0, 2.0])

    def test_create_experiment_manifest(self):
        manifest = create_experiment_manifest(
            experiment_name="Unit Test ARIMA",
            recording_id="REC_IND_01",
            model_algorithm="ARIMA",
            random_seed=42,
        )
        self.assertEqual(manifest["experiment_name"], "Unit Test ARIMA")
        self.assertEqual(manifest["random_seed"], 42)
        self.assertIn("reproducibility_contract", manifest)

    def test_compare_manifests(self):
        m1 = create_experiment_manifest("Exp1", "REC_01", "ARIMA", metrics={"RMSE": 2.5, "MAE": 2.0})
        m2 = create_experiment_manifest("Exp2", "REC_01", "Prophet", metrics={"RMSE": 1.4, "MAE": 1.2})
        df = compare_manifests([m1, m2])

        self.assertEqual(len(df), 2)
        self.assertIn("Model", df.columns)
        self.assertEqual(df.loc[df["Model"] == "Prophet", "RMSE"].values[0], 1.4)


if __name__ == "__main__":
    unittest.main()
