DROP TABLE IF EXISTS silver.fact_ball CASCADE;

CREATE TABLE silver.fact_ball AS
SELECT
    m.match_id,
    inn.idx::int                                          AS innings_number,
    inn.val->>'team'                                      AS batting_team,
    COALESCE((inn.val->>'super_over')::boolean, false)    AS is_super_over,
    (ov.val->>'over')::int                                AS over_number,
    d.idx::int                                            AS delivery_in_over,
    d.val->>'batter'                                      AS batter,
    d.val->>'bowler'                                      AS bowler,
    d.val->>'non_striker'                                 AS non_striker,
    r.people->>(d.val->>'batter')                         AS batter_id,
    r.people->>(d.val->>'bowler')                         AS bowler_id,
    r.people->>(d.val->>'non_striker')                    AS non_striker_id,
    (d.val->'runs'->>'batter')::int                       AS runs_batter,
    (d.val->'runs'->>'extras')::int                       AS runs_extras,
    (d.val->'runs'->>'total')::int                        AS runs_total,
    COALESCE((d.val->'extras'->>'wides')::int, 0)         AS wides,
    COALESCE((d.val->'extras'->>'noballs')::int, 0)       AS noballs,
    COALESCE((d.val->'extras'->>'byes')::int, 0)          AS byes,
    COALESCE((d.val->'extras'->>'legbyes')::int, 0)       AS legbyes,
    (d.val->'wickets') IS NOT NULL                        AS is_wicket,
    d.val->'wickets'->0->>'kind'                          AS wicket_kind,
    d.val->'wickets'->0->>'player_out'                    AS player_out
FROM public.raw_matches m
CROSS JOIN LATERAL (
    SELECT m.data->'info'->'registry'->'people' AS people
) r
CROSS JOIN LATERAL jsonb_array_elements(m.data->'innings')
    WITH ORDINALITY AS inn(val, idx)
CROSS JOIN LATERAL jsonb_array_elements(inn.val->'overs')
    AS ov(val)
CROSS JOIN LATERAL jsonb_array_elements(ov.val->'deliveries')
    WITH ORDINALITY AS d(val, idx);

-- Data quality: each delivery must be uniquely identified
ALTER TABLE silver.fact_ball
    ADD PRIMARY KEY (match_id, innings_number, over_number, delivery_in_over);