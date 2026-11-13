-- Direct cost on a cost center with a game: 100% to that game (R4).

CREATE OR REPLACE TABLE pieces_game AS
SELECT
    line_id,
    game AS game_or_bucket,
    1.0::DOUBLE AS share
FROM lines
WHERE line_reason IS NULL
  AND cost_type = 'direct'
  AND game IS NOT NULL;
