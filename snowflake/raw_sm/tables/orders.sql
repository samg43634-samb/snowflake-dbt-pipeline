CREATE TABLE IF NOT EXISTS RAW_SM.ORDERS (
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
