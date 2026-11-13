-- Q02: every input table is unique at the grain the BRIEF states (after trimming).
-- A duplicate key would multiply dollars in a join.
SELECT 'ledger' AS table_name, line_id AS key, COUNT(*) AS copies
FROM ledger GROUP BY line_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'entities', entity, COUNT(*)
FROM entities GROUP BY entity HAVING COUNT(*) > 1
UNION ALL
SELECT 'accounts', account, COUNT(*)
FROM accounts GROUP BY account HAVING COUNT(*) > 1
UNION ALL
SELECT 'cost_centers', cost_center, COUNT(*)
FROM cost_centers GROUP BY cost_center HAVING COUNT(*) > 1
UNION ALL
SELECT 'pools', pool_id || ' / ' || game, COUNT(*)
FROM pools GROUP BY pool_id, game HAVING COUNT(*) > 1
UNION ALL
SELECT 'headcount_games', month || ' / ' || game, COUNT(*)
FROM headcount_games GROUP BY month, game HAVING COUNT(*) > 1
UNION ALL
SELECT 'headcount_employees', month || ' / ' || employee_id, COUNT(*)
FROM headcount_employees GROUP BY month, employee_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'game_mapping', game_group || ' / ' || start_date, COUNT(*)
FROM game_mapping GROUP BY game_group, start_date HAVING COUNT(*) > 1
