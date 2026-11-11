# Take-home case: allocating shared costs between two sides

**We care more about correct numbers, checks and clear communication than about polish.

## The context

Lumen Games is a fictional mobile games company with five legal entities: Lumen Games Brasil
(`LGB`), Lumen Games Inc (`LGI`), Lumen Games Finland (`LGF`), and two small ones, in Canada
(`LGC`) and the UK (`LGK`).

For tax purposes, every cost has to end up on one of two **sides**:

- **BR Games**: games owned by the Brazilian entity;
- **US Games**: games owned by the rest of the group.

The Tax team needs to know, every month, how much cost each entity **booked** and which side
**bears** it. Costs often cross sides: a team in Brazil works on a US game, or a corporate department
paid by Brazil supports the whole company.

Finance gave you the month's data as CSV files (in `data/`) and the allocation rules below. The
files come from several real-life-like sources. **They may contain issues: finding them is part of
the task.** When you find one, decide how to handle it, and tell us what you found and what you did.

## The data

| File | One row per | Columns |
|---|---|---|
| `ledger.csv` | ledger line | `line_id`, `month` (`yyyy-MM`), `entity` (the entity that booked the cost), `account`, `cost_center`, `amount_usd` (positive = expense, negative = credit) |
| `entities.csv` | entity | `entity`, `entity_name`, `country`, `entity_group` (`BR`, `US`, `FI` or `Others`) |
| `accounts.csv` | account | `account`, `account_name`, `account_group` |
| `cost_centers.csv` | cost center | `cost_center`, `cost_center_name`, `department`, `game` (filled when the cost center is a single game's team), `pool_id` (filled when it is a team shared by several games) |
| `pools.csv` | pool × game | `pool_id`, `game`: the games a shared team works for |
| `headcount_games.csv` | month × game | `month`, `game`, `fte`: full-time equivalents working on the game |
| `headcount_employees.csv` | month × employee | `month`, `employee_id`, `entity`, `category` (`Live Games` or `New Games`) |
| `game_mapping.csv` | game or bucket × period | `game_group`, `category`, `bearing_group` (filled only on bucket rows), `side` (`BR Games`, `US Games`, or `By entity`), `start_date`, `end_date` |

## The rules (from Finance)

1. **Scope.** Every ledger line, except account group `Depreciation` and lines with a zero amount.
2. **Booked.** A line is booked by its `entity`; its *booked group* is that entity's `entity_group`.
3. **Direct costs** are lines on cost centers of the `Live Games` and `New Games` departments.
   - A cost center with a `game` goes 100% to that game.
   - A cost center with a `pool_id` is split across the pool's games, by each game's share of
     FTE in that month (`headcount_games.csv`), among the pool's games that have FTE that month.
   - A direct cost **doesn't change entity**: its *bearing group* is its booked group.
   - Its **side** comes from the game's row in `game_mapping.csv`. `By entity` means: BR Games
     when booked by `LGB`, US Games when booked by any other entity.
4. **Indirect costs** are lines on cost centers of the `Engineering`, `Marketing`, `People` and
   `Operations` departments. Each line is split across **buckets** by each bucket's share of the
   month's employees (`headcount_employees.csv`).
   - A bucket is the employee's category plus their entity's group, in lower case:
     `live_br`, `new_fi`, `new_others`, …
   - The bucket's row in `game_mapping.csv` gives the **bearing group** and the **side**.
5. **Mapping rows have dates.** A row applies to a month when the month's first day is between
   `start_date` and `end_date`, both inclusive.

## What to deliver

1. **A pipeline** that turns the CSVs into an allocation table, with at least: month, booked entity,
   booked group, account group, cost type (direct or indirect), the game or bucket, bearing group,
   side and amount. Use Python (pandas or PySpark) and/or SQL (DuckDB, Spark SQL, or the free
   edition of Databricks): your choice.
2. **A summary**: for each month and for the quarter, the amount by *booked group* × *side*.
3. **Data quality checks** that run with the pipeline and make problems impossible to miss.
   Totals must reconcile: tell us where every in-scope dollar went.
4. **A note to the Tax team**, one page at most, in plain English for non-technical readers: the
   results, the issues you found (with their dollar impact), what you assumed, and what you need
   from them.
5. **A short README**: how to run it, and your main design choices.

## How to submit

- A **Git repository**: a link to a private repo we can access, or a zip that includes the `.git`
  folder. We read the commit history.
- **AI tools are welcome; we expect you to use them.** Include either your AI session transcript
  or a short log: what you asked, what you kept, what you rejected, and why.
- Make sure it runs from a clean checkout with the instructions in your README.

## What comes next

A 45-minute conversation with the team. We'll ask you to walk us through your solution with it
running on your laptop, we'll ask for a small change live, we'll review a short piece of code
together, and we'll discuss a question from a business partner. No preparation needed beyond your
own solution.

Questions about the case? Write to the recruiter. We'll answer what a business partner could
answer, and any clarification goes to every candidate.
