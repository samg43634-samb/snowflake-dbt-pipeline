CREATE OR REPLACE TABLE RAW_SM.CUSTOMERS (
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
