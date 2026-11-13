"""Run the allocation pipeline: the SQL steps, then the checks, then the output files.

Usage, from the repo root:  python run.py

All the data work is in sql/. This script only runs the files in name order,
runs the checks in sql/checks/ and writes output/ (decisions 1, 2, 4 and 7 in docs/design.md).
"""

import sys
from pathlib import Path

import duckdb

SQL = Path("sql")
CHECKS = SQL / "checks"
OUTPUT = Path("output")

# The result files. They are deleted when a block_ check fails, so no stale number stays in output/.
RESULTS = ["allocation", "summary", "reconciliation"]

con = duckdb.connect()

# Remove the previous results first, so a run that stops on an error or a block_ check
# leaves no stale number in output/ (decision 4).
OUTPUT.mkdir(exist_ok=True)
for name in RESULTS + ["checks"]:
    (OUTPUT / f"{name}.csv").unlink(missing_ok=True)

# 1. The steps, in name order: 01_load.sql, 02_clean.sql, ...
for step in sorted(SQL.glob("*.sql")):
    print(f"step  {step.name}")
    con.execute(step.read_text())

# 2. The checks. Each query returns the rows it found; no rows means pass.
con.execute("""
    CREATE TABLE checks ("check" VARCHAR, level VARCHAR, result VARCHAR, rows INTEGER, amount_usd DECIMAL(18, 2))
""")
failed = []

for check in sorted(CHECKS.glob("*.sql")):
    name = check.stem
    level = "block" if name.startswith("block_") else "warn"
    # Keep the rows found in a table, so they can be counted, summed and shown
    con.execute(f"CREATE OR REPLACE TABLE found AS {check.read_text()}")
    rows = con.execute("SELECT COUNT(*) FROM found").fetchone()[0]

    # amount_usd only for checks that return dollars
    amount = None
    if "amount_usd" in con.table("found").columns:
        amount = con.execute("SELECT SUM(amount_usd) FROM found").fetchone()[0]

    if rows == 0:
        result = "pass"
    elif level == "warn":
        result = "warn"
    else:
        result = "fail"
        failed.append(name)

    con.execute("INSERT INTO checks VALUES (?, ?, ?, ?, ?)", [name, level, result, rows, amount])
    print(f"check {name}: {result}, {rows} rows")

    # Show what was found: every trimmed value (Q8), the first 10 rows of any other check
    if rows > 0:
        limit = "" if name == "warn_trimmed_values" else "LIMIT 10"
        print(con.sql(f"SELECT * FROM found {limit}"))

# 3. The output files. checks.csv is always written.
con.execute(f"COPY checks TO '{OUTPUT / 'checks.csv'}' (HEADER)")

if failed:
    print(f"Blocked by: {', '.join(failed)}. No results written; see output/checks.csv")
    sys.exit(1)

for name in RESULTS:
    con.execute(f"COPY output_{name} TO '{OUTPUT / f'{name}.csv'}' (HEADER)")
    print(f"wrote output/{name}.csv")
