-- Q09: the ledger months are the three months of one calendar quarter.
-- Returns every ledger month when they are not.
WITH months AS (
    SELECT DISTINCT CAST(month || '-01' AS DATE) AS first_day FROM ledger
)
SELECT strftime(first_day, '%Y-%m') AS month
FROM months
WHERE (SELECT COUNT(*) FROM months) <> 3
   OR (SELECT COUNT(DISTINCT (year(first_day), quarter(first_day))) FROM months) <> 1
ORDER BY month
