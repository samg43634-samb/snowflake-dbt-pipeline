-- Staging (stage_sm): type casting, null handling, and -- because RAW_SM
-- is historical -- deduplication down to exactly one current row per key.
-- QUALIFY + ROW_NUMBER() is the standard Snowflake pattern for this: rank
-- every row for a given customer_id by how recently it was loaded, and
-- keep only the most recent. No other business logic belongs here.

with source as (
    select * from {{ source('raw', 'customers') }}
),

deduped as (
    select *
    from source
    qualify row_number() over (
        partition by CustomerId
        order by LOAD_TIMESTAMP desc
    ) = 1
),

renamed as (
    select
        CustomerId          as customer_id,
        CustomerCode        as customer_code,
        trim(CustomerName)  as customer_name,
        upper(Region)       as region,
        Country             as country,
        upper(CustomerTier) as customer_tier,
        IsActive            as is_active,
        CreatedDate         as created_at,
        ModifiedDate        as updated_at
    from deduped
)

select * from renamed
