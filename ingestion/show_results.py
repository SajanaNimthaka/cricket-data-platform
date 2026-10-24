import psycopg

DB = "host=localhost port=5432 dbname=postgres user=postgres password=mypassword"

QUERIES = [
    ("Matches loaded",
     """SELECT count(*) AS matches,
               min(match_date) AS first_match,
               max(match_date) AS last_match
        FROM silver.dim_match"""),

    ("Total deliveries in the database",
     "SELECT count(*) AS deliveries FROM silver.fact_ball"),

    ("Top 10 run scorers",
     """SELECT p.player_name, sum(f.runs_batter) AS runs
        FROM silver.fact_ball f
        JOIN silver.dim_player p ON p.player_id = f.batter_id
        GROUP BY p.player_name
        ORDER BY runs DESC
        LIMIT 10"""),

    ("Top 10 wicket takers",
     """SELECT p.player_name, count(*) AS wickets
        FROM silver.fact_ball f
        JOIN silver.dim_player p ON p.player_id = f.bowler_id
        WHERE f.is_wicket
          AND f.wicket_kind NOT IN ('run out', 'retired hurt',
                                    'retired out', 'obstructing the field')
        GROUP BY p.player_name
        ORDER BY wickets DESC
        LIMIT 10"""),

    ("Matches won by each team",
     """SELECT winner AS team, count(*) AS wins
        FROM silver.dim_match
        WHERE winner IS NOT NULL
        GROUP BY winner
        ORDER BY wins DESC"""),

    ("Toss decision: bat or field?",
     """SELECT toss_decision, count(*) AS matches
        FROM silver.dim_match
        GROUP BY toss_decision
        ORDER BY matches DESC"""),

    ("Average first-innings score",
     """SELECT round(avg(total), 1) AS avg_first_innings_runs
        FROM (
            SELECT match_id, sum(runs_total) AS total
            FROM silver.fact_ball
            WHERE innings_number = 1
            GROUP BY match_id
        ) t"""),
]


def show(cur, title, sql):
    cur.execute(sql)
    columns = [c.name for c in cur.description]
    rows = cur.fetchall()
    print(f"\n=== {title} ===")
    print(" | ".join(columns))
    print("-" * 45)
    for row in rows:
        print(" | ".join(str(value) for value in row))


def main():
    with psycopg.connect(DB) as conn:
        with conn.cursor() as cur:
            for title, sql in QUERIES:
                show(cur, title, sql)


if __name__ == "__main__":
    main()