# Data issues

Three issues found in the inputs. Two leave dollars unallocated: 32,055.97 USD in the quarter (D1 + D3, `output/reconciliation.csv`). The third is fixed by the pipeline, and 753,920.16 USD depend on that fix (D2).

| # | Table | Issue | Rows | Handling | Dollar impact |
|---|---|---|---|---|---|
| D1 | ledger, cost_centers | Cost center `3999` is used in the ledger but is not in `cost_centers.csv`, so the line has no department. (check 7) | 1 line: `L00169`, 2026-02, LGB | Unallocated with reason `unknown_cost_center` (Q1). | 17,017.98 USD unallocated in 2026-02 (`output/reconciliation.csv`). |
| D2 | game_mapping | The game name `"Star Racer "` has a space at the end, so it matches no cost center, pool or headcount row. (checks 2, 8) | 1 mapping row | The pipeline removes the extra space before matching names. Only the name columns used to match tables are changed, and the run log lists every value it changed (Q8). | None after the fix. Without it, all 76 Star Racer pieces (single-game and pool lines), 753,920.16 USD, would have had no side and been unallocated (sum of `output/allocation.csv` rows for Star Racer). |
| D3 | headcount_employees, game_mapping | Bucket `live_fi` has no mapping row. It appears in 2026-03, when LGF has 2 Live Games employees. (check 9) | 2 employees, 2026-03 | Their share of March indirect costs is unallocated with reason `no_mapping_row` (Q1). | 15,037.99 USD unallocated in 2026-03: one `live_fi` piece on each of the 82 indirect lines of March (`output/reconciliation.csv`, March unallocated after D1). |

## Checked and fine

- No row appears twice in any table, using the key the BRIEF states for each table (check 1).
- All amounts and FTE are numbers; every FTE is above zero (check 3).
- 12 Depreciation lines (98,044.91 USD) and 3 zero lines are out of scope by rule R1 (check 5).
- 2 credits stay in scope and are split like any other line (checks 3, 5, Q6).
- Every cost center matches its department: direct ones have a game or a pool, indirect ones neither (check 6).
- Moon Miner has no mapping row in January, but no lines on its own cost center and no FTE that month, so nothing needs it (check 10).
- No bucket row says By entity, and the ledger covers the first quarter of 2026 (check 11).
