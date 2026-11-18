-- Step 05 · Direct cost, pool (R05)
-- What:   a direct line whose cost center has a pool_id is split across the pool's games,
--         by each game's FTE that month, among the games with FTE > 0.
--         share(game) = fte(game, month) / sum of fte of the pool's games that month.
-- Example W02: L00054, January, pool NEW_SHARED, 21,972.14 USD -> 4 pieces (Pixel Farm 14.5/41, ...).
-- A game with 0 FTE or no headcount row that month gets nothing (Moon Miner in January).
-- If no game of the pool has FTE, the line gets no piece: 08 marks it nothing_to_split.
-- Reads:  pools, headcount_games, lines      Writes: pool_shares, pieces_pool

-- pool_shares: one row per pool, month and game with FTE > 0.
-- The window SUM(...) OVER (PARTITION BY pool_id, month) is the pool's total FTE that month.
CREATE OR REPLACE TABLE pool_shares AS
SELECT
    p.pool_id,
    h.month,
    p.game,
    h.fte / SUM(h.fte) OVER (PARTITION BY p.pool_id, h.month) AS share
FROM pools p
JOIN headcount_games h ON h.game = p.game
WHERE h.fte > 0;

-- pieces_pool: each pool line gets one piece per game of its pool that month (inner join:
-- no FTE that month -> no piece -> nothing_to_split in 08).
CREATE OR REPLACE TABLE pieces_pool AS
SELECT
    l.line_id,
    s.game AS game_or_bucket,
    s.share
FROM lines l
JOIN pool_shares s ON s.pool_id = l.pool_id AND s.month = l.month
WHERE l.line_reason IS NULL
  AND l.cost_type = 'direct'
  AND l.pool_id IS NOT NULL;
