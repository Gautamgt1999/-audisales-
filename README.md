Project: Car Sales — processing, Postgres load, Power BI

Overview
- Clean and impute missing values using column mean (numeric-like) or mode (categorical).
- Produce summaries by `fuelType`, `transmission`, and `model` in `output/`.
- Load cleaned dataset into PostgreSQL for Power BI visualization.

Quickstart
1. Create a Python environment and install requirements:

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

2. Run processing and export CSVs (no DB upload):

```bash
python data_processing.py --csv "C:/Users/GOWTHAM/OneDrive/Documents/car_sales.csv" --export-only
```

3. To upload to PostgreSQL (example):

```bash
python data_processing.py --csv "C:/Users/GOWTHAM/OneDrive/Documents/car_sales.csv" --db-url "postgresql://user:pass@host:5432/dbname" --table car_sales
```

Or set `DATABASE_URL` environment variable and omit `--db-url`.

Power BI connection
- Option A (recommended): Connect Power BI Desktop directly to PostgreSQL using the Database connector. Use the same connection parameters as above and import the `car_sales` table.
- Option B: Use the exported CSV `output/cleaned_data.csv` and load into Power BI.

Notes
- The script will replace the destination table if it exists. Adjust `if_exists` in `data_processing.py` if you prefer `append`.
