-- See stg_customers.sql for why the QUALIFY dedup is here: RAW_SM is
-- historical, so an order can appear more than once (e.g. a status change).

with source as (
    select * from {{ source('raw', 'orders') }}
),

deduped as (
    select *
    from source
    qualify row_number() over (
        partition by OrderId
        order by LOAD_TIMESTAMP desc
    ) = 1
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
    from deduped
)

select * from renamed
