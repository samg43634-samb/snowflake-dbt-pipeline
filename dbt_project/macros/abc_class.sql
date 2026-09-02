{#
    abc_class(cumulative_pct_column)
    ------------------------------------------------------------------
    Classic ABC/Pareto classification from a running cumulative-revenue
    percentage: the products responsible for the first 80% of revenue
    are 'A', the next 15% are 'B', and the rest are 'C'. Centralizing
    the thresholds here means product_performance.sql stays readable,
    and the thresholds can be tuned in one place.
#}
{% macro abc_class(cumulative_pct_column) %}
    case
        when {{ cumulative_pct_column }} <= 0.80 then 'A'
        when {{ cumulative_pct_column }} <= 0.95 then 'B'
        else 'C'
    end
{% endmacro %}
