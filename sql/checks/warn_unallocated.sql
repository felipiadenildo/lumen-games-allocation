-- Check · warn_unallocated (warning, never stops the run)
-- What:  every row that is in scope but has no side yet, with its reason (Q01).
-- Why:   unallocated dollars are kept and visible instead of guessed; Tax needs to answer for them.
--        Want them to stop the run instead? Rename the file to block_unallocated.sql (scenario M08).
--
-- How run.py uses this file: it runs the query after steps 01-11 and counts the rows it returns.
--   0 rows = pass. Any row = warn: reported in checks.csv with the dollar total; the run continues.
-- Today (output/checks.csv): warn, 83 rows, 32,055.97 USD: L00169 cc 3999 (I01, 17,017.98) + 82 live_fi pieces in March (I03, 15,037.99).

SELECT line_id, month, booked_entity, cost_center, game_or_bucket, reason, amount_usd
FROM allocation
-- in scope but no side; out_of_scope rows are not here (they are excluded by rule, R01)
WHERE status = 'unallocated'
ORDER BY line_id, game_or_bucket
