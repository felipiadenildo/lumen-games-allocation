-- Check · block_unmatched_game_names
-- What:  every game named in pools.csv and headcount_games.csv has a row in game_mapping.csv (after the trim).
-- Why:   a misspelled game name there doesn't fail anywhere else: it just drops out of the pool split, and its
--        FTE share goes to the other games, moving dollars silently (Q08). Added after the adversarial review in F5
--        ("how could the numbers be wrong with every check passing?").
--
-- How run.py uses this file: it runs the query after steps 01-11 and counts the rows it returns.
--   0 rows = pass. Any row = FAIL: the run stops; the row gives the table and the unknown name.
-- Today (output/checks.csv): pass, 0 rows.

-- games in pools.csv with no mapping row
SELECT DISTINCT 'pools' AS table_name, p.game
FROM pools p
WHERE NOT EXISTS (SELECT 1 FROM game_mapping m WHERE m.game_group = p.game)
UNION ALL
-- games in headcount_games.csv with no mapping row
SELECT DISTINCT 'headcount_games', h.game
FROM headcount_games h
WHERE NOT EXISTS (SELECT 1 FROM game_mapping m WHERE m.game_group = h.game)
ORDER BY 1, 2
