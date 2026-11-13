-- R01, R11: ledger = out of scope + allocated + unallocated, and each summary total = in scope,
-- for each month and the quarter, within the Q07 tolerance.
SELECT period, 'ledger vs allocation' AS problem, difference AS amount_usd
FROM reconciliation
WHERE abs(difference) >= 0.005
UNION ALL
SELECT r.period, 'summary vs in scope', s.total - r.in_scope
FROM reconciliation r
LEFT JOIN (SELECT period, SUM(total) AS total FROM summary GROUP BY period) s ON s.period = r.period
WHERE s.total IS NULL OR abs(s.total - r.in_scope) >= 0.005
UNION ALL
SELECT r.period, 'summary by entity vs in scope', s.total - r.in_scope
FROM reconciliation r
LEFT JOIN (SELECT period, SUM(total) AS total FROM summary_by_entity GROUP BY period) s ON s.period = r.period
WHERE s.total IS NULL OR abs(s.total - r.in_scope) >= 0.005
