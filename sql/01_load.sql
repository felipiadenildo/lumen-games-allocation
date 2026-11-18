-- Step 01 · Load
-- What:   reads the 8 CSV files in data/ into DuckDB tables with the same names.
-- How:    every column is read as text (all_varchar), then only numbers and dates are cast on purpose:
--         ledger.amount_usd -> DECIMAL(18, 2) (exact cents), headcount_games.fte -> DOUBLE,
--         game_mapping.start_date / end_date -> DATE. A value that can't be cast stops the run (D05, D04).
-- Why:    reading as text keeps codes like '1001' or '3999' exactly as written (no lost zeros, no guessed types).
-- Names are not changed here: 02_clean trims them and logs each change.
-- Reads:  data/*.csv          Writes: ledger, entities, accounts, cost_centers, pools,
--                                     headcount_games, headcount_employees, game_mapping

-- The fact table: one row per ledger line. Only the amount is cast.
CREATE OR REPLACE TABLE ledger AS
SELECT
    line_id,
    month,
    entity,
    account,
    cost_center,
    CAST(amount_usd AS DECIMAL(18, 2)) AS amount_usd
FROM read_csv('data/ledger.csv', all_varchar = true);

-- Lookups, kept as text: entities (entity -> entity_group), accounts (account -> account_group),
-- cost_centers (department, and game or pool_id).
CREATE OR REPLACE TABLE entities AS
SELECT * FROM read_csv('data/entities.csv', all_varchar = true);

CREATE OR REPLACE TABLE accounts AS
SELECT * FROM read_csv('data/accounts.csv', all_varchar = true);

CREATE OR REPLACE TABLE cost_centers AS
SELECT * FROM read_csv('data/cost_centers.csv', all_varchar = true);

-- Weights: pools (which games a shared team works for), headcount_games (FTE per game and month),
-- headcount_employees (one row per employee and month).
CREATE OR REPLACE TABLE pools AS
SELECT * FROM read_csv('data/pools.csv', all_varchar = true);

CREATE OR REPLACE TABLE headcount_games AS
SELECT
    month,
    game,
    CAST(fte AS DOUBLE) AS fte
FROM read_csv('data/headcount_games.csv', all_varchar = true);

CREATE OR REPLACE TABLE headcount_employees AS
SELECT * FROM read_csv('data/headcount_employees.csv', all_varchar = true);

-- The side mapping: one row per game or bucket and period, with dates (R10).
CREATE OR REPLACE TABLE game_mapping AS
SELECT
    game_group,
    category,
    bearing_group,
    side,
    CAST(start_date AS DATE) AS start_date,
    CAST(end_date AS DATE) AS end_date
FROM read_csv('data/game_mapping.csv', all_varchar = true);
