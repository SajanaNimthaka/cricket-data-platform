import sys
from pathlib import Path

import psycopg

DB = "host=localhost port=5432 dbname=postgres user=postgres password=mypassword"


def main():
    if len(sys.argv) != 2:
        print("Usage: py ingestion\\run_sql.py sql\\your_file.sql")
        sys.exit(1)

    sql_path = Path(sys.argv[1])
    sql = sql_path.read_text(encoding="utf-8")

    with psycopg.connect(DB) as conn:
        conn.execute(sql)

    print(f"Ran {sql_path}")


if __name__ == "__main__":
    main()