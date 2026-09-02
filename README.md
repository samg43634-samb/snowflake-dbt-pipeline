# SQL Server → ADF → Snowflake → dbt → Git (CI/CD) — End-to-End Pipeline Demo

A **teaching example** for a data engineering coaching session. Fictional
data throughout, no company names or branding — just the architecture
pattern: an on-premises OLTP source system, an orchestrated ETL tool, a
cloud warehouse organized into clear layers, dbt for transformation, and
Git-driven CI/CD for promotion.

The stack is **SQL Server (on-prem) + Azure Data Factory + Snowflake +
dbt + Git** — a combination that shows up constantly in real enterprise
data platforms, especially ones with an existing Microsoft/Azure
footprint. ADF isn't a placeholder here: `adf/` ships two real,
metadata-driven pipelines (linked services, datasets, pipelines, and a
trigger), driven by a watermark control table in SQL Server.

This whole dbt project has been run end-to-end (seed → snapshot → run →
test, including a Day-2 change batch with the historical-append pattern
described below) against a local DuckDB target to confirm every model,
macro, snapshot, and test actually executes and produces correct
results — not just that the SQL parses. (ADF itself requires an actual
Azure subscription to run and wasn't executed live as part of that
validation — see `adf/README.md` for what to check when you do have one
available.)

## Architecture

```
SQL Server (on-prem)  --ADF-->  Snowflake  --dbt-->  Git (CI/CD)
```

Two ADF pipelines feed Snowflake:

- **`PL_Full_Historical_Load`** — a one-time (or on-demand) full load of
  every table, ignoring watermarks. Run once per table when it's first
  onboarded, or any time a full backfill is needed.
- **`PL_Incremental_Load`** — the regular, ongoing pipeline: full scans
  for small dimension tables, watermark-filtered scans for growing fact
  tables.

Both pipelines only ever **append** into Snowflake — there is no
merge/upsert step on the ADF side at all (see "Why RAW_SM is historical"
below for why that's a deliberate design choice, not a shortcut).

## Snowflake: four schemas, four jobs

All four schemas live in one database, `ANALYTICS_DB`:

| Schema | Job |
|---|---|
| **`RAW_SM`** | 1:1 with the source, **historical**. ADF appends every extraction here; a key can legitimately appear more than once. |
| **`STAGE_SM`** | dbt's staging layer: type casting, null handling, and — because RAW_SM is historical — deduplication down to exactly one current row per key. |
| **`INTERMEDIATE_SM`** | dbt's SCD2 snapshots and intermediate joins: `customers_snapshot`, `products_snapshot`, `orders_status_snapshot`, `int_order_lines_enriched`. |
| **`MARTS`** | Final, analytics-ready tables: `dim_cust`, `dim_products`, `fact_orders`, `cust_metrics`, `product_performance`. |

### Why RAW_SM is historical, not current-state

Earlier iterations of this pattern used a two-step "land in a transient
STAGE table, then MERGE into RAW" design on the Snowflake side, so that
RAW always held exactly one row per key. This version instead makes
**RAW_SM itself the historical record** — ADF's Copy activity always
appends, never merges — and pushes the "what's true right now"
responsibility down into dbt's `stage_sm` layer, using:

```sql
qualify row_number() over (
    partition by CustomerId
    order by LOAD_TIMESTAMP desc
) = 1
```

This is a real simplification of the ETL layer (no merge step, no
truncate, nothing that can partially fail mid-merge), and it means
RAW_SM can also answer "what did this record look like on any past
date" — a question a current-state-only RAW schema can't answer at all.
The trade-off, worth naming to students: RAW_SM grows faster (every
full-load run re-adds every row for small dimension tables), so it's
not free.

## What this demonstrates

| Concept | Where |
|---|---|
| SQL Server (on-prem) as the source system | `sql_server/` |
| A watermark control table driving two metadata-driven ADF pipelines | `sql_server/03_pipeline_watermark_control.sql` |
| Real Azure Data Factory pipelines: full load + incremental | `adf/` |
| Historical, append-only RAW_SM + QUALIFY dedup in STAGE_SM | `dbt_project/models/staging/` |
| **Incremental model with merge strategy + a real watermark edge case** | `dbt_project/models/marts/fact_orders.sql` |
| **SCD Type 2 via the timestamp snapshot strategy** | `dbt_project/snapshots/customers_snapshot.sql`, `products_snapshot.sql` |
| **SCD Type 2 via the check-columns snapshot strategy** | `dbt_project/snapshots/orders_status_snapshot.sql` |
| **Window-function analytics** (ROW_NUMBER, LAG, running SUM OVER, NTILE) | `dbt_project/models/marts/cust_metrics.sql` |
| **Window-function analytics** (RANK, cumulative share, ABC/Pareto classification) | `dbt_project/models/marts/product_performance.sql` |
| **Reusable macros** for business rules | `dbt_project/macros/` |
| **Custom singular tests** beyond schema tests | `dbt_project/tests/` |
| Dev/test/prod environments and real GitHub Actions CI/CD | `.github/workflows/`, `GITHUB_SETUP.md`, and the companion Environment Strategy & Promotion Process document |

## The source schema

Four tables covering the sales/orders/products domain: Customers,
Products (both SCD sources), Orders, OrderLines (the transactional fact
grain). Every table carries `CreatedDate` / `ModifiedDate`, which is
what makes incremental extraction and change detection possible
downstream. SQL Server itself updates these rows in place, exactly like
a normal OLTP system — it's only once data reaches `RAW_SM` that the
historical, append-only pattern applies.

## The "complex logic" layer, explained

This is the part worth walking through slowly with students — it's what
separates a toy pipeline from something that looks like real analytics
engineering work.

### 1. `fact_orders` — a real incremental model, not just a bigger table

```sql
{{ config(
    materialized='incremental',
    unique_key='order_line_id',
    incremental_strategy='merge'
) }}
...
{% if is_incremental() %}
where updated_at > (select coalesce(max(updated_at), '1900-01-01') from {{ this }})
{% endif %}
```

The interesting subtlety: `updated_at` on the joined row is
`GREATEST(order_line.updated_at, order.updated_at)` (see
`int_order_lines_enriched.sql`), not just the line's own timestamp. An
order **status change** doesn't touch `OrderLines.ModifiedDate` at all —
so a watermark built from the line alone would silently miss it, and an
order that ships would never update in the fact table. This is exactly
the kind of bug that's invisible until someone asks "why does this order
still say OPEN?" three weeks into production. The Day-2 exercise below
proves this actually works, not just that it looks plausible.

### 2. Two SCD2 snapshot strategies, side by side

`customers_snapshot` / `products_snapshot` use the **timestamp**
strategy (trust `updated_at`). `orders_status_snapshot` uses the
**check** strategy instead — it diffs `order_status` itself on every
run rather than trusting a timestamp. Worth asking students: when would
you not trust an upstream `updated_at` column enough to use the
timestamp strategy?

### 3. Window-function marts

- **`cust_metrics`**: `ROW_NUMBER()` for order sequence per customer,
  `LAG()` for days-since-previous-order, a running `SUM() OVER (... ROWS
  BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` for lifetime spend as of
  each order, and `NTILE(4)` to bucket customers into spend quartiles —
  feeding a simple `TOP SPENDER` / `AT RISK` / `ACTIVE` status label.
- **`product_performance`**: `RANK()` by revenue, a cumulative-revenue
  running total as a share of the grand total, and an ABC/Pareto
  classification (`A` = first 80% of revenue, `B` = next 15%, `C` =
  the rest) pulled out into the `abc_class` macro.

### 4. Macros as reusable business rules

`customer_tier_discount_pct` and `abc_class` are small, but they make the
point: a business rule defined once and referenced with `{{ }}` stays
consistent everywhere it's used, instead of being copy-pasted (and
drifting) across models.

### 5. Tests beyond `unique`/`not_null`

Three singular tests in `tests/`: an arithmetic invariant
(`line_total = quantity * unit_price`), a plausibility check (no
future-dated orders), and a sanity check on a window-function output
(`cumulative_revenue_pct` must be in `(0, 1]` and the top-ranked row must
reach ~1.0). These are the kind of tests schema-level `accepted_values`
and `relationships` tests can't express.

## Suggested walkthrough order for students

Two paths, depending on whether an Azure subscription is available:

**Path A — dbt-focused (no ADF/Azure needed):**

1. **Source system** — run `sql_server/01_create_schema.sql` then
   `sql_server/02_sample_data.sql` (first block only).
2. **Snowflake schemas** — run `snowflake/01_create_database_schema.sql`,
   then `snowflake/02_load_sample_data.sql` to populate `RAW_SM` directly.
3. **dbt project** — `dbt seed`/`dbt snapshot`/`dbt run`/`dbt test` (see
   below). Walk `stage_sm` → `intermediate_sm` → `marts` in order,
   pointing out the `QUALIFY` dedup in every staging model.

**Path B — the full pipeline, including ADF:**

1. **Source system** — run `sql_server/01_create_schema.sql`,
   `sql_server/02_sample_data.sql` (first block), and
   `sql_server/03_pipeline_watermark_control.sql` (the control table
   and watermark stored procedure ADF depends on).
2. **Snowflake** — run `snowflake/01_create_database_schema.sql`
   (`RAW_SM`, `STAGE_SM`, `INTERMEDIATE_SM`, `MARTS`, plus the
   `ADF_LOADER` role).
3. **Azure Data Factory** — deploy the linked services, datasets,
   pipelines, and trigger in `adf/` (see `adf/README.md`), then run
   `PL_Full_Historical_Load` once and watch it populate `RAW_SM`.
4. **dbt project** — same as Path A from here.

**Then, either path:**

4. **Run the Day-2 change batch** — the second block of
   `sql_server/02_sample_data.sql` (SQL Server itself still updates rows
   in place — it's a normal OLTP system), then either mirror it in
   `snowflake/02_load_sample_data.sql`'s "DAY 2" section (Path A — note
   these are `INSERT`s, not `UPDATE`s, matching `RAW_SM`'s historical
   design) or just re-run `PL_Incremental_Load` (Path B, which will pick
   up the changes via the watermark control table) — then re-run
   `dbt snapshot && dbt run`. Show students:
   - that `RAW_SM` now genuinely holds two rows for the changed
     customer/product/order, and that `stage_sm`'s `QUALIFY` dedup
     still correctly collapses each back down to one current row
   - the new `dbt_valid_from`/`dbt_valid_to` rows in `customers_snapshot`
     and `products_snapshot`
   - the same pattern in `orders_status_snapshot`, via the check strategy
   - that `fact_orders` picked up the order-5003 status change on its
     *existing* lines, even though only the order header changed —
     proof the `GREATEST()` watermark logic is doing its job

## Running dbt

Against Snowflake:

```bash
cd dbt_project
pip install dbt-snowflake
dbt deps                         # installs dbt_utils
# copy profiles.yml.sample -> ~/.dbt/profiles.yml and fill in credentials
dbt snapshot
dbt run
dbt test
dbt docs generate && dbt docs serve   # optional: browsable lineage graph
```

Against a free local DuckDB target, if you want students to run this
without a Snowflake account (this is exactly how the project was
validated while building it):

```bash
pip install dbt-core dbt-duckdb
# point profiles.yml at a local .duckdb file instead of Snowflake,
# load sample data via `dbt seed` from CSVs instead of the Snowflake
# scripts, then run the same dbt snapshot / run / test commands
```

## Environments and CI/CD

This build ships as a single Snowflake database for simplicity while
learning the pipeline. `snowflake/03_environment_setup.sql` and
`dbt_project/profiles.yml.sample` extend that to a real dev/test/prod
setup (separate databases, warehouses, and dbt targets), with
`macros/generate_schema_name.sql` giving each developer an isolated
schema in dev.

CI/CD is real, working GitHub Actions — not just documentation. See
**`GITHUB_SETUP.md`** for how to wire it up (repository/environment
secrets, branch protection, GitHub Environments):

- `.github/workflows/dbt_ci.yml` — runs `dbt build --target test` on
  every pull request and gates the merge on it passing.
- `.github/workflows/dbt_prod_deploy.yml` — runs `dbt build --target
  prod` on merge to `main`, nightly on a schedule, and on demand.

See the companion **Environment Strategy & Promotion Process** document
for the full explanation of the dev → test → prod promotion flow and a
complete command reference.

## Security notes to call out to students

- Warehouse credentials belong in environment variables or a secrets
  manager — never hardcoded in `profiles.yml` or committed to source
  control (`profiles.yml.sample` uses `env_var()` for exactly this reason).
- dbt's warehouse user runs under a dedicated `TRANSFORMER` role with
  read-only access to `RAW_SM` and write access only to its own schemas
  (`STAGE_SM`, `INTERMEDIATE_SM`, `MARTS`) — see the `GRANT` statements
  at the bottom of `snowflake/01_create_database_schema.sql`.
- ADF uses a separate, even more narrowly-scoped `ADF_LOADER` role that
  can only `INSERT` into `RAW_SM` — it has no access at all to anything
  dbt writes, so a compromised ADF credential can't touch a single
  downstream table.
- ADF's SQL Server and Snowflake credentials live in Azure Key Vault,
  read at runtime via ADF's managed identity — never typed into a
  linked service definition or committed anywhere (see
  `adf/linkedServices/LS_KeyVault.json`).

<!-- testing CI -->
