# NFL Franchise Valuation vs. Media Market Size

A data pipeline and analysis asking one question: **does the size of an NFL team's
media market predict how valuable the franchise is?** Built end-to-end — web scraping,
data cleaning, a relational schema, hand-rolled statistical SQL, and a Tableau dashboard.

## Question

Common intuition says teams in bigger media markets (New York, LA) should be worth
more than teams in smaller ones (Green Bay, Jacksonville) — bigger local audience,
bigger local ad/sponsorship revenue, bigger valuation. This project tests that
intuition against real data rather than assuming it.

## Result

Across all 32 NFL franchises (2012–2023 valuations, 384 team-years), average franchise
valuation and media market rank are correlated at **r ≈ -0.52** (market rank runs
1 = largest market, so the negative sign means *smaller rank number → higher valuation*
— i.e. bigger markets do trend toward higher valuations, moderately, not perfectly).
A simple linear regression of valuation on market rank is included in the SQL, with
predicted values and residuals per team — see `Visualization/team_valuation_summary.csv`
for which teams most over- or under-perform their market size would predict (the Dallas
Cowboys and Green Bay Packers are the two largest positive outliers — valued well above
what their market size alone would predict).

## Pipeline

1. **Scrape** — `Python/table_data_creation.ipynb` pulls NFL franchise valuations
   (2012–2023) from Wikipedia's Forbes valuation table, and TV market rankings from
   Wikipedia's Nielsen DMA list, via `pandas.read_html()` and a regex parse of the
   media-market page's wikitext.
2. **Clean & model** — reshapes the wide valuation table into a long team-year fact
   table, builds a `teams` dimension table, and handles three franchise relocations
   (Rams, Chargers, Raiders) so each team-year is attributed to the correct city.
3. **Load** — three tables (`teams`, `valuations`, `media_markets`) loaded into a
   SQLite database (`SQL/sports_valuation.db`).
4. **Analyze** — `SQL/sports_valuation_correlation.sql` computes each team's primary
   city, joins valuation and media-market data, and calculates the Pearson correlation
   coefficient and linear regression slope manually, to make the underlying statistics
   explicit rather than a black box.
5. **Visualize** — `Visualization/sports_valuation_dashboard.twbx` (Tableau) presents
   the results.

## Tech stack

Python (`requests`, `pandas`) · SQLite · SQL (CTEs, window functions) · Tableau

## Repo structure

```
Project_description/   process notes from building this project
Python/                 scraping + cleaning notebook
SQL/                    database + correlation/regression query
Visualization/          Tableau workbook + supporting CSVs
```

## Caveats

- Media market rank is a proxy for market size, not a direct financial variable —
  it doesn't capture stadium deals, ownership, or on-field success, all of which
  also drive valuation.
- n = 32 teams is small; a correlation this size (r ≈ -0.52) is suggestive, not
  proof of a causal relationship.
