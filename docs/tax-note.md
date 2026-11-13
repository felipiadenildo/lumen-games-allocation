# Q1 2026 costs by side: note to the Tax team

**Summary.** Of the 6,539,250.85 USD of costs in scope this quarter, BR Games bears 4,642,414.76 USD (71.0%) and US
Games 1,864,780.12 USD (28.5%). 32,055.97 USD (0.5%) is not on a side yet; two open items below would place it. Every
dollar of the ledger is accounted for.

## Results

Cost booked by each entity in the quarter, and the side that bears it (USD):

| Entity | Booked, in scope | BR Games bears | US Games bears | Not yet on a side |
|---|---:|---:|---:|---:|
| LGB, Lumen Games Brasil | 4,463,769.40 | 3,865,691.60 | 570,224.08 | 27,853.72 |
| LGI, Lumen Games Inc | 1,452,760.63 | 583,080.12 | 866,375.87 | 3,304.64 |
| LGF, Lumen Games Finland | 350,704.82 | 145,078.73 | 205,052.25 | 573.84 |
| LGK, Lumen Games UK | 190,966.24 | 30,889.89 | 159,870.58 | 205.76 |
| LGC, Lumen Games Canada | 81,049.76 | 17,674.42 | 63,257.34 | 118.01 |
| **Total** | **6,539,250.85** | **4,642,414.76** | **1,864,780.12** | **32,055.97** |

By month (USD):

| Month | BR Games bears | US Games bears | Not yet on a side |
|---|---:|---:|---:|
| January | 1,641,493.80 | 525,433.04 | 0.00 |
| February | 1,533,249.68 | 625,710.42 | 17,017.98 |
| March | 1,467,671.27 | 713,636.68 | 15,037.99 |

US Games grows twice in the quarter. Moon Miner, a US Games game, has costs from February and none in January
(114,538.78 USD in February). On 1 March, Puzzle Pals moves from BR Games to US Games, as the mapping file sets
(106,298.56 USD in March).

Out of scope by the rules: 98,044.91 USD of depreciation (12 lines) and 3 lines with a zero amount. Each month by
entity is in `output/summary_by_entity.csv`; by entity group, in `output/summary.csv`.

## Data issues found

1. **Cost center 3999 is missing from the cost center list.** One February line booked by LGB, 17,017.98 USD, has no
   department, so no rule applies to it. Not yet on a side.
2. **Finland's Live Games employees have no mapping row.** LGF has 2 Live Games employees from March, and the mapping
   file (the list that says which side each game and employee group belongs to) doesn't say which side bears their
   share of corporate costs: 15,037.99 USD in March. Not yet on a side.
3. **A game name has an extra space.** The mapping file writes "Star Racer " with a space at the end, so the name
   matched none of the game's costs. The space is removed before matching; 753,920.16 USD of Star Racer costs depend
   on this correction. Nothing is left off a side.

## Assumptions used

- **Corporate costs are shared across the whole company.** Engineering, Marketing, People and Operations costs are
  split by each month's employees of all entities. If each entity's corporate costs should be split only among its
  own employees, BR Games would bear about 180,980 USD less and US Games about 188,845 USD more in the quarter; the
  difference, about 7,865 USD, is cost now not on a side that this split would place.
- **Credits are shared like costs**, with the same split. The quarter has 2 credit lines.
- **Costs that can't be placed stay visible** as "not yet on a side", rather than being assigned to a side by guess.

## Open items for Tax

1. **Cost center 3999:** its department, or its game. Places 17,017.98 USD.
2. **Finland's Live Games employees from March:** the side and the entity group that bear their share. Places
   15,037.99 USD.
3. **Corporate cost split:** confirmation that it uses the whole company's employees (first assumption).
4. **"Star Racer " in the mapping file:** a fix at the source, so the name no longer needs correcting.

<sub>Details: issues I01–I03 in [`data-issues.md`](data-issues.md); assumptions Q01, Q04 and Q06 in
[`design.md`](design.md#open-questions).</sub>
