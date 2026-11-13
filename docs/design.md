# Design

How the allocation works: what the BRIEF asks, the data, the decisions, the output, and how it was checked.

## Contents

| Section | What it answers | Phase |
|---|---|---|
| [IDs](#ids) | how rules, questions, decisions and the rest are numbered | |
| [Rules](#rules) | what the BRIEF asks, as testable statements (R01–R11) | F1 |
| [Open questions](#open-questions) | what the BRIEF leaves open, and the assumption I use (Q01–Q09) | F1, F2 |
| [Data model](#data-model) | the eight input files and how they join | F2 |
| [Decisions](#decisions) | how the pipeline is built, and why (D01–D11) | F3 |
| [Output](#output) | the five files, their columns, the reasons and the checks | F3 |
| [How a line is allocated](#how-a-line-is-allocated) | the path of one ledger line | F3 |
| [Worked examples](#worked-examples) | six real lines, computed by hand (W01–W06) | F3 |
| [Pipeline](#pipeline) | which file does what | F4 |
| [Validation](#validation) | the pipeline checked from outside (S01–S18) | F5 |

Phases: F1 understand the request, F2 understand the data, F3 design, F4 build, F5 validate, F6 communicate, F7 deliver.
F6 and F7 produce the README, the Tax note and the delivery, not sections here (phase plan in [`CLAUDE.md`](../CLAUDE.md)).

## IDs

Everything that is cited has an ID: one letter for its kind and two digits. Each ID is defined in one place; everywhere
else it is only cited.

| ID | Kind | Defined in |
|---|---|---|
| R01… | Rule | [Rules](#rules) |
| Q01… | Open question | [Open questions](#open-questions) |
| D01… | Decision | [Decisions](#decisions) |
| I01… | Data issue | [`data-issues.md`](data-issues.md) |
| C01… | Check on the input files, before the pipeline | [`notebooks/01-explore.ipynb`](../notebooks/01-explore.ipynb) |
| W01… | Worked example | [Worked examples](#worked-examples); recomputed in [`notebooks/02-worked-examples.ipynb`](../notebooks/02-worked-examples.ipynb) |
| S01… | Scenario | [`notebooks/03-scenarios.ipynb`](../notebooks/03-scenarios.ipynb); summed up in [Validation](#validation) |

- Citations list IDs in this order, R, Q, D, I, C, W, S: (R05, Q04, D05, I02).
- Files, pipeline checks, reasons, statuses, tables and columns have no ID: they are cited by their exact name, e.g.
  `03_lines.sql`, `block_reconciliation`, `no_mapping_row`.
- IDs do not change once delivered. A removed ID is not reused.

## Rules

Each rule is a testable statement of what the BRIEF asks. The IDs column of the [checks table](#checkscsv) shows which
pipeline check covers which rule.

### R01. Scope
- **Rule:** every ledger line is in scope except lines whose account group is Depreciation and lines whose amount is 0. Credits (negative amounts) stay in scope.
- **Check:** in-scope + out-of-scope = all ledger lines, in count and in dollars. Every out-of-scope line is in the output with its reason (`depreciation` or `zero_amount`); see [Output](#output).

### R02. Booked entity and booked group
- **Rule:** the booked entity is the line's entity. The booked group is that entity's entity_group in entities.csv.
- **Check:** every in-scope line has a booked group.

### R03. Cost type comes from the department
- **Rule:** the cost center's department decides the path. Live Games and New Games are direct. Engineering, Marketing, People and Operations are indirect.
- **Check:** every in-scope line has exactly one cost type, or is unallocated with a reason.

### R04. Direct, single game
- **Rule:** a direct cost center with a game sends 100% of the line to that game.
- **Check:** share = 1 for these lines.

### R05. Direct, pool
- **Rule:** a direct cost center with a pool_id splits the line across the pool's games with fte > 0 in that month. share(game) = fte(game, month) / sum of fte of the pool's games with fte > 0 in that month.
- **Check:** for each line, shares add up to 1. Only games in the pool receive dollars. Games with fte = 0 or no fte that month get nothing.

### R06. Direct, bearing group
- **Rule:** a direct cost does not change entity. Bearing group = booked group.
- **Check:** for every direct row, bearing group = booked group.

### R07. Direct, side
- **Rule:** the side comes from the game's mapping row valid that month (R10). By entity resolves to BR Games when the booked entity is LGB, and to US Games for any other entity.
- **Check:** every direct row ends with BR Games or US Games. By entity never appears in the output.

### R08. Indirect, buckets
- **Rule:** an indirect line is split across buckets by each bucket's share of the month's employees. A bucket is the first word of the employee's category in lower case, an underscore, and the employee's entity group in lower case, e.g. live_br. share(bucket) = employees in bucket that month / all employees of the company that month.
- **Check:** for each month, bucket shares add up to 1. Each indirect line's rows add up to the line's amount.

### R09. Indirect, bearing group and side
- **Rule:** both come from the bucket's mapping row valid that month (R10).
- **Check:** every indirect row has a bearing group and a side.

### R10. Mapping rows have dates
- **Rule:** a mapping row applies to a month when the month's first day is between start_date and end_date, both inclusive.
- **Check (on the inputs, before the join):** for each game or bucket used in a month, exactly one mapping row applies.

### R11. Reconciliation and summary (from "What to deliver", items 2 and 3)
- **Rule:** ledger total = out of scope + allocated + unallocated, for each month and in total. The summary shows the amount by booked group × side, for each month and for the quarter. The quarter is the sum of the months.
- **Check:** the equation holds with abs(difference) < 0.005. Summary total = allocated + unallocated (the in-scope total).

## Open questions

| ID | Question | Assumption I use | Tax note? |
|---|---|---|---|
| Q01 | A line can't be allocated: its account, entity or cost center is missing from its lookup table; its department is not in R03; a direct cost center has both game and pool_id, or neither; a game or bucket has no mapping row valid that month; a pool or month has nothing to split by; a bucket row has a blank bearing group. | Unallocated with a reason; the dollars stay visible. The run continues and warns. An employee whose entity is missing stays in the headcount; their bucket has no mapping row, so that share is unallocated (D10). | yes |
| Q02 | An input table has duplicate keys at the grain the BRIEF states (including both headcount files and line_id in the ledger). | Stop the run: a join would multiply dollars. | if it happens |
| Q03 | Two mapping rows are valid for the same game or bucket and month. | Stop the run: the side is ambiguous. | if it happens |
| Q04 | "The month's employees" for indirect shares: whole company, or only the booking entity's employees? | All employees of the company that month, all entities and both categories. Reading it as the booking entity's employees only would change the quarter by about −180,980 USD for BR Games, +188,845 USD for US Games and −7,865 USD unallocated; the three net to zero (S18). | yes |
| Q05 | A bucket row says By entity. | Does not happen in this data (C11). If it appears, it is a Q01 case: unallocated with a reason, the run warns. | if it happens |
| Q06 | Credits are split with the same shares, so destinations get negative amounts. | Yes, same shares; credits are not netted before allocating. | no |
| Q07 | Rounding: when to round to cents. | Keep full precision; round only in the output files. Reconciliation passes when abs(difference) < 0.005. | no |
| Q08 | Text keys that almost match (spaces). | Trim only the name columns used to match tables or compared to a rule's value (`account_group`); the run log lists every value changed. | yes, as an issue |
| Q09 | Is the quarter exactly the months in the ledger? | Yes. The ledger covers 2026-01 to 2026-03, the first quarter of 2026 (C11). The pipeline keeps the check. | no |

## Data model

Eight input files. The ledger is the fact table; the others describe its codes, or give the shares and the sides.

```mermaid
erDiagram
    ledger {
        string line_id PK
        string month
        string entity FK "entities.entity"
        string account FK "accounts.account"
        string cost_center FK "cost_centers.cost_center"
        decimal amount_usd
    }
    entities {
        string entity PK
        string entity_name
        string country
        string entity_group
    }
    accounts {
        string account PK
        string account_name
        string account_group
    }
    cost_centers {
        string cost_center PK
        string cost_center_name
        string department
        string game FK "game_mapping.game_group"
        string pool_id FK "pools.pool_id"
    }
    pools {
        string pool_id PK
        string game PK, FK "game_mapping.game_group"
    }
    headcount_games {
        string month PK
        string game PK, FK "game_mapping.game_group"
        double fte
    }
    headcount_employees {
        string month PK
        string employee_id PK
        string entity FK "entities.entity"
        string category
    }
    game_mapping {
        string game_group PK
        date start_date PK
        date end_date
        string category
        string bearing_group
        string side
    }
    entities ||--o{ ledger : "entity"
    accounts ||--o{ ledger : "account"
    cost_centers ||--o{ ledger : "cost_center"
    entities ||--o{ headcount_employees : "entity"
    pools }o--o{ cost_centers : "pool_id"
    game_mapping ||--o{ cost_centers : "game"
    game_mapping ||--o{ pools : "game"
    game_mapping ||--o{ headcount_games : "game"
    game_mapping }o..o{ headcount_employees : "bucket, built (R08)"
```

- Each line joins the column named on it; each FK column says, in quotes, the column it refers to. Crow's foot: `||`
  one, `o{` zero or many. The dotted line is not a column: the bucket is built (below).
- Games and buckets have no table of their own. `game_mapping.csv` holds every game and bucket name, one row per
  period, and the other files refer to those names.
- A bucket is not stored anywhere: it is built from the employee's category and their entity's group (R08).
- Keys are the grain the BRIEF states; `block_duplicate_keys` checks them on every run (Q02).

## Decisions

| ID | Decision | Why |
|---|---|---|
| D01 | **DuckDB SQL** for the pipeline. Python only runs the SQL, the checks and the output; it never changes the data. | The rules are joins and sums, and SQL reads close to them. |
| D02 | **One SQL file per step** in `sql/`, run in name order by `run.py`. | A rule change is a change in one file. |
| D03 | **One allocation table for every ledger line**, with `status` (`allocated`, `unallocated`, `out_of_scope`) and `reason`. | Every dollar is in one place; the reconciliation is one sum by status. |
| D04 | **A blocking check stops the run**: it exits with an error and writes no result file, only `checks.csv`. `checks.csv` is always written to `output/`. If a step stops with an error, `output/` is left empty. | No wrong or stale number stays in `output/`. |
| D05 | **Line amounts are read as `DECIMAL(18, 2)`; shares are DOUBLE.** A piece (amount × share) keeps full precision and is cast to `DECIMAL(18, 2)` only when written; the checks compare at full precision with the Q07 tolerance. A line's rounded pieces may differ from the line by a few cents (at most 0.02 in this data); that is accepted, not adjusted, and the README says so. All files are read as text and cast explicitly in the load step. Output is sorted by `line_id`, then game or bucket. | Exact amounts in, cents out; the same input always gives the same file, so a change shows as a clean diff. |
| D06 | **No test framework.** | The checks run with every run; the worked examples are compared with the output in a notebook (see [Validation](#validation)). |
| D07 | **Checks are SQL queries in `sql/checks/`**, one per file, each returning the failing rows. The file name starts with `block_` or `warn_`. If a failure means the numbers would be wrong or ambiguous (a key or mapping is duplicated, the months are not one quarter, the pipeline lost or created dollars), it blocks. If the dollars are kept but some have no destination, or a value was cleaned, it warns. | The level is visible in the file name; adding a check is adding a file. |
| D08 | **The cleaning step trims names in SQL** and keeps a table of every value it changed (before, after). A `warn_` check reports it (Q08). | No value changes silently. |
| D09 | **One row per piece.** A line split across games or buckets has one row for each. A game or bucket with no mapping row is still a piece: status `unallocated`, with its game or bucket filled (the `live_fi` case). Only a line that can't be split at all has one row with no game or bucket. | An unallocated dollar shows where it would have gone, so the missing mapping row is easy to find. |
| D10 | **An employee whose entity is missing stays in the headcount**, with `unknown` as entity group (`live_unknown`, `new_unknown`). That bucket has no mapping row, so its piece is `unallocated` with reason `no_mapping_row` (Q01). | The shares still count every employee; the gap shows as unallocated dollars, not as a smaller headcount. |
| D11 | **Every row has a share**; a line that isn't split has one row with share 1. | The shares of every line add up to 1 and its rows to its amount, so one check, `block_shares_not_one`, covers every line. |

## Output

`python run.py` writes five files to `output/`: `allocation.csv`, `summary.csv`, `summary_by_entity.csv`,
`reconciliation.csv` and `checks.csv`. On a blocking check, only `checks.csv` is written (D04).

### allocation.csv

One row per piece of a ledger line (D09). Sorted by `line_id`, then `game_or_bucket`.

| Column | What it is |
|---|---|
| `line_id`, `month` | from the ledger |
| `booked_entity`, `booked_group` | the line's entity and its `entity_group` (R02) |
| `account`, `account_name`, `account_group` | from `accounts.csv` |
| `cost_center`, `cost_center_name`, `department`, `pool_id` | from `cost_centers.csv` |
| `cost_type` | `direct` or `indirect`, from the department (R03) |
| `game_or_bucket` | the game (R04, R05), or the bucket for indirect costs (R08) |
| `bearing_group` | the booked group for direct costs (R06); the bucket's mapping row for indirect costs (R09) |
| `side` | `BR Games` or `US Games`; `By entity` is already resolved (R07, R09) |
| `share` | the piece's share of the line; 1 when the line isn't split |
| `amount_usd` | line amount × share, rounded to cents |
| `status` | `allocated`, `unallocated` or `out_of_scope` |
| `reason` | empty when allocated; otherwise one code from the table below |

Lookup columns (names, `booked_group`, `department`, `pool_id`, `cost_type`, `account_group`) are filled whenever the
lookup finds a match, whatever the status. `bearing_group` and `side` are filled only on allocated rows. For example,
L00169 (cost center 3999) has no `cost_center_name`, `department`, `cost_type` or game.

**Reasons.** The steps run in this order, and the first one that fails gives the reason. One code per Q01 case.

| Code | Status | When |
|---|---|---|
| `zero_amount` | out_of_scope | amount is 0 (R01) |
| `unknown_account` | unallocated | account not in `accounts.csv`, so the scope can't be decided |
| `depreciation` | out_of_scope | account group is Depreciation (R01) |
| `unknown_entity` | unallocated | entity not in `entities.csv` |
| `unknown_cost_center` | unallocated | cost center not in `cost_centers.csv` (I01) |
| `unknown_department` | unallocated | department not in R03 |
| `bad_cost_center` | unallocated | a direct cost center has both a game and a pool, or neither |
| `nothing_to_split` | unallocated | a pool has no game with FTE that month (R05), or the month has no employees (R08) |
| `no_mapping_row` | unallocated | a game or bucket has no mapping row valid that month (R10, I03) |
| `bad_mapping_row` | unallocated | a bucket row has a blank bearing group, or says By entity (Q05) |

The last two apply to one piece, not to the whole line: the other pieces of the line are still allocated.

### summary.csv

One row per period × booked group: `period, booked_group, br_games, us_games, unallocated, total`. Period is `2026-01`,
`2026-02`, `2026-03` or `2026-Q1`; the quarter is the sum of the months. `total` is the in-scope amount;
out-of-scope lines are left out.
The month and quarter labels in the summaries and `reconciliation.csv` are built from the ledger's months, not
written in the code.

### summary_by_entity.csv

The same amounts, one row per period × booked entity: `period, booked_entity, booked_group, br_games, us_games,
unallocated, total`. The BRIEF asks for the summary by booked group, and also says Tax needs to know, every month, how
much cost each entity booked and which side bears it; this file answers that. `summary.csv` adds up these rows by
booked group (LGC and LGK are both in Others).

### reconciliation.csv

One row per period: `period, ledger_total, out_of_scope, in_scope, allocated, unallocated, difference`, where
`difference = ledger_total − out_of_scope − allocated − unallocated`, at full precision (Q07). This is where "every
in-scope dollar" is accounted for. `in_scope` = `ledger_total` − `out_of_scope`, so lines with `unknown_account` count
as in scope (unallocated).

### checks.csv

One row per check: `check, level, result, rows, amount_usd`. `result` is `pass`, `warn` or `fail`: `warn` means a
`warn_` check found rows, and `fail` is used only for `block_` checks, so it always means the run stopped. `rows` and
`amount_usd` describe the rows found; `amount_usd` is empty when the check is not about dollars (duplicate keys,
overlapping mapping, months, trimmed values). `run.py` prints all rows found by `warn_trimmed_values` (Q08), and the
first 10 rows found by any other check.

| Check | Level | Fails when | IDs |
|---|---|---|---|
| `block_duplicate_keys` | block | an input table has duplicate keys at its grain | Q02 |
| `block_overlapping_mapping` | block | two mapping rows are valid for the same game or bucket and month | R10, Q03 |
| `block_months_outside_quarter` | block | the ledger months are not the three months of one calendar quarter | Q09 |
| `block_shares_not_one` | block | the shares of a line don't add up to 1 | R04, R05, R08, D11 |
| `block_reconciliation` | block | `difference` is not under 0.005, or the `total` of either summary differs from `in_scope` | R01, R11, Q07 |
| `block_unmatched_game_names` | block | a game in `pools.csv` or `headcount_games.csv` has no row in `game_mapping.csv`: a misspelled name would drop out of a pool split silently | Q08, S11 |
| `block_allocated_rows_complete` | block | an allocated row has no game or bucket; has a side other than BR Games or US Games (so By entity never reaches the output); is a direct row whose bearing group isn't its booked group; is a pool piece whose game isn't in that pool; or is an indirect row with no bearing group | R05, R06, R07, R09 |
| `warn_unallocated` | warn | any row is unallocated | Q01 |
| `warn_trimmed_values` | warn | the cleaning step changed any value | Q08 |

Dates are cast explicitly in the load step, so a date DuckDB can't read stops the run with an error. A date without
leading zeros (`2026-3-1`) is read as the same day and does not stop the run.

Expected on this data: every `block_` check passes; both `warn_` checks give `warn` (I01 and I03 for unallocated, I02
for trimmed values).

## How a line is allocated

Each ledger line follows this path. The first step that fails gives the line its status and reason (see [Output](#output)). The
last two failures apply to one piece only: the other pieces of the line are still allocated.

```mermaid
flowchart TD
    L(["Ledger line"])

    subgraph SCOPE["Scope · 03_lines"]
        Z{"Amount = 0?<br/>(R01)"}
        A{"Account found?<br/>(R01)"}
        DP{"Depreciation?<br/>(R01)"}
    end

    subgraph LOOKUP["Lookups · 03_lines"]
        E{"Entity found?<br/>(R02)"}
        C{"Cost center found?<br/>(R03)"}
        D{"Department?<br/>(R03)"}
    end

    subgraph SPLIT["Split · 04_ to 06_"]
        DIR{"Game or pool?"}
        G["100% to the game<br/>(R04)"]
        P["Split by FTE > 0<br/>(R05)"]
        IND["Split by employees<br/>per bucket<br/>(R08)"]
    end

    subgraph MAP["Mapping · 07_mapping"]
        M{"Mapping row<br/>valid that month?<br/>(R10)"}
    end

    L --> Z
    Z -- no --> A
    A -- yes --> DP
    DP -- no --> E
    E -- yes --> C
    C -- yes --> D
    D -- "Live Games,<br/>New Games" --> DIR
    D -- "Engineering, Marketing,<br/>People, Operations" --> IND
    DIR -- game --> G
    DIR -- pool --> P
    G --> M
    P --> M
    IND --> M
    M -- yes --> OK(["allocated<br/>bearing group + side<br/>(R06, R07, R09)"])

    Z -- yes --> OZ["zero_amount"]
    DP -- yes --> OD["depreciation"]
    A -- no --> UA["unknown_account"]
    E -- no --> UE["unknown_entity"]
    C -- no --> UC["unknown_cost_center"]
    D -- other --> UD["unknown_department"]
    DIR -- "both or neither" --> UB["bad_cost_center"]
    P -- "no FTE" --> UN["nothing_to_split"]
    IND -- "no employees" --> UN
    M -- no --> UM["no_mapping_row<br/>this piece only"]
    M -- "bucket: blank bearing<br/>group or By entity" --> UBM["bad_mapping_row<br/>this piece only"]

    classDef outscope fill:#e6e6e6,stroke:#6b6b6b,color:#1f1f1f
    classDef unalloc fill:#ffe2b8,stroke:#b86e00,color:#3d2400
    classDef alloc fill:#cdeccf,stroke:#2e7d32,color:#163d19
    class OZ,OD outscope
    class UA,UE,UC,UD,UB,UN,UM,UBM unalloc
    class OK alloc
```

Grey: `out_of_scope`. Amber: `unallocated`, and the box is the reason. Green: `allocated`. Each block title names the
file in `sql/` that applies it (see [Pipeline](#pipeline)); each step names the rule it applies.

## Worked examples

Real lines from the data, computed independently of the pipeline in
[`notebooks/02-worked-examples.ipynb`](../notebooks/02-worked-examples.ipynb). The pipeline gives the same rows
(see [Validation](#validation)).

### W01. Direct, single game

L00105, 2026-01, LGB, Salaries, cost center 1001 Star Racer, 103,255.10 USD.
The cost center has a game, so the share is 1 (R04). The mapping row is `Star Racer ` with a trailing space (I02); after
the trim it matches (C08). Bearing group = booked group = BR (R06).

| Game | Share | Amount (USD) | Bearing group | Side |
|---|---|---|---|---|
| Star Racer | 1 | 103,255.10 | BR | BR Games |

### W02. Direct, pool

L00054, 2026-01, LGB, Salaries, cost center 2010 New Games Prototyping, pool NEW_SHARED,
21,972.14 USD. Moon Miner is in the pool but has no FTE in January, so it gets nothing (R05). FTE of the others: 11.5 + 14.5
+ 9 + 6 = 41. Puzzle Pals is still BR Games in January.

| Game | Share | Amount (USD) | Bearing group | Side |
|---|---|---|---|---|
| Pixel Farm | 14.5 / 41 | 7,770.63 | BR | US Games |
| Puzzle Pals | 11.5 / 41 | 6,162.92 | BR | BR Games |
| Rune Quest | 9 / 41 | 4,823.15 | BR | US Games |
| Tiny Chef | 6 / 41 | 3,215.44 | BR | BR Games |
| **Total** | 1 | **21,972.14** | | |

The bearing group stays BR on the US Games rows: a direct cost doesn't change entity (R06).

### W03. Indirect

L00444, 2026-02, LGB, Salaries, cost center 3301 Finance, 21,346.02 USD. The company has 123 employees
in February (R08, Q04).

| Bucket | Share | Amount (USD) | Bearing group | Side |
|---|---|---|---|---|
| live_br | 71 / 123 | 12,321.69 | BR | BR Games |
| new_br | 25 / 123 | 4,338.62 | BR | BR Games |
| new_fi | 8 / 123 | 1,388.36 | FI | US Games |
| new_others | 5 / 123 | 867.72 | Others | US Games |
| new_us | 14 / 123 | 2,429.63 | US | US Games |
| **Total** | 1 | **21,346.02** | | |

### W04. By entity

Legacy Arcade (cost center 1004) maps to By entity (R07). Same game and month, two entities:

| Line | Entity | Amount (USD) | Bearing group | Side |
|---|---|---|---|---|
| L00334, 2026-01, Salaries | LGB | 24,203.53 | BR | BR Games |
| L00336, 2026-01, Salaries | LGI | 12,825.36 | US | US Games |

### W05. Mapping dates

Puzzle Pals (cost center 2001) moves from BR Games to US Games on 2026-03-01 (R10). Same entity
and account, two months:

| Line | Month | Amount (USD) | Bearing group | Side |
|---|---|---|---|---|
| L00114, LGB, Salaries | 2026-02 | 31,929.39 | BR | BR Games |
| L00494, LGB, Salaries | 2026-03 | 32,256.22 | BR | US Games |

The bearing group stays BR: only the side changes.

### W06. Unallocated

Two cases, one per level:
- **Whole line (I01).** L00169, 2026-02, LGB, Professional Services, cost center 3999, 17,017.98 USD. The cost center isn't
  in `cost_centers.csv`, so the line has one row: share 1, no game, status `unallocated`, reason `unknown_cost_center`.
- **One piece (I03).** L00234, 2026-03, LGB, Salaries, cost center 3301 Finance, 24,080.73 USD. There are 125 employees
  in March, 2 of them in live_fi, which has no mapping row.

| Bucket | Share | Amount (USD) | Bearing group | Side | Status |
|---|---|---|---|---|---|
| live_br | 70 / 125 | 13,485.21 | BR | BR Games | allocated |
| live_fi | 2 / 125 | 385.29 | | | unallocated, `no_mapping_row` |
| new_br | 26 / 125 | 5,008.79 | BR | BR Games | allocated |
| new_fi | 8 / 125 | 1,541.17 | FI | US Games | allocated |
| new_others | 5 / 125 | 963.23 | Others | US Games | allocated |
| new_us | 14 / 125 | 2,697.04 | US | US Games | allocated |
| **Total** | 1 | **24,080.73** | | | |

## Pipeline

`python run.py` runs the files in `sql/` in name order, then the checks in `sql/checks/`, then writes `output/`.
Each step creates tables that the next steps read. To change a rule, change the file in its row.

```mermaid
flowchart TD
    IN[("data/*.csv")]

    subgraph PREP["Prepare"]
        P01["01_load"] --> P02["02_clean"] --> P03["03_lines"]
    end

    subgraph SPLIT["Split"]
        P04["04_direct_game"]
        P05["05_direct_pool"]
        P06["06_indirect"]
    end

    subgraph BUILD["Assemble"]
        P07["07_mapping"] --> P08["08_allocation"]
    end

    subgraph REPORT["Report"]
        P09["09_summary"]
        P10["10_reconciliation"]
        P11["11_output"]
    end

    IN --> P01
    P03 --> P04 & P05 & P06
    P04 & P05 & P06 --> P07
    P08 --> P09 & P10
    P09 & P10 --> P11
    P11 --> CK{"sql/checks/<br/>any block_ fails?"}
    CK -- no --> OUT[("output/<br/>allocation · summary<br/>summary_by_entity<br/>reconciliation · checks")]
    CK -- yes --> STOP["exit 1<br/>only checks.csv"]

    classDef step fill:#dbe8fb,stroke:#2f62b0,color:#0e2a52
    classDef io fill:#ece4f7,stroke:#6a46b0,color:#2b1a4a
    classDef stop fill:#ffd9d6,stroke:#c0392b,color:#4a0f0a
    class P01,P02,P03,P04,P05,P06,P07,P08,P09,P10,P11 step
    class IN,OUT io
    class STOP stop
```

Blue: a file in `sql/`. Purple: files read or written. Red: the run stops. Before the first step, `run.py` deletes
the previous results, so a step that stops with an error leaves `output/` empty (D04).

| File | Creates | IDs |
|---|---|---|
| `01_load.sql` | the eight input tables; amounts as DECIMAL, FTE as DOUBLE, dates as DATE | D05 |
| `02_clean.sql` | `trimmed_values`; names trimmed in place | Q08, D08, I02 |
| `03_lines.sql` | `lines`: one row per ledger line with its lookups, cost type, reason and scope | R01, R02, R03, Q01 |
| `04_direct_game.sql` | `pieces_game` | R04 |
| `05_direct_pool.sql` | `pool_shares`, `pieces_pool` | R05 |
| `06_indirect.sql` | `employee_buckets`, `bucket_shares`, `pieces_indirect` | R08, Q04 |
| `07_mapping.sql` | `pieces`, `pieces_mapped`: bearing group, side and reason of every piece | R06, R07, R09, R10, Q05 |
| `08_allocation.sql` | `allocation`: every ledger line, one row per piece | D03, D09, D11 |
| `09_summary.sql` | `summary_by_entity`, then `summary` from it | R11 |
| `10_reconciliation.sql` | `reconciliation` | R01, R11 |
| `11_output.sql` | the result tables as written: rounded and sorted | Q07, D05 |
| `sql/checks/*.sql` | one query per check; the rows it returns are the problem | D07 |
| `run.py` | runs everything above and writes `output/`; clears old results first | D01, D02, D04 |

The run happens in memory. To look at any table after a run: `python -i run.py`, then for example
`con.sql("SELECT * FROM lines WHERE line_id = 'L00169'").show()`; or the **Look inside** section of
[`notebooks/04-results.ipynb`](../notebooks/04-results.ipynb), which also follows one line from start to end.

## Validation

Two notebooks check the pipeline from outside, without changing it:

- [`notebooks/02-worked-examples.ipynb`](../notebooks/02-worked-examples.ipynb) recomputes the six worked examples in
  pandas and compares all 21 rows with `output/allocation.csv`: same pieces, amounts to the cent, bearing group and
  side.
- [`notebooks/03-scenarios.ipynb`](../notebooks/03-scenarios.ipynb) runs 18 scenarios. Each one copies the project to
  a temporary folder, makes one change and runs the pipeline there. The expected result is written before the run.

| ID | Change | Expected | Result |
|---|---|---|---|
| S01 | A ledger line appears twice | `block_duplicate_keys` fails, only `checks.csv` left | as expected |
| S02 | Two mapping rows valid in the same month | `block_overlapping_mapping` fails, only `checks.csv` left | as expected |
| S03 | A ledger line in April | `block_months_outside_quarter` fails, only `checks.csv` left | as expected |
| S04 | A date the load step can't read | error in the load step, `output/` empty | as expected |
| S05 | Unknown entity on a line | the line is unallocated, `unknown_entity`; reconciles | as expected |
| S06 | Unknown account on a line | unallocated, `unknown_account`; in scope unchanged | as expected |
| S07 | `Depreciation ` with a trailing space | trim logged; out of scope unchanged | as expected |
| S08 | A pool with no FTE in a month | its in-scope lines: one row each, `nothing_to_split` | as expected |
| S09 | An employee with an unknown entity | `live_unknown` pieces, `no_mapping_row`; reconciles | as expected |
| S10 | A direct cost center with a game and a pool | its lines: `bad_cost_center` | as expected |
| S11 | A misspelled game in `headcount_games.csv` | `block_unmatched_game_names` fails, only `checks.csv` left | as expected |
| S12 | "Cost center 3999 is Marketing" (data only) | L00169 allocated; nothing unallocated in February | as expected |
| S13 | "Add the mapping row for live_fi" (data only) | nothing unallocated in March | as expected |
| S14 | "Puzzle Pals moved in February" (data only) | its February dollars move to US Games | as expected |
| S15 | "Exclude account group Administrative" (`03_lines.sql`, two lines) | out of scope grows by the Administrative dollars; reconciles | as expected |
| S16 | "A new game with its own cost center" (data only) | the line goes 100% to the new game | as expected |
| S17 | A live edit breaks the pool split (`05_direct_pool.sql`) | `block_shares_not_one` fails and is named in the last line | as expected |
| S18 | Q04 read as "the booking entity's employees only" (`06_indirect.sql`) | indirect costs stay in their booked group; reconciles | as expected: in the quarter about −180,980 USD BR Games, +188,845 USD US Games, −7,865 USD unallocated; they net to zero |

Two expectations were wrong the first time, not the pipeline: S08 forgot that a Depreciation line on the pool stays out
of scope, and S15 summed rounded pieces instead of line amounts.
