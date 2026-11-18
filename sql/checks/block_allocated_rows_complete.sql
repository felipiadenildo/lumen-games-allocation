-- Check · block_allocated_rows_complete
-- What:  every row with status 'allocated' has a full, valid destination.
-- Why:   an allocated row is a promise that the dollars are on a side. A row with no game, a side that isn't
--        BR Games / US Games, or a wrong bearing group would be counted in the summary but be wrong (R05-R09).
--        One check with five conditions instead of six separate checks (F3 review).
-- Each part of the UNION ALL is one way a row can be incomplete; the 'problem' column says which.
--
-- How run.py uses this file: it runs the query after steps 01-11 and counts the rows it returns.
--   0 rows = pass. Any row = FAIL: the run stops, only checks.csv is written (D04).
-- Today (output/checks.csv): pass, 0 rows.

-- 1. every allocated row says where it went
SELECT line_id, game_or_bucket, 'no game or bucket' AS problem, amount_usd
FROM allocation
WHERE status = 'allocated' AND game_or_bucket IS NULL
UNION ALL
-- 2. the side is one of the two sides (R07, R09)
SELECT line_id, game_or_bucket, 'side is not BR Games or US Games', amount_usd
FROM allocation
WHERE status = 'allocated' AND (side IS NULL OR side NOT IN ('BR Games', 'US Games'))
UNION ALL
-- 3. a direct cost never changes entity: bearing = booked (R06)
SELECT line_id, game_or_bucket, 'direct row with bearing group not equal to booked group', amount_usd
FROM allocation
WHERE status = 'allocated' AND cost_type = 'direct' AND bearing_group IS DISTINCT FROM booked_group
UNION ALL
-- 4. a pool piece goes to a game that is really in that pool (R05)
SELECT a.line_id, a.game_or_bucket, 'pool piece for a game not in the pool', a.amount_usd
FROM allocation a
WHERE a.status = 'allocated' AND a.pool_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM pools p WHERE p.pool_id = a.pool_id AND p.game = a.game_or_bucket)
UNION ALL
-- 5. an indirect row has the bearing group from its bucket's row (R09)
SELECT line_id, game_or_bucket, 'indirect row with no bearing group', amount_usd
FROM allocation
WHERE status = 'allocated' AND cost_type = 'indirect' AND bearing_group IS NULL
