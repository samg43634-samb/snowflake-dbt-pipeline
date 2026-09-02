/* ============================================================================
   SNOWFLAKE -- LOAD SAMPLE DATA INTO RAW_SM
   Teaching example only.

   This loads the same rows as sql_server/02_sample_data.sql directly into
   ANALYTICS_DB.RAW_SM -- a fast, no-infrastructure stand-in for the real
   Azure Data Factory pipeline in adf/, so the dbt project can be built and
   tested without first standing up ADF, a self-hosted integration runtime,
   and a Snowflake connection. See adf/README.md for the actual
   production-shaped ETL pattern this project ships.

   RAW_SM is historical: every load is an INSERT, never an UPDATE. The
   "Day 2" block below deliberately never modifies a Day-1 row -- it adds
   new rows carrying the changed values, exactly like ADF's Copy activity
   would after re-extracting from SQL Server. Turning that history into a
   single current row per key is dbt's job (see models/staging/, which
   dedupes with QUALIFY ROW_NUMBER() ... ORDER BY LOAD_TIMESTAMP DESC).

   Every row is stamped with LOAD_TIMESTAMP / SOURCE_SYSTEM / OP_FLAG,
   mirroring the audit columns the real ADF pipeline adds via its
   Copy Activity "additional columns" feature.
   ============================================================================ */

USE DATABASE ANALYTICS_DB;
USE SCHEMA RAW_SM;

/* ---------------------------- Day 1 load ---------------------------- */

INSERT INTO CUSTOMERS (CustomerId, CustomerCode, CustomerName, Region, Country, CustomerTier, IsActive, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT * FROM VALUES
(1, 'CUST-001', 'Northwind Cooling Pte Ltd',   'APAC', 'Singapore',   'GOLD',   TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(2, 'CUST-002', 'Southern Cross Refrigeration','APAC', 'Australia',  'SILVER', TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(3, 'CUST-003', 'Delta Climate Systems BV',    'EMEA', 'Netherlands','GOLD',   TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(4, 'CUST-004', 'Atlas Industrial Supply',     'AMER', 'USA',        'BRONZE', TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(5, 'CUST-005', 'Pacific Rim Foodservice',     'APAC', 'Hong Kong',  'SILVER', TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(6, 'CUST-006', 'Coldline Logistics GmbH',     'EMEA', 'Germany',    'GOLD',   TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(7, 'CUST-007', 'Frostpoint Retail Group',     'AMER', 'Canada',     'BRONZE', TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(8, 'CUST-008', 'Meridian Cold Chain Co.',     'APAC', 'India',      'SILVER', TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I');

INSERT INTO PRODUCTS (ProductId, ProductCode, ProductName, Category, UnitPrice, UnitCost, IsActive, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT * FROM VALUES
(101, 'CMP-1000', 'Scroll Compressor 5HP',     'COMPRESSOR', 1250.00,  780.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(102, 'CMP-2000', 'Scroll Compressor 10HP',    'COMPRESSOR', 2100.00, 1340.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(103, 'CND-1000', 'Air-Cooled Condenser Unit', 'CONDENSER',   980.00,  610.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(104, 'CTL-1000', 'Digital Temp Controller',   'CONTROLS',    145.00,   72.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(105, 'CTL-2000', 'IoT Refrigeration Gateway', 'CONTROLS',    310.00,  165.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(106, 'SPR-1000', 'Expansion Valve Kit',       'SPARES',       65.00,   28.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(107, 'SPR-2000', 'Refrigerant Filter Drier',  'SPARES',       42.00,   18.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(108, 'CMP-3000', 'Scroll Compressor 15HP',    'COMPRESSOR', 2890.00, 1900.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I');

INSERT INTO ORDERS (OrderId, OrderNumber, CustomerId, OrderDate, OrderStatus, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT * FROM VALUES
(5001, 'SO-5001', 1, '2026-01-10'::DATE, 'INVOICED', '2026-01-10'::TIMESTAMP_NTZ, '2026-01-10'::TIMESTAMP_NTZ, '2026-01-10'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(5002, 'SO-5002', 2, '2026-01-11'::DATE, 'SHIPPED',  '2026-01-11'::TIMESTAMP_NTZ, '2026-01-11'::TIMESTAMP_NTZ, '2026-01-11'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(5003, 'SO-5003', 3, '2026-01-11'::DATE, 'OPEN',     '2026-01-11'::TIMESTAMP_NTZ, '2026-01-11'::TIMESTAMP_NTZ, '2026-01-11'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(5004, 'SO-5004', 4, '2026-01-12'::DATE, 'INVOICED', '2026-01-12'::TIMESTAMP_NTZ, '2026-01-12'::TIMESTAMP_NTZ, '2026-01-12'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(5005, 'SO-5005', 5, '2026-01-12'::DATE, 'OPEN',     '2026-01-12'::TIMESTAMP_NTZ, '2026-01-12'::TIMESTAMP_NTZ, '2026-01-12'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(5006, 'SO-5006', 6, '2026-01-13'::DATE, 'SHIPPED',  '2026-01-13'::TIMESTAMP_NTZ, '2026-01-13'::TIMESTAMP_NTZ, '2026-01-13'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(5007, 'SO-5007', 1, '2026-01-13'::DATE, 'INVOICED', '2026-01-13'::TIMESTAMP_NTZ, '2026-01-13'::TIMESTAMP_NTZ, '2026-01-13'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(5008, 'SO-5008', 7, '2026-01-14'::DATE, 'OPEN',     '2026-01-14'::TIMESTAMP_NTZ, '2026-01-14'::TIMESTAMP_NTZ, '2026-01-14'::TIMESTAMP_NTZ, 'SALES_ERP', 'I');

INSERT INTO ORDER_LINES (OrderLineId, OrderId, ProductId, Quantity, UnitPrice, LineTotal, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT * FROM VALUES
(90001, 5001, 101, 2, 1250.00, 2500.00, '2026-01-10'::TIMESTAMP_NTZ, '2026-01-10'::TIMESTAMP_NTZ, '2026-01-10'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(90002, 5001, 104, 2,  145.00,  290.00, '2026-01-10'::TIMESTAMP_NTZ, '2026-01-10'::TIMESTAMP_NTZ, '2026-01-10'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(90003, 5002, 102, 1, 2100.00, 2100.00, '2026-01-11'::TIMESTAMP_NTZ, '2026-01-11'::TIMESTAMP_NTZ, '2026-01-11'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(90004, 5003, 103, 3,  980.00, 2940.00, '2026-01-11'::TIMESTAMP_NTZ, '2026-01-11'::TIMESTAMP_NTZ, '2026-01-11'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(90005, 5003, 106, 4,   65.00,  260.00, '2026-01-11'::TIMESTAMP_NTZ, '2026-01-11'::TIMESTAMP_NTZ, '2026-01-11'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(90006, 5004, 108, 1, 2890.00, 2890.00, '2026-01-12'::TIMESTAMP_NTZ, '2026-01-12'::TIMESTAMP_NTZ, '2026-01-12'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(90007, 5005, 105, 5,  310.00, 1550.00, '2026-01-12'::TIMESTAMP_NTZ, '2026-01-12'::TIMESTAMP_NTZ, '2026-01-12'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(90008, 5006, 107, 10,  42.00,  420.00, '2026-01-13'::TIMESTAMP_NTZ, '2026-01-13'::TIMESTAMP_NTZ, '2026-01-13'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(90009, 5007, 101, 1, 1250.00, 1250.00, '2026-01-13'::TIMESTAMP_NTZ, '2026-01-13'::TIMESTAMP_NTZ, '2026-01-13'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(90010, 5008, 104, 6,  145.00,  870.00, '2026-01-14'::TIMESTAMP_NTZ, '2026-01-14'::TIMESTAMP_NTZ, '2026-01-14'::TIMESTAMP_NTZ, 'SALES_ERP', 'I');


/* ============================================================================
   "DAY 2" CHANGE BATCH -- run this after the SQL Server day-2 batch, then
   re-run dbt (snapshot && run && test). Mirrors sql_server/02_sample_data.sql's
   second block -- except here every change is an INSERT, never an UPDATE.
   The Day-1 rows above are never touched: RAW_SM ends this block holding
   TWO rows for CustomerId 2, TWO rows for ProductId 101, and TWO rows for
   OrderId 5003 -- exactly what a historical, append-only landing table
   should look like after something changes twice.
   ============================================================================ */

-- Customer 2: tier upgrade (SILVER -> GOLD). A real ADF full-reload of the
-- Customers table would re-extract every row; only the changed one is
-- shown here for brevity, but in practice all 8 customers would get a new
-- Day-2 row with this same LOAD_TIMESTAMP.
INSERT INTO CUSTOMERS (CustomerId, CustomerCode, CustomerName, Region, Country, CustomerTier, IsActive, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT * FROM VALUES
(2, 'CUST-002', 'Southern Cross Refrigeration', 'APAC', 'Australia', 'GOLD', TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, 'SALES_ERP', 'U');

-- Product 101: price increase.
INSERT INTO PRODUCTS (ProductId, ProductCode, ProductName, Category, UnitPrice, UnitCost, IsActive, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT * FROM VALUES
(101, 'CMP-1000', 'Scroll Compressor 5HP', 'COMPRESSOR', 1325.00, 780.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, 'SALES_ERP', 'U');

-- Order 5003: status change (OPEN -> SHIPPED) -- a header-only change with
-- no accompanying OrderLines row, on purpose (see fact_orders.sql's
-- GREATEST() watermark comment for why that matters downstream).
INSERT INTO ORDERS (OrderId, OrderNumber, CustomerId, OrderDate, OrderStatus, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT * FROM VALUES
(5003, 'SO-5003', 3, '2026-01-11'::DATE, 'SHIPPED', '2026-01-11'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, 'SALES_ERP', 'U');

-- Two brand-new orders.
INSERT INTO ORDERS (OrderId, OrderNumber, CustomerId, OrderDate, OrderStatus, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT * FROM VALUES
(5009, 'SO-5009', 8, '2026-01-17'::DATE, 'OPEN', '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(5010, 'SO-5010', 2, '2026-01-17'::DATE, 'OPEN', '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, 'SALES_ERP', 'I');

INSERT INTO ORDER_LINES (OrderLineId, OrderId, ProductId, Quantity, UnitPrice, LineTotal, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT * FROM VALUES
(90011, 5009, 102, 2, 2100.00, 4200.00, '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
(90012, 5010, 101, 1, 1325.00, 1325.00, '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, 'SALES_ERP', 'I');
