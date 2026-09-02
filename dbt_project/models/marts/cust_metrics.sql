-- Customer-level analytics built with window functions -- the kind of
-- logic that shows up in almost every real analytics engineering project
-- and that a purely 1:1 staging-to-mart pipeline never exercises.
--
-- Grain: one row per customer.

with order_totals as (
    -- Roll fact_orders (grain: order line) up to grain: order.
    -- CANCELLED orders are excluded from spend/recency metrics but a
    -- cancelled order still counts as a "touch" -- deliberately not
    -- filtered out upstream so this decision stays visible here.
    select
        order_id,
        customer_id,
        customer_sk,
        order_date,
        order_status,
        sum(line_total) as order_amount
    from {{ ref('fact_orders') }}
    group by order_id, customer_id, customer_sk, order_date, order_status
),

valid_orders as (
    select * from order_totals where order_status != 'CANCELLED'
),

sequenced as (
    select
        *,
        -- Order # for this customer, oldest first.
        row_number() over (
            partition by customer_id order by order_date, order_id
        ) as order_sequence,
        -- Gap since the customer's previous order, in days. NULL on
        -- their first order, which is the correct answer, not a bug.
        datediff(
            'day',
            lag(order_date) over (partition by customer_id order by order_date, order_id),
            order_date
        ) as days_since_previous_order,
        -- Running lifetime spend as of each order, oldest first.
        sum(order_amount) over (
            partition by customer_id order by order_date, order_id
            rows between unbounded preceding and current row
        ) as running_customer_spend
    from valid_orders
),

customer_rollup as (
    select
        customer_id,
        count(distinct order_id)                    as total_orders,
        sum(order_amount)                            as lifetime_spend,
        round(avg(order_amount), 2)                  as avg_order_value,
        min(order_date)                              as first_order_date,
        max(order_date)                              as last_order_date,
        max(order_sequence)                          as latest_order_sequence,
        max(running_customer_spend)                  as running_spend_as_of_latest_order,
        avg(days_since_previous_order)                as avg_days_between_orders
    from sequenced
    group by customer_id
),

segmented as (
    select
        c.*,
        datediff('day', c.last_order_date, current_date()) as days_since_last_order,
        -- Quartile by lifetime spend: 1 = top spenders. NTILE is the
        -- standard window function for this kind of even-bucket split.
        ntile(4) over (order by c.lifetime_spend desc) as spend_quartile
    from customer_rollup c
)

select
    dc.customer_id,
    dc.customer_name,
    dc.customer_tier,
    dc.region,
    s.total_orders,
    s.lifetime_spend,
    s.avg_order_value,
    s.first_order_date,
    s.last_order_date,
    s.days_since_last_order,
    s.avg_days_between_orders,
    s.spend_quartile,
    case
        when s.spend_quartile = 1 then 'TOP SPENDER'
        when s.days_since_last_order > 60 then 'AT RISK'
        else 'ACTIVE'
    end as customer_status
from segmented s
inner join {{ ref('dim_cust') }} dc
    on s.customer_id = dc.customer_id and dc.is_current
