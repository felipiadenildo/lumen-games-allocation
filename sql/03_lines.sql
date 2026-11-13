-- One row per ledger line, with its lookups, its cost type (R2, R3)
-- and the reason when the line stops before it is split (R1, Q1).

CREATE OR REPLACE TABLE lines AS
WITH joined AS (
    SELECT
        l.line_id,
        l.month,
        l.entity AS booked_entity,
        e.entity_group AS booked_group,
        l.account,
        a.account_name,
        a.account_group,
        l.cost_center,
        c.cost_center_name,
        c.department,
        c.pool_id,
        c.game,
        CASE
            WHEN c.department IN ('Live Games', 'New Games') THEN 'direct'
            WHEN c.department IN ('Engineering', 'Marketing', 'People', 'Operations') THEN 'indirect'
        END AS cost_type,
        l.amount_usd,
        a.account IS NOT NULL AS account_found,
        e.entity IS NOT NULL AS entity_found,
        c.cost_center IS NOT NULL AS cost_center_found
    FROM ledger l
    LEFT JOIN entities e ON e.entity = l.entity
    LEFT JOIN accounts a ON a.account = l.account
    LEFT JOIN cost_centers c ON c.cost_center = l.cost_center
),
with_reason AS (
    SELECT
        * EXCLUDE (account_found, entity_found, cost_center_found),
        -- The first step that fails gives the reason (see the Output section of docs/design.md)
        CASE
            WHEN amount_usd = 0 THEN 'zero_amount'
            WHEN NOT account_found THEN 'unknown_account'
            WHEN account_group = 'Depreciation' THEN 'depreciation'
            WHEN NOT entity_found THEN 'unknown_entity'
            WHEN NOT cost_center_found THEN 'unknown_cost_center'
            WHEN cost_type IS NULL THEN 'unknown_department'
            WHEN cost_type = 'direct' AND game IS NULL AND pool_id IS NULL THEN 'bad_cost_center'
            WHEN cost_type = 'direct' AND game IS NOT NULL AND pool_id IS NOT NULL THEN 'bad_cost_center'
        END AS line_reason
    FROM joined
)
SELECT
    *,
    -- R1: these two reasons take a line out of scope; any other reason keeps it in scope, unallocated.
    -- To exclude another account group: add its WHEN above and its reason here.
    coalesce(line_reason IN ('zero_amount', 'depreciation'), false) AS out_of_scope
FROM with_reason;
