{#
    customer_tier_discount_pct(tier_column)
    ------------------------------------------------------------------
    Returns the standard discount percentage for a customer tier.
    A deliberately simple example of pulling a business rule out of
    a single model and into a macro, so every model that needs the
    rule (marts, ad-hoc analysis, tests) applies it the same way
    instead of re-implementing a CASE statement each time.
#}
{% macro customer_tier_discount_pct(tier_column) %}
    case {{ tier_column }}
        when 'GOLD'   then 0.10
        when 'SILVER' then 0.05
        when 'BRONZE' then 0.00
        else 0.00
    end
{% endmacro %}
