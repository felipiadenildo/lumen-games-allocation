-- Check · block_overlapping_mapping
-- What:  for each game or bucket, at most one mapping row is valid in each ledger month (R10, Q03).
-- Why:   step 07 joins each piece to the mapping row valid that month. Two valid rows would duplicate the piece:
--        the same dollars on both sides. Example: move Puzzle Pals' first end_date to March without moving the
--        second row's start_date, and March has two valid rows -> blocked.
--
-- How run.py uses this file: it runs the query after steps 01-11 and counts the rows it returns.
--   0 rows = pass. Any row = FAIL: the run stops; the row gives the game or bucket, the month and how many rows are valid.
-- Today (output/checks.csv): pass, 0 rows.

SELECT
    m.game_group,
    l.month,
    COUNT(*) AS valid_rows
-- the same date rule as step 07: a row applies when the month's first day is between its dates
FROM (SELECT DISTINCT month FROM ledger) l
JOIN game_mapping m
    ON CAST(l.month || '-01' AS DATE) BETWEEN m.start_date AND m.end_date
GROUP BY m.game_group, l.month
-- more than one valid row for the same game or bucket in the same month
HAVING COUNT(*) > 1
ORDER BY m.game_group, l.month
