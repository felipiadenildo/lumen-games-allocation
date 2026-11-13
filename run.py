"""Run the allocation pipeline: the SQL steps, then the checks, then the output files.

Usage, from the repo root:  python run.py

All the data work is in sql/. This script only runs the files in name order,
runs the checks in sql/checks/ and writes output/ (decisions 1, 2, 4 and 7 in docs/design.md).
"""

from pathlib import Path

import duckdb

SQL = Path("sql")

con = duckdb.connect()

# 1. The steps, in name order: 01_load.sql, 02_clean.sql, ...
for step in sorted(SQL.glob("*.sql")):
    print(f"step  {step.name}")
    con.execute(step.read_text())
