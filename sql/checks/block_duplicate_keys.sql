-- Check · block_duplicate_keys
-- What:  every input table is unique at the grain the BRIEF states (after the trim in step 02).
-- Why:   a duplicate key multiplies dollars in a join: two cost_centers rows for one code would double every
--        line of that cost center; a ledger line_id twice would be allocated twice (Q02).
-- One SELECT per table, GROUP BY its key, HAVING COUNT(*) > 1 keeps only the repeated keys.
--
-- How run.py uses this file: it runs the query after steps 01-11 and counts the rows it returns.
--   0 rows = pass. Any row = FAIL: the run stops (D04); the row says which table and key, and how many copies.
-- Today (output/checks.csv): pass, 0 rows. Live: duplicate L00105 in the ledger and this check fails.

-- ledger: one row per line_id
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
-- pools: one row per pool and game
SELECT 'pools', pool_id || ' / ' || game, COUNT(*)
FROM pools GROUP BY pool_id, game HAVING COUNT(*) > 1
UNION ALL
-- headcount: one row per month and game / per month and employee
SELECT 'headcount_games', month || ' / ' || game, COUNT(*)
FROM headcount_games GROUP BY month, game HAVING COUNT(*) > 1
UNION ALL
SELECT 'headcount_employees', month || ' / ' || employee_id, COUNT(*)
FROM headcount_employees GROUP BY month, employee_id HAVING COUNT(*) > 1
UNION ALL
-- mapping: one row per game or bucket and start date (overlaps: block_overlapping_mapping)
SELECT 'game_mapping', game_group || ' / ' || start_date, COUNT(*)
FROM game_mapping GROUP BY game_group, start_date HAVING COUNT(*) > 1
