with snap as (
    select * from {{ ref('products_snapshot') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['product_id', 'dbt_valid_from']) }} as product_sk,
    product_id,
    product_code,
    product_name,
    category,
    unit_price,
    unit_cost,
    is_active,
    dbt_valid_from                as valid_from,
    dbt_valid_to                  as valid_to,
    (dbt_valid_to is null)        as is_current
from snap
