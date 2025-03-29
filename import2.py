#!/usr/bin/env python3
import os
import subprocess
from io import StringIO
from time import time
import psycopg2
import logging
from dotenv import load_dotenv
# Import the 'sub' function from the 're' module for regular expression substitution
from re import sub

# Load environment variables from .env file
load_dotenv()

# Configure logging
LOG_FILE = "import_log.csv"
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Fetch sensitive information from environment variables
PG_HOST = os.getenv("PG_HOST", "localhost")
PG_PORT = int(os.getenv("PG_PORT", 5432))
PG_DB = os.getenv("PG_DB")
PG_USER = os.getenv("PG_USER")
PG_PASSWORD = os.getenv("PG_PASSWORD")
MDB_FILE = os.getenv("MDB_FILE")

if not all([PG_DB, PG_USER, PG_PASSWORD, MDB_FILE]):
    raise ValueError("Missing required environment variables. Check your .env file.")

# Define a function to convert a string to snake case
def snake_case(s):
    # Replace hyphens with spaces, then apply regular expression substitutions for title case conversion
    # and add an underscore between words, finally convert the result to lowercase
    return '_'.join(
        sub('([A-Z][a-z]+)', r' \1',
        sub('([A-Z]+)', r' \1',
        s.replace('-', ' '))).split()).lower()

def export_table_to_csv(mdb_file, table_name):
    """Export a table from an MDB file to CSV format."""
    try:
        result = subprocess.run(
            ["mdb-export", "-b", "strip", "-H", mdb_file, table_name],
            capture_output=True,
            text=True,
            check=True
        )
        csv_data = result.stdout
        row_count = len(csv_data.splitlines()) - 1 if csv_data.strip() else 0
        return csv_data, row_count
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to export table|table={table_name}|error={e.stderr}")
        raise

def clean_schema(schema):
    """Clean and adjust the schema for PostgreSQL compatibility."""
    #
    # Convert all quoted identifiers to lowercase
    schema = sub(r'"([^"]+)"', lambda match: f'"{match.group(1).lower()}"', schema)

    lines = schema.splitlines()
    cleaned_lines = []
    for line in lines:
        if "CREATE INDEX" not in line:  # Remove index creation
            cleaned_lines.append(line)
    cleaned_schema = "\n".join(cleaned_lines)
    # Add primary key corrections
#    cleaned_schema += '\nALTER TABLE "city" ADD CONSTRAINT "city_pkey" PRIMARY KEY ("code");'
#    cleaned_schema += '\nALTER TABLE "country" ADD CONSTRAINT "country_pkey" PRIMARY KEY ("countrycode");'
    return cleaned_schema

def import_to_postgres(mdb_file, tables):
    """Import data from an MDB file into PostgreSQL."""
    conn = psycopg2.connect(
        host=PG_HOST,
        port=PG_PORT,
        database=PG_DB,
        user=PG_USER,
        password=PG_PASSWORD
    )
    cursor = conn.cursor()

    try:
        # Step 1: Clear existing tables
        for table in tables:
            table_lower = table.lower()
            cursor.execute(f"DROP TABLE IF EXISTS \"{table_lower}\" CASCADE;")
            logger.info(f"Cleared table|table={table_lower}")

        # Step 2: Recreate table structures
        start_time = time()
        schema = subprocess.run(
            ["mdb-schema", mdb_file, "postgres"],
            capture_output=True,
            text=True,
            check=True
        ).stdout
        cleaned_schema = clean_schema(schema)
        cursor.execute(cleaned_schema)
        conn.commit()
        elapsed_time = time() - start_time
        logger.info(f"Recreated table structures|time={elapsed_time:.2f}s")

        # Step 3: Import data
        for table in tables:
            table_lower = table.lower()
            logger.info(f"Starting import|table={table_lower}")
            start_time = time()

            # Export table data
            csv_data, row_count = export_table_to_csv(mdb_file, table)
            if not csv_data.strip():
                logger.info(f"Skipping empty table|table={table_lower}|rows=0")
                continue

            csv_buffer = StringIO(csv_data)
            # Import data into PostgreSQL
            cursor.copy_expert(
                f"COPY \"{table_lower}\" FROM STDIN WITH (FORMAT csv, HEADER true)",
                csv_buffer
            )
            conn.commit()

            elapsed_time = time() - start_time
            logger.info(f"Imported data|table={table_lower}|rows={row_count}|time={elapsed_time:.2f}s")

    except Exception as e:
        logger.error(f"Error occurred|details={str(e)}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    # Fetch table names from the MDB file
    try:
        tables = subprocess.run(
            ["mdb-tables", "-1", MDB_FILE],
            capture_output=True,
            text=True,
            check=True
        ).stdout.strip().split("\n")
        if not tables:
            logger.error("No tables found in the MDB file.")
            exit(1)
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to fetch table names|error={e.stderr}")
        exit(1)

    # Import data into PostgreSQL
    import_to_postgres(MDB_FILE, tables)