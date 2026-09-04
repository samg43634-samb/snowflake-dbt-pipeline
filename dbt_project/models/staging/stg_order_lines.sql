{{
    config(
        materialized='incremental',
        unique_key='order_line_id',
        incremental_strategy='merge'
    )
}}

with source as (
    select * from {{ source('raw', 'order_lines') }}
    {% if is_incremental() %}
    where LOAD_TIMESTAMP > (select coalesce(max(load_timestamp), '1900-01-01') from {{ this }})
    {% endif %}
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
        ModifiedDate  as updated_at,
        LOAD_TIMESTAMP as load_timestamp
    from deduped
)

select * from renamed
