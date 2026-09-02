-- Product-level analytics: revenue ranking and classic ABC/Pareto
-- classification. A second, different window-function pattern from
-- cust_metrics.sql (running total as a share of a grand total,
-- rather than a per-customer running total) worth contrasting with
-- students.
--
-- Grain: one row per product.

with product_sales as (
    select
        product_id,
        category,
        sum(line_total)     as revenue,
        sum(gross_margin)   as total_margin,
        sum(quantity)       as units_sold
    from {{ ref('fact_orders') }}
    group by product_id, category
),

ranked as (
    select
        *,
        rank() over (order by revenue desc) as revenue_rank,
        -- Running revenue total, richest product first, as a share of
        -- total revenue -- the input to an ABC/Pareto classification.
        sum(revenue) over (
            order by revenue desc
            rows between unbounded preceding and current row
        ) / sum(revenue) over () as cumulative_revenue_pct
    from product_sales
)

select
    dp.product_id,
    dp.product_code,
    dp.product_name,
    r.category,
    r.units_sold,
    r.revenue,
    r.total_margin,
    round(r.total_margin / nullif(r.revenue, 0), 4) as margin_pct,
    r.revenue_rank,
    round(r.cumulative_revenue_pct, 4)              as cumulative_revenue_pct,
    {{ abc_class('r.cumulative_revenue_pct') }}      as abc_class
from ranked r
inner join {{ ref('dim_products') }} dp
    on r.product_id = dp.product_id and dp.is_current
order by r.revenue_rank
