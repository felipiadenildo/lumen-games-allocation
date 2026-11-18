-- Step 08 · The allocation table: every ledger line, one row per piece (D03, D09, D11)
-- Part 1: lines that were split -> one row per piece, amount = line amount x share,
--         status allocated, or unallocated with the piece's reason.
-- Part 2: lines with no piece -> one row, share 1, status out_of_scope or unallocated with the line's reason.
-- So every ledger dollar is in exactly one place, and the shares of each line add up to 1 (block_shares_not_one).
-- Reads:  lines, pieces_mapped, pieces      Writes: allocation

CREATE OR REPLACE TABLE allocation AS
-- Part 1: one row per piece of the lines that were split.
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

-- Part 2: lines that got no piece at all.
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
    -- A line that passed every step but got no piece had nothing to split by (R05, R08)
    coalesce(l.line_reason, 'nothing_to_split') AS reason
FROM lines l
WHERE l.line_id NOT IN (SELECT line_id FROM pieces);
