#!/usr/bin/env python3
import subprocess
from io import StringIO
from time import time
import psycopg2
import logging

logger = logging.getLogger(__name__)

# Assuming these are defined elsewhere in the script
MDB_FILE = "/home/marche/Projects/xOpti.Import/SynergyV.mdb"  # Adjust path as needed
PG_HOST = "10.0.1.19"
PG_PORT = 5436
PG_DB = "xOpti"
PG_USER = "marche"
PG_PASSWORD = "mc@24949981"  # Replace with actual password
LOG_FILE = "import_log.csv"

def export_table_to_csv(mdb_file, table_name):
    # Placeholder for the export function; adjust as per your script
    result = subprocess.run(
        ["mdb-export", "-b", "strip", "-H", mdb_file, table_name],
        capture_output=True,
        text=True,
        check=True
    )
    csv_data = result.stdout
    row_count = len(csv_data.splitlines()) - 1 if csv_data.strip() else 0
    return csv_data, row_count

def clean_schema(schema):
    # Placeholder for schema cleaning; adjust as per your script
    lines = schema.splitlines()
    cleaned_lines = []
    for line in lines:
        if "CREATE INDEX" not in line:  # Simplified example
            cleaned_lines.append(line)
    cleaned_schema = "\n".join(cleaned_lines)
    # Add primary key corrections as needed
    cleaned_schema += '\nALTER TABLE "city" ADD CONSTRAINT "city_pkey" PRIMARY KEY ("code");'
    cleaned_schema += '\nALTER TABLE "country" ADD CONSTRAINT "country_pkey" PRIMARY KEY ("countrycode");'
    return cleaned_schema

def import_to_postgres(tables):
    conn = psycopg2.connect(
        host=PG_HOST,
        port=PG_PORT,
        database=PG_DB,
        user=PG_USER,
        password=PG_PASSWORD
    )
    cursor = conn.cursor()

    try:
        # Step 1: Clear existing tables using lowercase names
        for table in tables:
            table_lower = table.lower()
            cursor.execute(f"DROP TABLE IF EXISTS \"{table_lower}\" CASCADE;")
            logger.info(f"Cleared table|table={table_lower}")

        # Step 2: Recreate table structures
        start_time = time()
        schema = subprocess.run(
            ["mdb-schema", MDB_FILE, "postgres"],
            capture_output=True,
            text=True,
            check=True
        ).stdout
        cleaned_schema = clean_schema(schema)
        cursor.execute(cleaned_schema)
        conn.commit()
        elapsed_time = time() - start_time
        logger.info(f"Recreated table structures|xOpti|{elapsed_time:.2f}")

        # Step 3: Import data
        for table in tables:
            table_lower = table.lower()
            logger.info(f"Starting import|table={table_lower}")
            start_time = time()

            # Export using original table name
            csv_data, row_count = export_table_to_csv(MDB_FILE, table)
            if not csv_data.strip():
                logger.info(f"Skipping empty table|table={table_lower}|rows=0")
                continue

            csv_buffer = StringIO(csv_data)
            # Import using lowercase table name
            cursor.copy_expert(
                f"COPY \"{table_lower}\" FROM STDIN WITH (FORMAT csv, HEADER true)",
                csv_buffer
            )
            conn.commit()

            elapsed_time = time() - start_time
            logger.info(f"Imported data|table={table_lower}|rows={row_count}|time={elapsed_time:.2f}")

    except Exception as e:
        logger.error(f"Error occurred|details={str(e)}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

# Example usage
if __name__ == "__main__":
    tables = subprocess.run(["mdb-tables", "-1", MDB_FILE], capture_output=True, text=True, check=True).stdout.strip().split("\n")
    import_to_postgres(tables)