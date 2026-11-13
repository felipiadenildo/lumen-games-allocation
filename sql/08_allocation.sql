-- The allocation table: every ledger line, one row per piece (decision 3).
-- A line with no piece (out of scope, or stopped before the split) has one row with share 1.

CREATE OR REPLACE TABLE allocation AS
SELECT
    l.line_id,
    l.month,
    l.booked_entity,
    l.booked_group,
    l.account,
    l.account_name,
    l.account_group,
    l.cost_center,
    l.cost_center_name,
    l.department,
    l.pool_id,
    l.cost_type,
    p.game_or_bucket,
    -- Bearing group and side only on allocated rows
    CASE WHEN p.reason IS NULL THEN p.bearing_group END AS bearing_group,
    CASE WHEN p.reason IS NULL THEN p.side END AS side,
    p.share,
    l.amount_usd * p.share AS amount_usd,
    CASE WHEN p.reason IS NULL THEN 'allocated' ELSE 'unallocated' END AS status,
    p.reason
FROM lines l
JOIN pieces_mapped p ON p.line_id = l.line_id

UNION ALL

SELECT
    l.line_id,
    l.month,
    l.booked_entity,
    l.booked_group,
    l.account,
    l.account_name,
    l.account_group,
    l.cost_center,
    l.cost_center_name,
    l.department,
    l.pool_id,
    l.cost_type,
    NULL AS game_or_bucket,
    NULL AS bearing_group,
    NULL AS side,
    1.0::DOUBLE AS share,
    l.amount_usd,
    CASE WHEN l.out_of_scope THEN 'out_of_scope' ELSE 'unallocated' END AS status,
    -- A line that passed every step but got no piece had nothing to split by (R5, R8)
    coalesce(l.line_reason, 'nothing_to_split') AS reason
FROM lines l
WHERE l.line_id NOT IN (SELECT line_id FROM pieces);
