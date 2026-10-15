# Module 1 — Traffic Dataset Management

**Project:** Urban Traffic Pattern Analysis and Short-Term Congestion Forecasting Using Drone-Collected Traffic Data

## 1. Scope

This initial implementation supports:
- Importing CSV/TSV/TXT datasets.
- Previewing rows and identifying the dataset schema.
- Checking missing values and fully duplicated rows.
- Optionally validating a timestamp column.
- Optionally checking whether coordinate columns contain numeric values.
- Creating a JSON data-quality report and dataset metadata.
- Recording a SHA-256 checksum to help identify a changed file.

This is an initial data-processing module, not yet the complete web-based dataset management interface. Version history, user permissions, database storage, and archive/delete workflows can be added during later integration.

## 2. Important dataset note

The project proposal mentions public UAV datasets such as **inD** and **pNEUMA**, but the exact dataset and its schema must be confirmed by the team. Do not assume that column names are the same across datasets. Use the actual column names shown by the preview before passing `--timestamp-col`, `--x-col`, or `--y-col`.

For large datasets, start with `--sample-rows 50000` to inspect a sample. The report will describe the sample, not the entire dataset. Remove `--sample-rows` when ready to inspect the complete file, if memory permits.

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

## 4. Put the dataset in place

Place a CSV/TSV/TXT file under `data/raw/`. Large original datasets should generally not be committed to GitHub unless the license, repository size, and instructor's requirements allow it. Commit the code and small documentation/report examples instead.

## 5. Run

Example using a file named `traffic.csv`:

```bash
python src/dataset_manager.py data/raw/traffic.csv --sample-rows 50000
```

If the actual column names are known, pass them explicitly. For example only (replace names with real columns):

```bash
python src/dataset_manager.py data/raw/traffic.csv --timestamp-col timestamp --x-col x --y-col y
```

The command prints a preview and schema, and creates:
- `reports/data_quality_report.json`
- `reports/dataset_metadata.json`

These JSON files are ignored by Git by default because they may contain dataset-specific details and should be generated from the team's chosen data. If the instructor needs to review a report, remove the relevant `reports/*.json` ignore rule or force-add only the intended report after checking it contains no sensitive information.

## 6. Run tests

```bash
pytest -q
```

## 7. Suggested GitHub workflow

1. Commit this module and README first.
2. Add a small, license-permitted sample dataset only if needed.
3. Record the dataset source, license, download date, selected columns, and preprocessing decisions in the project documentation.
4. Do not commit large raw data or private credentials.
5. Ask the technical lead (Huy) to review the interface and merge changes into the main branch.

## 8. Current limitations

- Timestamp parsing is a general check; timezone interpretation must be confirmed for the chosen dataset.
- Coordinate checking confirms numeric values only. It does not assume latitude/longitude bounds because UAV datasets may use local Cartesian coordinates.
- Duplicate checking detects identical full rows; repeated vehicle IDs are normal in trajectory datasets and are not treated as duplicates by themselves.
- Metadata currently describes the file and inspected table. Dataset provenance and license should be completed manually by the team.
