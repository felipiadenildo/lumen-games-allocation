-- Check · warn_trimmed_values (warning, never stops the run)
-- What:  every value the cleaning step (02) changed, before and after, in quotes so the spaces are visible.
-- Why:   no value changes silently (Q08, D08). This is where issue I02 shows: "Star Racer " -> "Star Racer";
--        753,920.16 USD depend on that fix.
--
-- How run.py uses this file: it runs the query after steps 01-11 and counts the rows it returns.
--   0 rows = pass. Any row = warn: reported in checks.csv and printed in full by run.py; the run continues.
-- Today (output/checks.csv): warn, 1 row (I02).

-- trimmed_values is written by step 02, one row per changed value
SELECT table_name, column_name, '"' || before || '"' AS before, '"' || after || '"' AS after
FROM trimmed_values
