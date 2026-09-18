# Sports Franchise Valuation Pipeline — Project Summary

## Goal
A portfolio project demonstrating data-analyst skills (SQL, Python, Tableau) aimed
squarely at business/finance questions in sports — franchise valuation and market
economics — deliberately avoiding player stats or on-field performance, so the
project reads as business analysis rather than sports fandom.

## Tool stack, in order
1. **Wikipedia + Census API** — raw source data (team valuations; market/population data)
2. **Python (requests + pandas)** — scrape valuation tables off Wikipedia
3. **Python (pandas)** — clean and reshape the scraped data
4. **SQLite** — store the data in a proper 3-table relational schema
5. **SQL** — join and aggregate into analysis-ready views
6. **Tableau** — build the dashboard on top of the SQL layer
7. **GitHub** — document and share the finished project

## Schema
- **teams** (dimension) — team_id, name, league, city — one row per franchise, stable
- **valuations** (fact table) — team_id, year, value — one row per team-per-year, grows over time
- **markets** (dimension, not yet built) — city, metro_population, media_market_rank

## Data source specifics
- Source page used so far: Wikipedia "Forbes list of the most valuable NFL teams"
- `pandas.read_html()` on that page returns 5 tables; only two are real content:
  - Table 0 (32×8): current-year ranking — Rank, Team, State, Value, Change, Revenue, Operating income
  - Table 2 (32×13): **the historical valuations table** — Team + one column per year, 2012–2023
  - Tables 1, 3, 4 are page furniture (an "update needed" notice box and navigation sidebars) — junk
- Table-selection logic: don't rely on row count (both real tables have 32 rows) — check
  column *names* instead. Table 2's columns are mostly 4-digit numeric strings (years);
  Table 0's are named fields. A working detector: for each table, compute the fraction of
  column names that are 4-character strings passing `.isdigit()`; the table with the highest
  fraction is the historical (wide-format) table.
- Table 2's values are already clean `int64` — no `$`/"billion" text cleanup needed (that
  formatting issue exists only in table 0, not table 2). Caption confirms units are US$ millions.
- Team names in table 2 reflect *current* franchise names even for years the team was
  elsewhere (e.g., "Las Vegas Raiders" for years it was the Oakland Raiders). This is a
  known join-key caveat for later, when matching against a market/city table — not a
  cleaning bug in this table.

## Progress so far
- Wrote a Python loop that scores each scraped table by the fraction of its columns that
  look like 4-digit years, correctly and automatically isolates table 2.
- Melted table 2 from wide (Team + 12 year-columns) to long format using `pd.melt()`,
  producing 384 rows (32 teams × 12 years): columns `Team`, `Year`, `Evaluation`.
- Converted the `Year` column from string to `int64` after melting.
- Current state: `historical_table` is a clean 384-row, 3-column long-format DataFrame —
  this is the `valuations` fact table, pending a swap of `Team` name for `team_id` once
  the `teams` dimension table exists.

## Next steps (not yet started)
- Build the `teams` dimension table: team_id, name, league, city
- Build the `markets` dimension table: city, metro_population, media_market_rank
  (planned sources: Wikipedia tables via `pandas.read_html()`, U.S. Census Bureau API —
  avoid scraping Forbes.com directly, it blocks scrapers)
- Load all three tables into SQLite
- Write SQL joins/aggregations (e.g., valuation growth rate, revenue-to-valuation ratio,
  market-size vs. valuation correlation)
- Build the Tableau dashboard
- Write the GitHub README

## Working style for this project
- Guided-discovery approach: work through design decisions and debugging via questions
  rather than being handed full solutions. Plumbing/boilerplate (e.g., basic HTTP fetch
  calls) can be supplied directly; logic that constitutes real design judgment (table
  selection, cleaning rules, schema decisions, join-key handling) should be reasoned
  through step by step, not solved outright.
