{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge'
    )
}}

with source as (
    select * from {{ source('raw', 'orders') }}
    {% if is_incremental() %}
    where LOAD_TIMESTAMP > (select coalesce(max(load_timestamp), '1900-01-01') from {{ this }})
    {% endif %}
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
        ModifiedDate  as updated_at,
        LOAD_TIMESTAMP as load_timestamp
    from deduped
)

select * from renamed
