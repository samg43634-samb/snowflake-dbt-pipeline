with source as (
    select * from {{ source('raw', 'products') }}
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
    from source
)

select * from renamed
