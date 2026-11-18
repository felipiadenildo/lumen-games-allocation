-- Step 03 · Lines: one row per ledger line, with everything the next steps need
-- What:   joins each ledger line to its entity, account and cost center, decides its cost type,
--         and gives a reason when the line stops here (it is never split).
-- Rules:  R01 scope (zero amount, Depreciation), R02 booked group = the entity's entity_group,
--         R03 cost type from the department, Q01 unknown codes stay visible as unallocated.
-- Why LEFT JOIN: a line whose entity, account or cost center is missing must not disappear;
--         it stays with a reason (unknown_cost_center for L00169, I01).
-- Reads:  ledger, entities, accounts, cost_centers     Writes: lines

CREATE OR REPLACE TABLE lines AS
-- joined: the ledger line with its lookups. The *_found flags say which lookup failed.
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
        -- R03: the department decides the path. Any other department -> NULL -> unknown_department below.
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
-- with_reason: the first check that fails gives the reason; NULL = the line goes on to be split.
-- The order matters: scope first (R01), then the lookups, then the cost center's shape (Q01).
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
    -- R01: these two reasons take a line out of scope; any other reason keeps it in scope, unallocated.
    -- To exclude another account group: add its WHEN above and its reason here.
    coalesce(line_reason IN ('zero_amount', 'depreciation'), false) AS out_of_scope
FROM with_reason;
