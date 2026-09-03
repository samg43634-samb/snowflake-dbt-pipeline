"""
deploy_snowflake_sql.py
Runs every statement in a .sql file against Snowflake, using key-pair
authentication. Credentials come entirely from environment variables.

The target database is set on the CONNECTION itself, not with a
hardcoded USE DATABASE statement -- that is what makes every file under
snowflake/raw_sm/tables/ and snowflake/raw_sm/seed_data/ reusable across
dev/test/prod unchanged.

Usage:
    python scripts/deploy_snowflake_sql.py snowflake/raw_sm/tables/customers.sql

Required environment variables:
    SNOWFLAKE_ACCOUNT
    SNOWFLAKE_USER
    SNOWFLAKE_PRIVATE_KEY   -- full PEM contents of the private key
    SNOWFLAKE_DATABASE      -- optional; omit for account-level scripts
    SNOWFLAKE_ROLE          -- optional, defaults to TRANSFORMER
"""

import os
import sys

import snowflake.connector
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization


def load_private_key(pem_text: str) -> bytes:
    key = serialization.load_pem_private_key(
        pem_text.encode("utf-8"),
        password=None,
        backend=default_backend(),
    )
    return key.private_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )


def main() -> None:
    if len(sys.argv) != 2:
        print("Usage: python deploy_snowflake_sql.py <path-to-sql-file>")
        sys.exit(1)

    sql_path = sys.argv[1]
    with open(sql_path, "r", encoding="utf-8") as f:
        sql_text = f.read()

    private_key_der = load_private_key(os.environ["SNOWFLAKE_PRIVATE_KEY"])

    connect_kwargs = {
        "account": os.environ["SNOWFLAKE_ACCOUNT"],
        "user": os.environ["SNOWFLAKE_USER"],
        "private_key": private_key_der,
        "role": os.environ.get("SNOWFLAKE_ROLE", "TRANSFORMER"),
    }
    database = os.environ.get("SNOWFLAKE_DATABASE")
    if database:
        connect_kwargs["database"] = database

    conn = snowflake.connector.connect(**connect_kwargs)

    try:
        target_desc = database or "(account level, no database)"
        print(f"[{sql_path}] executing against {target_desc}...")
        cursors = conn.execute_string(sql_text)
        for i, cur in enumerate(cursors, start=1):
            query_preview = " ".join((cur.query or "").split())[:100]
            print(f"  [{i}] {query_preview}")
        print(f"[{sql_path}] all statements completed successfully")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
