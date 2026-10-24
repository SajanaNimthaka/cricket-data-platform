CREATE SCHEMA IF NOT EXISTS silver;

-- One row per match
DROP TABLE IF EXISTS silver.dim_match CASCADE;
CREATE TABLE silver.dim_match AS
SELECT
    match_id,
    (data->'info'->'dates'->>0)::date            AS match_date,
    data->'info'->>'season'                      AS season,
    data->'info'->>'city'                        AS city,
    data->'info'->>'venue'                       AS venue,
    data->'info'->'event'->>'name'               AS event_name,
    (data->'info'->'event'->>'match_number')::int AS match_number,
    data->'info'->>'match_type'                  AS match_type,
    (data->'info'->>'overs')::int                AS overs,
    data->'info'->'teams'->>0                    AS team_1,
    data->'info'->'teams'->>1                    AS team_2,
    data->'info'->'toss'->>'winner'              AS toss_winner,
    data->'info'->'toss'->>'decision'            AS toss_decision,
    data->'info'->'outcome'->>'winner'           AS winner,
    data->'info'->'outcome'->>'result'           AS result,
    (data->'info'->'outcome'->'by'->>'runs')::int    AS win_by_runs,
    (data->'info'->'outcome'->'by'->>'wickets')::int AS win_by_wickets,
    data->'info'->'outcome'->>'eliminator'       AS eliminator,
    data->'info'->'player_of_match'->>0          AS player_of_match
FROM public.raw_matches;

ALTER TABLE silver.dim_match ADD PRIMARY KEY (match_id);

-- One row per team
DROP TABLE IF EXISTS silver.dim_team CASCADE;
CREATE TABLE silver.dim_team AS
SELECT DISTINCT team_name
FROM (
    SELECT data->'info'->'teams'->>0 AS team_name FROM public.raw_matches
    UNION
    SELECT data->'info'->'teams'->>1 FROM public.raw_matches
) t
WHERE team_name IS NOT NULL;

ALTER TABLE silver.dim_team ADD PRIMARY KEY (team_name);

-- One row per person in the registry (players, umpires, referees)
DROP TABLE IF EXISTS silver.dim_player CASCADE;
CREATE TABLE silver.dim_player AS
SELECT
    value                  AS player_id,
    min(key)               AS player_name,
    count(DISTINCT key)    AS name_variants
FROM public.raw_matches,
     jsonb_each_text(data->'info'->'registry'->'people')
GROUP BY value;

ALTER TABLE silver.dim_player ADD PRIMARY KEY (player_id);