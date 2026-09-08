with source as (
    select * from {{ source('raw', 'orders') }}
),

renamed as (
    select
        OrderId       as order_id,
        OrderNumber   as order_number,
        CustomerId    as customer_id,
        OrderDate     as order_date,
        upper(OrderStatus) as order_status,
        CreatedDate   as created_at,
        ModifiedDate  as updated_at
    from source
)

select * from renamed
