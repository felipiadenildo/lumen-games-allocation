-- Step 02 · Clean
-- What:   removes spaces at the start and end of the name columns that are used to match tables (Q08, D08).
-- Why:    game_mapping has 'Star Racer ' (I02). Without the trim it matches no cost center, pool or headcount row,
--         and 753,920.16 USD of Star Racer pieces would have no side.
-- How:    first keep every value that will change (before/after) in trimmed_values, then UPDATE the tables.
--         warn_trimmed_values reports the log, so no value changes silently.
-- Only these columns: game names, pool ids, departments, categories, entity groups, account groups.
-- Reads:  the 8 input tables    Writes: trimmed_values; updates the input tables in place

CREATE OR REPLACE TABLE trimmed_values AS
SELECT 'game_mapping' AS table_name, 'game_group' AS column_name, game_group AS before, trim(game_group) AS after
FROM game_mapping WHERE game_group <> trim(game_group)
UNION ALL
SELECT 'cost_centers', 'game', game, trim(game) FROM cost_centers WHERE game <> trim(game)
UNION ALL
SELECT 'cost_centers', 'pool_id', pool_id, trim(pool_id) FROM cost_centers WHERE pool_id <> trim(pool_id)
UNION ALL
SELECT 'cost_centers', 'department', department, trim(department) FROM cost_centers WHERE department <> trim(department)
UNION ALL
SELECT 'pools', 'pool_id', pool_id, trim(pool_id) FROM pools WHERE pool_id <> trim(pool_id)
UNION ALL
SELECT 'pools', 'game', game, trim(game) FROM pools WHERE game <> trim(game)
UNION ALL
SELECT 'headcount_games', 'game', game, trim(game) FROM headcount_games WHERE game <> trim(game)
UNION ALL
SELECT 'headcount_employees', 'category', category, trim(category) FROM headcount_employees WHERE category <> trim(category)
UNION ALL
SELECT 'entities', 'entity_group', entity_group, trim(entity_group) FROM entities WHERE entity_group <> trim(entity_group)
UNION ALL
SELECT 'accounts', 'account_group', account_group, trim(account_group) FROM accounts WHERE account_group <> trim(account_group);

-- Now change the values, the same columns as logged above.
UPDATE game_mapping SET game_group = trim(game_group);
UPDATE cost_centers SET game = trim(game), pool_id = trim(pool_id), department = trim(department);
UPDATE pools SET pool_id = trim(pool_id), game = trim(game);
UPDATE headcount_games SET game = trim(game);
UPDATE headcount_employees SET category = trim(category);
UPDATE entities SET entity_group = trim(entity_group);
UPDATE accounts SET account_group = trim(account_group);
