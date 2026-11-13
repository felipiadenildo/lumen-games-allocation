# Data issues

Three issues found in the inputs. Two leave dollars unallocated: 32,055.97 USD in the quarter (I01 + I03, `output/reconciliation.csv`). The third is fixed by the pipeline, and 753,920.16 USD depend on that fix (I02).

| ID | Table | Issue | Rows | Handling | Dollar impact |
|---|---|---|---|---|---|
| I01 | ledger, cost_centers | Cost center `3999` is used in the ledger but is not in `cost_centers.csv`, so the line has no department. (C07) | 1 line: `L00169`, 2026-02, LGB | Unallocated with reason `unknown_cost_center` (Q01). | 17,017.98 USD unallocated in 2026-02 (`output/reconciliation.csv`). |
| I02 | game_mapping | The game name `"Star Racer "` has a space at the end, so it matches no cost center, pool or headcount row. (C02, C08) | 1 mapping row | The pipeline removes the extra space before matching names. Only the name columns used to match tables are changed, and the run log lists every value it changed (Q08). | None after the fix. Without it, all 76 Star Racer pieces (single-game and pool lines), 753,920.16 USD, would have had no side and been unallocated (sum of `output/allocation.csv` rows for Star Racer). |
| I03 | headcount_employees, game_mapping | Bucket `live_fi` has no mapping row. It appears in 2026-03, when LGF has 2 Live Games employees. (C09) | 2 employees, 2026-03 | Their share of March indirect costs is unallocated with reason `no_mapping_row` (Q01). | 15,037.99 USD unallocated in 2026-03: one `live_fi` piece on each of the 82 indirect lines of March (`output/reconciliation.csv`: all of March's unallocated amount is I03). |

## Checked and fine

- No row appears twice in any table, using the key the BRIEF states for each table (C01).
- All amounts and FTE are numbers; every FTE is above zero (C03).
- 12 Depreciation lines (98,044.91 USD) and 3 zero lines are out of scope by rule R01 (C05).
- 2 credits stay in scope and are split like any other line (Q06, C03, C05).
- Every cost center matches its department: direct ones have a game or a pool, indirect ones neither (C06).
- Moon Miner has no mapping row in January, but no lines on its own cost center and no FTE that month, so nothing needs it (C10).
- No bucket row says By entity, and the ledger covers the first quarter of 2026 (C11).
