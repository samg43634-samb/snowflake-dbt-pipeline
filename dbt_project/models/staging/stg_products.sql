{{
    config(
        materialized='incremental',
        unique_key='product_id',
        incremental_strategy='merge'
    )
}}

with source as (
    select * from {{ source('raw', 'products') }}
    {% if is_incremental() %}
    where LOAD_TIMESTAMP > (select coalesce(max(load_timestamp), '1900-01-01') from {{ this }})
    {% endif %}
),

deduped as (
    select *
    from source
    qualify row_number() over (
        partition by ProductId
        order by LOAD_TIMESTAMP desc
    ) = 1
),

renamed as (
    select
        ProductId        as product_id,
        ProductCode      as product_code,
        trim(ProductName) as product_name,
        upper(Category)  as category,
        UnitPrice        as unit_price,
        UnitCost         as unit_cost,
        IsActive         as is_active,
        CreatedDate      as created_at,
        ModifiedDate     as updated_at,
        LOAD_TIMESTAMP   as load_timestamp
    from deduped
)

select * from renamed
