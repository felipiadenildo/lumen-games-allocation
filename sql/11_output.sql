-- The three result files as they are written: amounts rounded to cents only here (decision 5, Q7),
-- rows always in the same order. run.py copies these tables to output/ when no block_ check fails.

CREATE OR REPLACE TABLE output_allocation AS
SELECT
    * REPLACE (CAST(amount_usd AS DECIMAL(18, 2)) AS amount_usd)
FROM allocation
ORDER BY line_id, game_or_bucket NULLS FIRST;

CREATE OR REPLACE TABLE output_summary AS
SELECT
    period,
    booked_group,
    CAST(br_games AS DECIMAL(18, 2)) AS br_games,
    CAST(us_games AS DECIMAL(18, 2)) AS us_games,
    CAST(unallocated AS DECIMAL(18, 2)) AS unallocated,
    CAST(total AS DECIMAL(18, 2)) AS total
FROM summary
ORDER BY period, booked_group;

CREATE OR REPLACE TABLE output_reconciliation AS
SELECT
    period,
    CAST(ledger_total AS DECIMAL(18, 2)) AS ledger_total,
    CAST(out_of_scope AS DECIMAL(18, 2)) AS out_of_scope,
    CAST(in_scope AS DECIMAL(18, 2)) AS in_scope,
    CAST(allocated AS DECIMAL(18, 2)) AS allocated,
    CAST(unallocated AS DECIMAL(18, 2)) AS unallocated,
    CAST(difference AS DECIMAL(18, 2)) AS difference
FROM reconciliation
ORDER BY period;
