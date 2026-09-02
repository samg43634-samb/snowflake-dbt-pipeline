-- Singular test: fails (returns rows) if line_total ever drifts from
-- quantity * unit_price. Schema tests (unique/not_null/accepted_values)
-- can't express a cross-column arithmetic invariant like this -- that's
-- exactly the case a singular test is for. A failure here would point
-- to a real data quality problem upstream, not a dbt bug.

select
    order_line_id,
    quantity,
    unit_price,
    line_total,
    quantity * unit_price as expected_line_total
from {{ ref('fact_orders') }}
where abs(line_total - (quantity * unit_price)) > 0.01
