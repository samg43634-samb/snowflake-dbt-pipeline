/* ============================================================================
   SNOWFLAKE -- PER-ENVIRONMENT DATABASES, WAREHOUSES, AND ROLES
   Teaching example only.

   Three fully separate databases -- not three schemas in one database.
   That's a deliberate choice: it means a mistake in dev (a dropped table,
   a runaway full-refresh) has zero blast radius on test or prod, and it
   lets each environment scale its warehouse independently (dev stays on
   a cheap XSMALL; prod can be sized for its actual concurrent load).

   Run this once as an ACCOUNTADMIN or a role with CREATE DATABASE /
   CREATE WAREHOUSE / CREATE ROLE privileges. Run 01_create_database_schema.sql
   and 02_load_sample_data.sql once per environment afterward, pointed at
   each database in turn.
   ============================================================================ */

-- ---------------------------------------------------------------------------
-- Warehouses -- sized per environment. Dev and TEST auto-suspend fast since
-- they're used in short bursts; prod is slightly larger and still
-- auto-suspends, since Snowflake bills by the second either way.
-- ---------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS ANALYTICS_WH_DEV  WITH WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60;
CREATE WAREHOUSE IF NOT EXISTS ANALYTICS_WH_TEST WITH WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60;
CREATE WAREHOUSE IF NOT EXISTS ANALYTICS_WH_PROD WITH WAREHOUSE_SIZE = 'SMALL'  AUTO_SUSPEND = 120;

-- ---------------------------------------------------------------------------
-- Databases -- one per environment, same internal shape (RAW_SM / STAGE_SM /
-- INTERMEDIATE_SM / MARTS), created by re-running 01_create_database_schema.sql
-- with ANALYTICS_DB swapped for each of these.
-- ---------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS ANALYTICS_DB_DEV;
CREATE DATABASE IF NOT EXISTS ANALYTICS_DB_TEST;
CREATE DATABASE IF NOT EXISTS ANALYTICS_DB_PROD;

-- ---------------------------------------------------------------------------
-- Roles -- one TRANSFORMER role, granted on all three databases, so the
-- same role name works in every dbt target. Real setups typically split
-- this into TRANSFORMER_DEV / TRANSFORMER_PROD instead so a leaked dev
-- credential can't touch prod at all; kept as one role here to keep the
-- teaching example's moving parts manageable.
-- ---------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS TRANSFORMER;

GRANT USAGE ON WAREHOUSE ANALYTICS_WH_DEV  TO ROLE TRANSFORMER;
GRANT USAGE ON WAREHOUSE ANALYTICS_WH_TEST TO ROLE TRANSFORMER;
GRANT USAGE ON WAREHOUSE ANALYTICS_WH_PROD TO ROLE TRANSFORMER;

GRANT USAGE ON DATABASE ANALYTICS_DB_DEV  TO ROLE TRANSFORMER;
GRANT USAGE ON DATABASE ANALYTICS_DB_TEST TO ROLE TRANSFORMER;
GRANT USAGE ON DATABASE ANALYTICS_DB_PROD TO ROLE TRANSFORMER;

-- Re-run the RAW_SM/STAGE_SM/INTERMEDIATE_SM/MARTS schema + grant statements from
-- 01_create_database_schema.sql against each database in turn, e.g.:
--   USE DATABASE ANALYTICS_DB_DEV;  <then the CREATE SCHEMA / GRANT statements>
--   USE DATABASE ANALYTICS_DB_TEST; <same statements again>
--   USE DATABASE ANALYTICS_DB_PROD; <same statements again>

-- ---------------------------------------------------------------------------
-- Optional: give TEST a cheap way to start from realistic data instead of
-- reloading sample data by hand -- Snowflake zero-copy cloning takes a
-- point-in-time copy of prod's RAW_SM schema without duplicating storage or
-- touching prod itself. A common pattern for a nightly TEST refresh job.
-- ---------------------------------------------------------------------------
-- CREATE OR REPLACE SCHEMA ANALYTICS_DB_TEST.RAW_SM CLONE ANALYTICS_DB_PROD.RAW_SM;
