-- Step 06 · Indirect cost: buckets of employees (R08, Q04, D10)
-- What:   an indirect line (Engineering, Marketing, People, Operations) is split across buckets,
--         by each bucket's share of ALL the company's employees that month (Q04: whole company).
-- Bucket: first word of the employee's category + '_' + the entity group of the employee's entity, lower case.
--         'Live Games' + LGB (group BR) -> live_br;  'New Games' + LGF (group FI) -> new_fi.
-- Why both parts: the mapping gives each bucket its own bearing group and side (live_others -> BR, new_others -> US),
--         so neither the category nor the group alone decides the side.
-- Example W03: L00444, February, Finance, 21,346.02 USD, 123 employees -> 5 pieces (live_br 71/123, ...).
-- Reads:  headcount_employees, entities, lines      Writes: employee_buckets, bucket_shares, pieces_indirect

-- employee_buckets: one row per employee and month, with the bucket name.
-- LEFT JOIN + coalesce: an employee with an unknown entity stays counted, in *_unknown (D10).
CREATE OR REPLACE TABLE employee_buckets AS
SELECT
    h.month,
    lower(split_part(h.category, ' ', 1)) || '_' || lower(coalesce(e.entity_group, 'unknown')) AS bucket
FROM headcount_employees h
LEFT JOIN entities e ON e.entity = h.entity;

-- bucket_shares: employees in the bucket / all employees that month. Shares add up to 1 each month.
CREATE OR REPLACE TABLE bucket_shares AS
SELECT
    month,
    bucket,
    COUNT(*)::DOUBLE / SUM(COUNT(*)) OVER (PARTITION BY month) AS share
FROM employee_buckets
GROUP BY month, bucket;

-- pieces_indirect: every indirect line gets one piece per bucket of its month.
-- Q04's other reading (only the booking group's employees) would add the group to the join; see live.ipynb, M06.
CREATE OR REPLACE TABLE pieces_indirect AS
SELECT
    l.line_id,
    s.bucket AS game_or_bucket,
    s.share
FROM lines l
JOIN bucket_shares s ON s.month = l.month
WHERE l.line_reason IS NULL
  AND l.cost_type = 'indirect';
