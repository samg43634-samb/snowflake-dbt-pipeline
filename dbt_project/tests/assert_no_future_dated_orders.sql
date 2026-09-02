-- Singular test: an order_date in the future almost always means a
-- source-system data entry error or a timezone bug in the extraction
-- job -- worth catching explicitly rather than letting it silently
-- skew any trend analysis built on order_date.

select
    order_id,
    order_date
from {{ ref('stg_orders') }}
where order_date > current_date()
