-- Load every input file as text, then cast only the numbers and dates (D05).
-- Names are not changed here: the cleaning step trims them and logs each change.

CREATE OR REPLACE TABLE ledger AS
SELECT
    line_id,
    month,
    entity,
    account,
    cost_center,
    CAST(amount_usd AS DECIMAL(18, 2)) AS amount_usd
FROM read_csv('data/ledger.csv', all_varchar = true);

CREATE OR REPLACE TABLE entities AS
SELECT * FROM read_csv('data/entities.csv', all_varchar = true);

CREATE OR REPLACE TABLE accounts AS
SELECT * FROM read_csv('data/accounts.csv', all_varchar = true);

CREATE OR REPLACE TABLE cost_centers AS
SELECT * FROM read_csv('data/cost_centers.csv', all_varchar = true);

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

CREATE OR REPLACE TABLE game_mapping AS
SELECT
    game_group,
    category,
    bearing_group,
    side,
    CAST(start_date AS DATE) AS start_date,
    CAST(end_date AS DATE) AS end_date
FROM read_csv('data/game_mapping.csv', all_varchar = true);
