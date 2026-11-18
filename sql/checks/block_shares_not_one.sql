-- Check · block_shares_not_one
-- What:  line by line, starting FROM the ledger: every ledger line is in the allocation table, and its shares
--        add up to 1 (R04, R05, R08, D11).
-- Why:   it catches what a total could hide: a lost line (no rows -> total share 0), a line split twice
--        (total share 2), or a split that doesn't add up. Works because every row has a share (D11).
--
-- How run.py uses this file: it runs the query after steps 01-11 and counts the rows it returns.
--   0 rows = pass. Any row = FAIL: the run stops; the row gives the line and its total share.
-- Today (output/checks.csv): pass, 0 rows.

SELECT l.line_id, coalesce(SUM(a.share), 0) AS total_share
FROM ledger l
-- LEFT JOIN from the ledger: a line missing from the allocation gets total share 0 and fails
LEFT JOIN allocation a ON a.line_id = l.line_id
GROUP BY l.line_id
-- shares are DOUBLE (D05), so compare with a tiny tolerance, not '= 1'
HAVING abs(coalesce(SUM(a.share), 0) - 1) > 1e-9
