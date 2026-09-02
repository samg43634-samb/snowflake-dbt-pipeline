-- Grain: one row per order line. Joins to the *current* dimension rows
-- via is_current, which is the simplest pattern for a training example --
-- production models often instead pick the SCD row valid as-of order_date.
--
-- Materialized incremental: on the first run this builds the full table;
-- on every run after, it only rescans order lines whose updated_at is
-- newer than what's already in fact_orders, then MERGEs them in on
-- order_line_id. This is the real-world pattern for a fact table that
-- will eventually hold millions of rows -- a full rebuild every run
-- stops being viable long before that.

{{
    config(
        materialized='incremental',
        unique_key='order_line_id',
        incremental_strategy='merge',
        on_schema_change='fail'
    )
}}

with lines as (
    select * from {{ ref('int_order_lines_enriched') }}

    {% if is_incremental() %}
    -- Only reprocess rows that changed since the last run. `this` refers
    -- to the fact_orders table itself -- the standard dbt incremental
    -- watermark pattern.
    where updated_at > (select coalesce(max(updated_at), '1900-01-01') from {{ this }})
    {% endif %}
),

dim_customer as (
    select * from {{ ref('dim_cust') }} where is_current
),

dim_product as (
    select * from {{ ref('dim_products') }} where is_current
)

select
    l.order_line_id,
    l.order_id,
    l.order_number,
    l.order_date,
    l.order_status,
    dc.customer_sk,
    dc.customer_id,
    dc.customer_tier,
    dc.region,
    dp.product_sk,
    dp.product_id,
    dp.category,
    l.quantity,
    l.unit_price,
    l.line_total,
    (l.unit_price - dp.unit_cost) * l.quantity                          as gross_margin,
    round((l.unit_price - dp.unit_cost) * l.quantity / nullif(l.line_total, 0), 4) as gross_margin_pct,
    l.line_total * (1 - {{ customer_tier_discount_pct('dc.customer_tier') }})      as net_revenue_after_discount,
    l.updated_at
from lines l
left join dim_customer dc on l.customer_id = dc.customer_id
left join dim_product  dp on l.product_id  = dp.product_id
