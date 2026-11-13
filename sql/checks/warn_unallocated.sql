-- Q01: dollars that are kept but have no destination yet.
SELECT line_id, month, booked_entity, cost_center, game_or_bucket, reason, amount_usd
FROM allocation
WHERE status = 'unallocated'
ORDER BY line_id, game_or_bucket
