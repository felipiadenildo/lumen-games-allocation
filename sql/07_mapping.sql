-- Bearing group and side of each piece, from the mapping row valid that month (R6, R7, R9, R10).
-- A piece with no valid mapping row, or a bad bucket row, stays unallocated (Q1, Q5).

CREATE OR REPLACE TABLE pieces AS
SELECT * FROM pieces_game
UNION ALL
SELECT * FROM pieces_pool
UNION ALL
SELECT * FROM pieces_indirect;

CREATE OR REPLACE TABLE pieces_mapped AS
WITH matched AS (
    SELECT
        p.line_id,
        p.game_or_bucket,
        p.share,
        l.cost_type,
        l.booked_entity,
        l.booked_group,
        m.game_group IS NOT NULL AS has_mapping,
        m.bearing_group AS mapping_bearing_group,
        m.side AS mapping_side
    FROM pieces p
    JOIN lines l ON l.line_id = p.line_id
    -- A row applies when the month's first day is between its dates, both inclusive (R10)
    LEFT JOIN game_mapping m
        ON m.game_group = p.game_or_bucket
       AND CAST(l.month || '-01' AS DATE) BETWEEN m.start_date AND m.end_date
)
SELECT
    line_id,
    game_or_bucket,
    share,
    CASE
        WHEN NOT has_mapping THEN 'no_mapping_row'
        WHEN cost_type = 'indirect' AND (mapping_bearing_group IS NULL OR mapping_side = 'By entity') THEN 'bad_mapping_row'
    END AS reason,
    -- Direct: the cost doesn't change entity (R6). Indirect: from the bucket row (R9).
    CASE
        WHEN cost_type = 'direct' THEN booked_group
        ELSE mapping_bearing_group
    END AS bearing_group,
    -- By entity: BR Games when booked by LGB, US Games for any other entity (R7)
    CASE
        WHEN mapping_side = 'By entity' AND booked_entity = 'LGB' THEN 'BR Games'
        WHEN mapping_side = 'By entity' THEN 'US Games'
        ELSE mapping_side
    END AS side
FROM matched;
