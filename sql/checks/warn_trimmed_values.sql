-- Q8: every value the cleaning step changed.
SELECT table_name, column_name, '"' || before || '"' AS before, '"' || after || '"' AS after
FROM trimmed_values
