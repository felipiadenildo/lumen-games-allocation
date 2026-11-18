-- Check · block_months_outside_quarter
-- What:  the ledger months are exactly the three months of one calendar quarter.
-- Why:   the quarter label ('2026-Q1') and the quarter totals are built from the data, not written in the code (Q09).
--        If a month of another quarter came in, or one month were missing, the 'quarter' would be wrong.
--
-- How run.py uses this file: it runs the query after steps 01-11 and counts the rows it returns.
--   0 rows = pass. Any row = FAIL: the run stops; it returns every ledger month so you can see which one is off.
-- Today (output/checks.csv): pass, 0 rows.

-- the distinct months in the ledger, as the first day of each
WITH months AS (
    SELECT DISTINCT CAST(month || '-01' AS DATE) AS first_day FROM ledger
)
SELECT strftime(first_day, '%Y-%m') AS month
FROM months
-- fail when there aren't exactly 3 months, or they span more than one (year, quarter)
WHERE (SELECT COUNT(*) FROM months) <> 3
   OR (SELECT COUNT(DISTINCT (year(first_day), quarter(first_day))) FROM months) <> 1
ORDER BY month
