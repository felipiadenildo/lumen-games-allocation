-- The shares of every ledger line add up to 1 (R04, R05, R08, D11), and every ledger line is in the allocation table.
SELECT l.line_id, coalesce(SUM(a.share), 0) AS total_share
FROM ledger l
LEFT JOIN allocation a ON a.line_id = l.line_id
GROUP BY l.line_id
HAVING abs(coalesce(SUM(a.share), 0) - 1) > 1e-9
