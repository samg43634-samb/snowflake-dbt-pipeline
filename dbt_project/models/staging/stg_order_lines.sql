-- See stg_customers.sql for why the QUALIFY dedup is here.

with source as (
    select * from {{ source('raw', 'order_lines') }}
),

deduped as (
    select *
    from source
    qualify row_number() over (
        partition by OrderLineId
        order by LOAD_TIMESTAMP desc
    ) = 1
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
    from deduped
)

select * from renamed
