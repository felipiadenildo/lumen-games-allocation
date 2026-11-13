-- R05, R06, R07, R09: every allocated row has a full, valid destination.
SELECT line_id, game_or_bucket, 'no game or bucket' AS problem, amount_usd
FROM allocation
WHERE status = 'allocated' AND game_or_bucket IS NULL
UNION ALL
SELECT line_id, game_or_bucket, 'side is not BR Games or US Games', amount_usd
FROM allocation
WHERE status = 'allocated' AND (side IS NULL OR side NOT IN ('BR Games', 'US Games'))
UNION ALL
SELECT line_id, game_or_bucket, 'direct row with bearing group not equal to booked group', amount_usd
FROM allocation
WHERE status = 'allocated' AND cost_type = 'direct' AND bearing_group IS DISTINCT FROM booked_group
UNION ALL
SELECT a.line_id, a.game_or_bucket, 'pool piece for a game not in the pool', a.amount_usd
FROM allocation a
WHERE a.status = 'allocated' AND a.pool_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM pools p WHERE p.pool_id = a.pool_id AND p.game = a.game_or_bucket)
UNION ALL
SELECT line_id, game_or_bucket, 'indirect row with no bearing group', amount_usd
FROM allocation
WHERE status = 'allocated' AND cost_type = 'indirect' AND bearing_group IS NULL
