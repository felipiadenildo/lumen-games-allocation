-- Indirect cost: split across buckets by each bucket's share of the month's employees,
-- all entities and both categories (R8, Q4).
-- Bucket = first word of the category + entity group, in lower case (live_br, new_fi, ...).
-- An employee whose entity is missing goes to live_unknown or new_unknown (Notes).

CREATE OR REPLACE TABLE employee_buckets AS
SELECT
    h.month,
    lower(split_part(h.category, ' ', 1)) || '_' || lower(coalesce(e.entity_group, 'unknown')) AS bucket
FROM headcount_employees h
LEFT JOIN entities e ON e.entity = h.entity;

CREATE OR REPLACE TABLE bucket_shares AS
SELECT
    month,
    bucket,
    COUNT(*)::DOUBLE / SUM(COUNT(*)) OVER (PARTITION BY month) AS share
FROM employee_buckets
GROUP BY month, bucket;

CREATE OR REPLACE TABLE pieces_indirect AS
SELECT
    l.line_id,
    s.bucket AS game_or_bucket,
    s.share
FROM lines l
JOIN bucket_shares s ON s.month = l.month
WHERE l.line_reason IS NULL
  AND l.cost_type = 'indirect';
