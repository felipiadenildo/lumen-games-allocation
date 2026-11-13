-- Every game in pools.csv and headcount_games.csv has a row in game_mapping.csv (after trimming).
-- A misspelled name there drops out of a pool split without any other error and moves dollars between games.
SELECT DISTINCT 'pools' AS table_name, p.game
FROM pools p
WHERE NOT EXISTS (SELECT 1 FROM game_mapping m WHERE m.game_group = p.game)
UNION ALL
SELECT DISTINCT 'headcount_games', h.game
FROM headcount_games h
WHERE NOT EXISTS (SELECT 1 FROM game_mapping m WHERE m.game_group = h.game)
ORDER BY 1, 2
