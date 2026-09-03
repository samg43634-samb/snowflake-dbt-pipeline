CREATE TABLE IF NOT EXISTS RAW_SM.PRODUCTS (
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
