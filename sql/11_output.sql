-- Step 11 · Output tables
-- The only place amounts are rounded to cents (Q07, D05): until here every piece keeps full precision.
-- Rows are always in the same order, so a rerun gives an identical file (easy to diff).
-- run.py copies output_* to output/*.csv only when no block_ check fails (D04).
-- Reads:  allocation, summary, summary_by_entity, reconciliation      Writes: output_allocation, output_summary,
--                                                                             output_summary_by_entity, output_reconciliation

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

CREATE OR REPLACE TABLE output_summary_by_entity AS
SELECT
    period,
    booked_entity,
    booked_group,
    CAST(br_games AS DECIMAL(18, 2)) AS br_games,
    CAST(us_games AS DECIMAL(18, 2)) AS us_games,
    CAST(unallocated AS DECIMAL(18, 2)) AS unallocated,
    CAST(total AS DECIMAL(18, 2)) AS total
FROM summary_by_entity
ORDER BY period, booked_entity;

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
