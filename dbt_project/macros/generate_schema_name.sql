{#
    Overrides dbt's default schema-naming behavior.

    In test/prod, models build into exactly the schema configured in
    dbt_project.yml (e.g. "stage_sm", "marts") -- predictable, so BI tools
    know where to look.

    In dev, every developer shares the same ANALYTICS_DB_DEV database, so
    without this override two developers running `dbt run --target dev`
    at the same time would both write to the same "stage_sm" schema and
    stomp on each other. Instead each developer's models land in a
    personal schema like DBT_DEV_JSMITH_STAGE_SM -- isolated, and obvious
    who it belongs to.

    This is a very common real-world dbt customization; it's usually one
    of the first things a new dbt project needs once more than one person
    is developing against the same warehouse.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if target.name == 'dev' -%}
        {#- e.g. DBT_DEV_JSMITH_STAGING, derived from the warehouse user -#}
        {{ default_schema }}_{{ target.user | lower | replace('.', '_') }}
        {%- if custom_schema_name is not none -%}_{{ custom_schema_name | trim }}{%- endif -%}

    {%- elif custom_schema_name is none -%}
        {{ default_schema }}

    {%- else -%}
        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
