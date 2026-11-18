-- Step 10 · Reconciliation: where every ledger dollar went (R01, R11)
-- ledger_total = out_of_scope + allocated + unallocated, per month and for the quarter.
-- The ledger total is read from the ledger itself, not from the allocation table, so a lost or doubled
-- row shows as a difference. block_reconciliation fails if any |difference| >= 0.005.
-- Reads:  ledger, allocation      Writes: reconciliation

CREATE OR REPLACE TABLE reconciliation AS
WITH ledger_by_month AS (
    SELECT month AS period, SUM(amount_usd) AS ledger_total
    FROM ledger
    GROUP BY month
),
allocation_by_month AS (
    SELECT
        month AS period,
        coalesce(SUM(amount_usd) FILTER (WHERE status = 'out_of_scope'), 0) AS out_of_scope,
        coalesce(SUM(amount_usd) FILTER (WHERE status = 'allocated'), 0) AS allocated,
        coalesce(SUM(amount_usd) FILTER (WHERE status = 'unallocated'), 0) AS unallocated
    FROM allocation
    GROUP BY month
),
by_month AS (
    SELECT
        l.period,
        l.ledger_total,
        a.out_of_scope,
        l.ledger_total - a.out_of_scope AS in_scope,
        a.allocated,
        a.unallocated
    FROM ledger_by_month l
    LEFT JOIN allocation_by_month a ON a.period = l.period
),
quarter AS (
    SELECT strftime(min(CAST(month || '-01' AS DATE)), '%Y') || '-Q'
           || quarter(min(CAST(month || '-01' AS DATE))) AS label
    FROM ledger
),
with_quarter AS (
    SELECT * FROM by_month
    UNION ALL
    SELECT
        (SELECT label FROM quarter),
        SUM(ledger_total),
        SUM(out_of_scope),
        SUM(in_scope),
        SUM(allocated),
        SUM(unallocated)
    FROM by_month
)
-- difference must be 0.00: checked by block_reconciliation (Q07 tolerance 0.005).
SELECT
    *,
    ledger_total - out_of_scope - allocated - unallocated AS difference
FROM with_quarter;
