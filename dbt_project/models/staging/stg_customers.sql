{{
    config(
        materialized='incremental',
        unique_key='customer_id',
        incremental_strategy='merge'
    )
}}

with source as (
    select * from {{ source('raw', 'customers') }}
    {% if is_incremental() %}
    where LOAD_TIMESTAMP > (select coalesce(max(load_timestamp), '1900-01-01') from {{ this }})
    {% endif %}
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
        ModifiedDate        as updated_at,
        LOAD_TIMESTAMP      as load_timestamp
    from deduped
)

select * from renamed
