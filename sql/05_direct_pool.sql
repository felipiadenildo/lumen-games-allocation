-- Direct cost on a pool: split across the pool's games by FTE that month,
-- among the games with FTE > 0 (R5).

CREATE OR REPLACE TABLE pool_shares AS
SELECT
    p.pool_id,
    h.month,
    p.game,
    h.fte / SUM(h.fte) OVER (PARTITION BY p.pool_id, h.month) AS share
FROM pools p
JOIN headcount_games h ON h.game = p.game
WHERE h.fte > 0;

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
