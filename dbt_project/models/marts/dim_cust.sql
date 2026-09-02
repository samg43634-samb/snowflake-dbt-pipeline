-- Type-2 customer dimension. Sources straight from the snapshot table, so
-- every historical tier/region change is preserved with its own valid
-- date range -- this is the dbt equivalent of the INT_<table>_HIST tables
-- built by the legacy Snowflake stored procedures.

with snap as (
    select * from {{ ref('customers_snapshot') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'dbt_valid_from']) }} as customer_sk,
    customer_id,
    customer_code,
    customer_name,
    region,
    country,
    customer_tier,
    is_active,
    dbt_valid_from                                   as valid_from,
    dbt_valid_to                                      as valid_to,
    (dbt_valid_to is null)                            as is_current
from snap
