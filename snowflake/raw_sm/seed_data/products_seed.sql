INSERT INTO RAW_SM.PRODUCTS (ProductId, ProductCode, ProductName, Category, UnitPrice, UnitCost, IsActive, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT src.ProductId, src.ProductCode, src.ProductName, src.Category, src.UnitPrice, src.UnitCost, src.IsActive, src.CreatedDate, src.ModifiedDate, src.LOAD_TIMESTAMP, src.SOURCE_SYSTEM, src.OP_FLAG
FROM (
    SELECT * FROM VALUES
    (101, 'CMP-1000', 'Scroll Compressor 5HP',     'COMPRESSOR', 1250.00,  780.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (102, 'CMP-2000', 'Scroll Compressor 10HP',    'COMPRESSOR', 2100.00, 1340.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (103, 'CND-1000', 'Air-Cooled Condenser Unit', 'CONDENSER',   980.00,  610.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (104, 'CTL-1000', 'Digital Temp Controller',   'CONTROLS',    145.00,   72.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (105, 'CTL-2000', 'IoT Refrigeration Gateway', 'CONTROLS',    310.00,  165.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (106, 'SPR-1000', 'Expansion Valve Kit',       'SPARES',       65.00,   28.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (107, 'SPR-2000', 'Refrigerant Filter Drier',  'SPARES',       42.00,   18.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I'),
    (108, 'CMP-3000', 'Scroll Compressor 15HP',    'COMPRESSOR', 2890.00, 1900.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-05'::TIMESTAMP_NTZ, 'SALES_ERP', 'I')
) AS src(ProductId, ProductCode, ProductName, Category, UnitPrice, UnitCost, IsActive, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
WHERE NOT EXISTS (
    SELECT 1 FROM RAW_SM.PRODUCTS tgt
    WHERE tgt.ProductId = src.ProductId AND tgt.LOAD_TIMESTAMP = src.LOAD_TIMESTAMP
);

INSERT INTO RAW_SM.PRODUCTS (ProductId, ProductCode, ProductName, Category, UnitPrice, UnitCost, IsActive, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
SELECT src.ProductId, src.ProductCode, src.ProductName, src.Category, src.UnitPrice, src.UnitCost, src.IsActive, src.CreatedDate, src.ModifiedDate, src.LOAD_TIMESTAMP, src.SOURCE_SYSTEM, src.OP_FLAG
FROM (
    SELECT * FROM VALUES
    (101, 'CMP-1000', 'Scroll Compressor 5HP', 'COMPRESSOR', 1325.00, 780.00, TRUE, '2026-01-05'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, '2026-01-17'::TIMESTAMP_NTZ, 'SALES_ERP', 'U')
) AS src(ProductId, ProductCode, ProductName, Category, UnitPrice, UnitCost, IsActive, CreatedDate, ModifiedDate, LOAD_TIMESTAMP, SOURCE_SYSTEM, OP_FLAG)
WHERE NOT EXISTS (
    SELECT 1 FROM RAW_SM.PRODUCTS tgt
    WHERE tgt.ProductId = src.ProductId AND tgt.LOAD_TIMESTAMP = src.LOAD_TIMESTAMP
);
