CREATE TABLE IF NOT EXISTS RAW_SM.ORDER_LINES (
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
