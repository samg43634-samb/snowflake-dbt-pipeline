-- See stg_customers.sql for why the QUALIFY dedup is here: RAW_SM is
-- historical, so a product can appear more than once (e.g. a price change).

with source as (
    select * from {{ source('raw', 'products') }}
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
        ModifiedDate     as updated_at
    from deduped
)

select * from renamed
