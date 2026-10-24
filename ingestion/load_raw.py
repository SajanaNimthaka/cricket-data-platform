import json
from pathlib import Path

import psycopg

DB = "host=localhost port=5432 dbname=postgres user=postgres password=mypassword"
RAW_DIR = Path("data/raw")

CREATE_SQL = """
CREATE TABLE IF NOT EXISTS raw_matches (
    match_id   TEXT PRIMARY KEY,
    source_dir TEXT NOT NULL,
    loaded_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    data       JSONB NOT NULL
);
"""

INSERT_SQL = """
INSERT INTO raw_matches (match_id, source_dir, data)
VALUES (%s, %s, %s::jsonb)
ON CONFLICT (match_id) DO NOTHING;
"""


def main():
    files = sorted(RAW_DIR.rglob("*.json"))
    print(f"Found {len(files)} JSON files")

    inserted = 0
    skipped = 0
    with psycopg.connect(DB) as conn:
        conn.execute(CREATE_SQL)
        for f in files:
            text = f.read_text(encoding="utf-8")
            json.loads(text)  # fails early if a file is not valid JSON
            cur = conn.execute(INSERT_SQL, (f.stem, f.parent.name, text))
            if cur.rowcount == 1:
                inserted += 1
            else:
                skipped += 1

    print(f"Inserted: {inserted}, already loaded (skipped): {skipped}")


if __name__ == "__main__":
    main()