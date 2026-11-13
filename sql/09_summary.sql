-- Amount by booked group x side, for each month and for the quarter (R11).
-- Out-of-scope lines are left out; unallocated dollars get their own column.

CREATE OR REPLACE TABLE summary AS
WITH by_month AS (
    SELECT
        month AS period,
        booked_group,
        coalesce(SUM(amount_usd) FILTER (WHERE status = 'allocated' AND side = 'BR Games'), 0) AS br_games,
        coalesce(SUM(amount_usd) FILTER (WHERE status = 'allocated' AND side = 'US Games'), 0) AS us_games,
        coalesce(SUM(amount_usd) FILTER (WHERE status = 'unallocated'), 0) AS unallocated,
        SUM(amount_usd) AS total
    FROM allocation
    WHERE status <> 'out_of_scope'
    GROUP BY month, booked_group
),
-- The quarter label comes from the ledger's months, e.g. 2026-Q1
quarter AS (
    SELECT strftime(min(CAST(month || '-01' AS DATE)), '%Y') || '-Q'
           || quarter(min(CAST(month || '-01' AS DATE))) AS label
    FROM ledger
)
SELECT * FROM by_month
UNION ALL
SELECT
    (SELECT label FROM quarter) AS period,
    booked_group,
    SUM(br_games),
    SUM(us_games),
    SUM(unallocated),
    SUM(total)
FROM by_month
GROUP BY booked_group;
