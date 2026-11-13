-- Trim the name columns used to match tables (Q8, decision 8).
-- First keep every value that will change, then change it.

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
SELECT 'entities', 'entity_group', entity_group, trim(entity_group) FROM entities WHERE entity_group <> trim(entity_group);

UPDATE game_mapping SET game_group = trim(game_group);
UPDATE cost_centers SET game = trim(game), pool_id = trim(pool_id), department = trim(department);
UPDATE pools SET pool_id = trim(pool_id), game = trim(game);
UPDATE headcount_games SET game = trim(game);
UPDATE headcount_employees SET category = trim(category);
UPDATE entities SET entity_group = trim(entity_group);
