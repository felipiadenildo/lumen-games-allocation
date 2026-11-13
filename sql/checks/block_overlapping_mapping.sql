-- Q3: at most one mapping row is valid for a game or bucket in each ledger month (R10).
SELECT
    m.game_group,
    l.month,
    COUNT(*) AS valid_rows
FROM (SELECT DISTINCT month FROM ledger) l
JOIN game_mapping m
    ON CAST(l.month || '-01' AS DATE) BETWEEN m.start_date AND m.end_date
GROUP BY m.game_group, l.month
HAVING COUNT(*) > 1
