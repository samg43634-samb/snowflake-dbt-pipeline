{% snapshot products_snapshot %}

{{
    config(
        target_schema='intermediate_sm',
        unique_key='product_id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=True
    )
}}

select
    product_id,
    product_code,
    product_name,
    category,
    unit_price,
    unit_cost,
    is_active,
    updated_at
from {{ ref('stg_products') }}

{% endsnapshot %}
