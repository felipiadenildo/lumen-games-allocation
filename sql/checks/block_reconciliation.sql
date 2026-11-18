-- Check · block_reconciliation
-- What:  three equalities, per month and for the quarter, within half a cent (Q07 tolerance 0.005):
--        1. ledger total = out of scope + allocated + unallocated   (step 10, R11)
--        2. summary total = in scope                                 (the table Tax reads)
--        3. summary by entity total = in scope
-- Why:   the ledger side of 1 is summed from the raw ledger, the other side from the allocation table, so a line
--        lost or duplicated anywhere in between shows here. 2 and 3 tie the reports to the same total.
--
-- How run.py uses this file: it runs the query after steps 01-11 and counts the rows it returns.
--   0 rows = pass. Any row = FAIL: the run stops; the row says which period and which equality, and by how much.
-- Today (output/checks.csv): pass, 0 rows (difference 0.00 in every month).

-- 1. ledger = out of scope + allocated + unallocated (difference computed in step 10)
SELECT period, 'ledger vs allocation' AS problem, difference AS amount_usd
FROM reconciliation
WHERE abs(difference) >= 0.005
UNION ALL
-- 2. the summary (booked group x side) adds up to in scope; a missing period also fails
SELECT r.period, 'summary vs in scope', s.total - r.in_scope
FROM reconciliation r
LEFT JOIN (SELECT period, SUM(total) AS total FROM summary GROUP BY period) s ON s.period = r.period
WHERE s.total IS NULL OR abs(s.total - r.in_scope) >= 0.005
UNION ALL
-- 3. same for the summary by booked entity
SELECT r.period, 'summary by entity vs in scope', s.total - r.in_scope
FROM reconciliation r
LEFT JOIN (SELECT period, SUM(total) AS total FROM summary_by_entity GROUP BY period) s ON s.period = r.period
WHERE s.total IS NULL OR abs(s.total - r.in_scope) >= 0.005
