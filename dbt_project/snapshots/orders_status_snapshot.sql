{% snapshot orders_status_snapshot %}

{{
    config(
        target_schema='intermediate_sm',
        unique_key='order_id',
        strategy='check',
        check_cols=['order_status'],
        invalidate_hard_deletes=True
    )
}}

-- Deliberately uses the CHECK strategy instead of the TIMESTAMP strategy
-- used in customers_snapshot / products_snapshot, so students see both:
--   - timestamp strategy: trust an updated_at column to know something changed
--   - check strategy: no reliable updated_at, so dbt diffs specific columns
--     itself on every snapshot run to detect a change
-- Order status is a good example of state worth tracking over time (how
-- long did an order sit OPEN before shipping?) where you might not trust
-- upstream timestamps to be maintained consistently.

select
    order_id,
    order_number,
    customer_id,
    order_date,
    order_status
from {{ ref('stg_orders') }}

{% endsnapshot %}
