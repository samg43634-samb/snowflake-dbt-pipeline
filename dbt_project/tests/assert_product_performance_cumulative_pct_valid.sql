-- Singular test: cumulative_revenue_pct is a running share of total
-- revenue, so every row must land in (0, 1] and the highest-ranked row
-- must be at (or extremely close to) 1.0. A useful pattern for
-- validating a window-function calculation, not just a plain column.

with bad_range as (
    select product_id, cumulative_revenue_pct
    from {{ ref('product_performance') }}
    where cumulative_revenue_pct <= 0 or cumulative_revenue_pct > 1
),

bad_max as (
    select max(cumulative_revenue_pct) as max_pct
    from {{ ref('product_performance') }}
    having max(cumulative_revenue_pct) < 0.999
)

select 'out_of_range' as issue, product_id::string as detail from bad_range
union all
select 'max_not_near_one' as issue, max_pct::string as detail from bad_max
