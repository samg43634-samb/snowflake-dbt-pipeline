{% snapshot customers_snapshot %}

{{
    config(
        target_schema='intermediate_sm',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=True
    )
}}

-- This is dbt's built-in replacement for the hand-written SCD stored
-- procedures in the legacy pipeline: every dbt run/scheduled job that
-- calls `dbt snapshot` compares the current source rows against the last
-- captured version and automatically inserts dbt_valid_from / dbt_valid_to
-- rows whenever a tracked column changes (e.g. CustomerTier, Region).

select
    customer_id,
    customer_code,
    customer_name,
    region,
    country,
    customer_tier,
    is_active,
    updated_at
from {{ ref('stg_customers') }}

{% endsnapshot %}
