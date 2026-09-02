-- Materialized as a view in intermediate_sm (see dbt_project.yml) -- joins
-- order header attributes onto each line, ready for the fact table.
--
-- updated_at is deliberately the GREATEST of the line's own timestamp and
-- its parent order's timestamp. A header-only change -- an order status
-- update, for instance -- doesn't touch OrderLines.ModifiedDate at all,
-- so a watermark built from the line alone would silently miss it. This
-- is the kind of edge case that's easy to overlook in an incremental
-- design and worth walking through with students explicitly.

with lines as (
    select * from {{ ref('stg_order_lines') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

joined as (
    select
        l.order_line_id,
        l.order_id,
        o.order_number,
        o.customer_id,
        o.order_date,
        o.order_status,
        l.product_id,
        l.quantity,
        l.unit_price,
        l.line_total,
        greatest(l.updated_at, o.updated_at) as updated_at
    from lines l
    inner join orders o on l.order_id = o.order_id
)

select * from joined
