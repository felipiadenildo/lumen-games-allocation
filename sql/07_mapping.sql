-- Step 07 · Bearing group and side of every piece (R06, R07, R09, R10)
-- What:   each piece (game or bucket) looks up its row in game_mapping valid that month.
--         Valid = the month's first day is between start_date and end_date, both inclusive (R10).
-- Direct piece:   bearing group = booked group, the cost never changes entity (R06);
--                 side = the row's side; 'By entity' -> BR Games if booked by LGB, else US Games (R07, W04).
-- Indirect piece: bearing group and side both come from the bucket row (R09); this is where a cost
--                 booked by one group can be borne by another (W03: LGB pays, new_fi -> FI, US Games).
-- A piece with no valid row (live_fi in March, I03) or a bad bucket row stays unallocated,
-- only that piece; the line's other pieces are allocated (Q01, Q05, D09).
-- Reads:  pieces_game, pieces_pool, pieces_indirect, lines, game_mapping      Writes: pieces, pieces_mapped

-- pieces: the three kinds of piece in one table (same columns: line_id, game_or_bucket, share).
CREATE OR REPLACE TABLE pieces AS
SELECT * FROM pieces_game
UNION ALL
SELECT * FROM pieces_pool
UNION ALL
SELECT * FROM pieces_indirect;

-- pieces_mapped: each piece with the line's cost type and booked entity/group, and its mapping row.
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
-- reason: no_mapping_row (no row valid that month) or bad_mapping_row (a bucket row with a blank
-- bearing group or By entity, Q05). NULL = the piece is allocated.
SELECT
    line_id,
    game_or_bucket,
    share,
    CASE
        WHEN NOT has_mapping THEN 'no_mapping_row'
        WHEN cost_type = 'indirect' AND (mapping_bearing_group IS NULL OR mapping_side = 'By entity') THEN 'bad_mapping_row'
    END AS reason,
    -- Direct: the cost doesn't change entity (R06). Indirect: from the bucket row (R09).
    CASE
        WHEN cost_type = 'direct' THEN booked_group
        ELSE mapping_bearing_group
    END AS bearing_group,
    -- By entity: BR Games when booked by LGB, US Games for any other entity (R07)
    CASE
        WHEN mapping_side = 'By entity' AND booked_entity = 'LGB' THEN 'BR Games'
        WHEN mapping_side = 'By entity' THEN 'US Games'
        ELSE mapping_side
    END AS side
FROM matched;
