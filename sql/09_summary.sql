-- Step 09 · Summaries: amount by booked entity / booked group x side, per month and quarter (R11)
-- What:   in-scope rows only. br_games and us_games add the allocated rows of each side;
--         unallocated has its own column, so total = everything in scope.
-- summary_by_entity: month x booked entity (what Tax reads). summary: the same added up by booked group (BRIEF item 2).
-- The quarter row is the sum of the months; its label (2026-Q1) is computed from the ledger months.
-- Reads:  allocation, ledger      Writes: summary_by_entity, summary

-- FILTER (WHERE ...) adds only the rows that pass the condition; coalesce turns 'no rows' into 0.
CREATE OR REPLACE TABLE summary_by_entity AS
WITH by_month AS (
    SELECT
        month AS period,
        booked_entity,
        booked_group,
        coalesce(SUM(amount_usd) FILTER (WHERE status = 'allocated' AND side = 'BR Games'), 0) AS br_games,
        coalesce(SUM(amount_usd) FILTER (WHERE status = 'allocated' AND side = 'US Games'), 0) AS us_games,
        coalesce(SUM(amount_usd) FILTER (WHERE status = 'unallocated'), 0) AS unallocated,
        SUM(amount_usd) AS total
    FROM allocation
    WHERE status <> 'out_of_scope'
    GROUP BY month, booked_entity, booked_group
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
    booked_entity,
    booked_group,
    SUM(br_games),
    SUM(us_games),
    SUM(unallocated),
    SUM(total)
FROM by_month
GROUP BY booked_entity, booked_group;

-- The booked group view adds up its entities
CREATE OR REPLACE TABLE summary AS
SELECT
    period,
    booked_group,
    SUM(br_games) AS br_games,
    SUM(us_games) AS us_games,
    SUM(unallocated) AS unallocated,
    SUM(total) AS total
FROM summary_by_entity
GROUP BY period, booked_group;
