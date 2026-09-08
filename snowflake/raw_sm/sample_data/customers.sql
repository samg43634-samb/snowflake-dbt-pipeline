INSERT INTO RAW_SM.CUSTOMERS (CustomerId, CustomerCode, CustomerName, Region, Country, CustomerTier, IsActive, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT src.CustomerId, src.CustomerCode, src.CustomerName, src.Region, src.Country, src.CustomerTier, src.IsActive, src.CreatedDate, src.ModifiedDate, src.LOAD_TIMESTAMP, src.SOURCE_SYSTEM, src.OP_FLAG
FROM (
    SELECT * FROM VALUES
    (1, 'CUST-001', 'Northwind Cooling Pte Ltd',   'APAC', 'Singapore',   'GOLD',   TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (2, 'CUST-002', 'Southern Cross Refrigeration','APAC', 'Australia',  'SILVER', TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (3, 'CUST-003', 'Delta Climate Systems BV',    'EMEA', 'Netherlands','GOLD',   TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (4, 'CUST-004', 'Atlas Industrial Supply',     'AMER', 'USA',        'BRONZE', TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (5, 'CUST-005', 'Pacific Rim Foodservice',     'APAC', 'Hong Kong',  'SILVER', TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (6, 'CUST-006', 'Coldline Logistics GmbH',     'EMEA', 'Germany',    'GOLD',   TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (7, 'CUST-007', 'Frostpoint Retail Group',     'AMER', 'Canada',     'BRONZE', TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (8, 'CUST-008', 'Meridian Cold Chain Co.',     'APAC', 'India',      'SILVER', TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I')
) AS src(CustomerId, CustomerCode, CustomerName, Region, Country, CustomerTier, IsActive, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
WHERE NOT EXISTS (
    SELECT 1 FROM RAW_SM.CUSTOMERS tgt
    WHERE tgt.CustomerId = src.CustomerId
);

INSERT INTO RAW_SM.CUSTOMERS (CustomerId, CustomerCode, CustomerName, Region, Country, CustomerTier, IsActive, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT src.CustomerId, src.CustomerCode, src.CustomerName, src.Region, src.Country, src.CustomerTier, src.IsActive, src.CreatedDate, src.ModifiedDate, src.LOAD_TIMESTAMP, src.SOURCE_SYSTEM, src.OP_FLAG
FROM (
    SELECT * FROM VALUES
    (2, 'CUST-002', 'Southern Cross Refrigeration', 'APAC', 'Australia', 'GOLD', TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, 'SALES_ERP', 'U')
) AS src(CustomerId, CustomerCode, CustomerName, Region, Country, CustomerTier, IsActive, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
WHERE NOT EXISTS (
    SELECT 1 FROM RAW_SM.CUSTOMERS tgt
    WHERE tgt.CustomerId = src.CustomerId
);

UPDATE RAW_SM.CUSTOMERS
SET IsActive = FALSE,
    ModifiedDate = '2026-01-20'::TIMESTAMP_NTZ
WHERE CustomerId NOT IN (1, 2, 3, 4, 5, 7, 8)
  AND IsActive = TRUE;
