import os
import argparse
import pandas as pd
from sqlalchemy import create_engine


def load_data(csv_path):
    return pd.read_csv(csv_path)


def impute_df(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    for col in df.columns:
        coerced = pd.to_numeric(df[col], errors='coerce')
        if coerced.notna().any():
            mean_val = coerced.mean()
            df[col] = coerced.fillna(mean_val)
        else:
            if df[col].mode().size > 0:
                df[col].fillna(df[col].mode()[0], inplace=True)
    return df


def analyze_by_categories(df: pd.DataFrame, out_dir: str = "output") -> dict:
    os.makedirs(out_dir, exist_ok=True)
    results = {}


    agg_funcs = ['count']
    if 'price' in df.columns:
        agg_funcs.append('mean')

    for cat in ['fuelType', 'transmission', 'model']:
        if cat in df.columns:
            grp = df.groupby(cat).agg(agg_funcs)
            # flatten columns
            grp.columns = ["_" . join(map(str, c)) if isinstance(c, tuple) else str(c) for c in grp.columns]
            results[cat] = grp.sort_values(by=grp.columns[0], ascending=False)
            grp.to_csv(os.path.join(out_dir, f"summary_by_{cat}.csv"))

   
    df.to_csv(os.path.join(out_dir, "cleaned_data.csv"), index=False)
    return results


def upload_to_postgres(df: pd.DataFrame, db_url: str, table_name: str = "car_sales"):
    engine = create_engine(db_url)
    df.to_sql(table_name, engine, if_exists='replace', index=False, method='multi', chunksize=1000)


def main():
    parser = argparse.ArgumentParser(description="Process car sales dataset and upload to PostgreSQL")
    parser.add_argument('--csv', required=True, help='Path to car_sales.csv')
    parser.add_argument('--db-url', required=False, help='Postgres DB URL, e.g. postgresql://user:pass@host:5432/dbname')
    parser.add_argument('--table', default='car_sales', help='Destination table name')
    parser.add_argument('--export-only', action='store_true', help='Only export cleaned CSV and summaries')

    args = parser.parse_args()

    df = load_data(args.csv)
    df_clean = impute_df(df)
    analyze_by_categories(df_clean, out_dir='output')

    if not args.export_only:
        db_url = args.db_url or os.environ.get('DATABASE_URL')
        if not db_url:
            raise ValueError('No database URL provided. Use --db-url or set DATABASE_URL env var')
        upload_to_postgres(df_clean, db_url, table_name=args.table)
        print(f"Uploaded cleaned data to {args.table} at {db_url}")
    else:
        print('Exported cleaned data and summaries to the output/ folder')


if __name__ == '__main__':
    main()
