/* ============================================================================
   SNOWFLAKE -- DATABASE AND SCHEMAS
   Teaching example only. All names are generic.

   Four schemas, each with one clear job:

     RAW_SM           1:1 with the source, HISTORICAL. ADF appends every
                       extraction here -- it never updates or deletes a row.
                       A key can legitimately appear more than once.

     STAGE_SM          dbt's staging layer. Type casting, null handling, and
                       -- because RAW_SM is historical -- deduplication down
                       to exactly one current row per key.

     INTERMEDIATE_SM   dbt's SCD2 snapshots and intermediate-join models:
                       customers_snapshot, products_snapshot,
                       orders_status_snapshot, and int_order_lines_enriched
                       all build here.

     MARTS             Final, analytics-ready tables: dim_cust, dim_products,
                       fact_orders, cust_metrics, product_performance.

   RAW_SM is dbt's only source; nothing downstream ever reads SQL Server or
   ADF's staging area directly.
   ============================================================================ */

CREATE DATABASE IF NOT EXISTS ANALYTICS_DB;

CREATE SCHEMA IF NOT EXISTS ANALYTICS_DB.RAW_SM;
CREATE SCHEMA IF NOT EXISTS ANALYTICS_DB.STAGE_SM;
CREATE SCHEMA IF NOT EXISTS ANALYTICS_DB.INTERMEDIATE_SM;
CREATE SCHEMA IF NOT EXISTS ANALYTICS_DB.MARTS;

USE DATABASE ANALYTICS_DB;
USE SCHEMA RAW_SM;

/* No primary key is declared -- Snowflake doesn't enforce them, and RAW_SM
   is expected to hold more than one row per business key over time. It's
   an append-only history of everything ADF has ever extracted. */

CREATE OR REPLACE TABLE CUSTOMERS (
    CustomerId      INT,
    CustomerCode    STRING,
    CustomerName    STRING,
    Region          STRING,
    Country         STRING,
    CustomerTier    STRING,
    IsActive        BOOLEAN,
    CreatedDate     TIMESTAMP_NTZ,
    ModifiedDate    TIMESTAMP_NTZ,
    LOAD_TIMESTAMP  TIMESTAMP_NTZ,
    SOURCE_SYSTEM   STRING,
    OP_FLAG         STRING
);

CREATE OR REPLACE TABLE PRODUCTS (
    ProductId       INT,
    ProductCode     STRING,
    ProductName     STRING,
    Category        STRING,
    UnitPrice       NUMBER(10,2),
    UnitCost        NUMBER(10,2),
    IsActive        BOOLEAN,
    CreatedDate     TIMESTAMP_NTZ,
    ModifiedDate    TIMESTAMP_NTZ,
    LOAD_TIMESTAMP  TIMESTAMP_NTZ,
    SOURCE_SYSTEM   STRING,
    OP_FLAG         STRING
);

CREATE OR REPLACE TABLE ORDERS (
    OrderId         INT,
    OrderNumber     STRING,
    CustomerId      INT,
    OrderDate       DATE,
    OrderStatus     STRING,
    CreatedDate     TIMESTAMP_NTZ,
    ModifiedDate    TIMESTAMP_NTZ,
    LOAD_TIMESTAMP  TIMESTAMP_NTZ,
    SOURCE_SYSTEM   STRING,
    OP_FLAG         STRING
);

CREATE OR REPLACE TABLE ORDER_LINES (
    OrderLineId     INT,
    OrderId         INT,
    ProductId       INT,
    Quantity        INT,
    UnitPrice       NUMBER(10,2),
    LineTotal       NUMBER(12,2),
    CreatedDate     TIMESTAMP_NTZ,
    ModifiedDate    TIMESTAMP_NTZ,
    LOAD_TIMESTAMP  TIMESTAMP_NTZ,
    SOURCE_SYSTEM   STRING,
    OP_FLAG         STRING
);

/* A dedicated role/warehouse for dbt keeps permissions tight. dbt only ever
   reads RAW_SM and writes STAGE_SM / INTERMEDIATE_SM / MARTS -- it can
   never modify the historical record ADF is building. */
CREATE WAREHOUSE IF NOT EXISTS ANALYTICS_WH WITH WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60;
CREATE ROLE IF NOT EXISTS TRANSFORMER;

GRANT USAGE ON DATABASE ANALYTICS_DB TO ROLE TRANSFORMER;
GRANT USAGE ON WAREHOUSE ANALYTICS_WH TO ROLE TRANSFORMER;

GRANT USAGE ON SCHEMA ANALYTICS_DB.RAW_SM TO ROLE TRANSFORMER;
GRANT SELECT ON ALL TABLES IN SCHEMA ANALYTICS_DB.RAW_SM TO ROLE TRANSFORMER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA ANALYTICS_DB.RAW_SM TO ROLE TRANSFORMER;

GRANT ALL ON SCHEMA ANALYTICS_DB.STAGE_SM TO ROLE TRANSFORMER;
GRANT ALL ON SCHEMA ANALYTICS_DB.INTERMEDIATE_SM TO ROLE TRANSFORMER;
GRANT ALL ON SCHEMA ANALYTICS_DB.MARTS TO ROLE TRANSFORMER;

/* ADF's loader role, by contrast, only ever appends to RAW_SM -- it has no
   access at all to STAGE_SM, INTERMEDIATE_SM, or MARTS. */
CREATE ROLE IF NOT EXISTS ADF_LOADER;
GRANT USAGE ON DATABASE ANALYTICS_DB TO ROLE ADF_LOADER;
GRANT USAGE ON WAREHOUSE ANALYTICS_WH TO ROLE ADF_LOADER;
GRANT USAGE ON SCHEMA ANALYTICS_DB.RAW_SM TO ROLE ADF_LOADER;
GRANT INSERT ON ALL TABLES IN SCHEMA ANALYTICS_DB.RAW_SM TO ROLE ADF_LOADER;
