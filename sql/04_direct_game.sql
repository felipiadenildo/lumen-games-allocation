-- Step 04 · Direct cost, single game (R04)
-- What:   a direct line whose cost center has a game becomes ONE piece: that game, share 1.
-- Example W01: L00105, cc 1001 Star Racer, 103,255.10 USD -> 1 piece, Star Racer, share 1.
-- 'piece' = one destination of a line. The column is game_or_bucket because indirect pieces (06) go to buckets.
-- Only lines with no reason yet (line_reason IS NULL) are split.
-- Reads:  lines      Writes: pieces_game (line_id, game_or_bucket, share)

-- 1.0::DOUBLE keeps the same type as the shares of 05 and 06, so the three can be stacked in 07.
CREATE OR REPLACE TABLE pieces_game AS
SELECT
    line_id,
    game AS game_or_bucket,
    1.0::DOUBLE AS share
FROM lines
WHERE line_reason IS NULL
  AND cost_type = 'direct'
  AND game IS NOT NULL;
