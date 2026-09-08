with source as (
    select * from {{ source('raw', 'order_lines') }}
),

renamed as (
    select
        OrderLineId   as order_line_id,
        OrderId       as order_id,
        ProductId     as product_id,
        Quantity      as quantity,
        UnitPrice     as unit_price,
        LineTotal     as line_total,
        CreatedDate   as created_at,
        ModifiedDate  as updated_at
    from source
)

select * from renamed
