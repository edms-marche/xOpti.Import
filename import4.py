from dotenv import load_dotenv
import os
import subprocess
import psycopg2
from io import StringIO
import logging
from time import time
import tempfile
import re
from re import sub
from tqdm import tqdm

# Load environment variables from .env file
load_dotenv()

# Get configuration from environment variables
MDB_FILE = os.getenv("MDB_FILE")
PG_HOST = os.getenv("PG_HOST")
PG_PORT = int(os.getenv("PG_PORT", 5432))
PG_DB = os.getenv("PG_DB")
PG_USER = os.getenv("PG_USER")
PG_PASSWORD = os.getenv("PG_PASSWORD")
LOG_FILE = os.getenv("LOG_FILE", "import_log.csv")

# Validate environment variables
def validate_env_vars():
    required_vars = ["MDB_FILE", "PG_HOST", "PG_PORT", "PG_DB", "PG_USER", "PG_PASSWORD"]
    for var in required_vars:
        if not os.getenv(var):
            raise ValueError(f"Environment variable {var} is not set.")

validate_env_vars()

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s|%(levelname)s|%(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger()

def snake_case(s):
    """Convert a string to snake_case."""
    return '_'.join(
        sub('([A-Z][a-z]+)', r' \1',
        sub('([A-Z]+)', r' \1',
        s.replace('-', ' '))).split()).lower() \
        .replace('rigth', 'right') \
        .replace('dateof', 'date_of') \
        .replace('leve_l', 'level') \
        .replace('retailmark_down', 'retail_markdown') \
        .replace('retail_mark_down', 'retail_markdown') \
        .replace('paltform', 'platform') \

def run_subprocess(command):
    """Run a subprocess command and return the output."""
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        logger.error(f"Subprocess failed|command={' '.join(command)}|error={e.stderr}")
        raise

def get_mdb_tables(mdb_file):
    """Fetch table names from the MDB file."""
    return run_subprocess(["mdb-tables", "-1", mdb_file]).split("\n")

def get_table_row_counts(mdb_file):
    """Fetch row counts for each table in the MDB file."""
    output = run_subprocess(["mdb-tables", "-r", mdb_file])
    row_counts = {}
    for line in output.split("\n"):
        parts = line.split()
        if len(parts) == 2:
            table_name, count_str = parts
            row_counts[table_name] = int(count_str)
    return row_counts

def get_column_names(mdb_file, table):
    """Fetch column names for a specific table."""
    output = run_subprocess(["mdb-describe", mdb_file, table])
    return [line.split()[0] for line in output.split("\n")]

# This function is expected to replace column names in a CREATE TABLE statement
# with their snake_case equivalents or mapped names.
def replace_column_names_in_create_table(statement, table, column_mappings):
    """Replace column names in a CREATE TABLE statement."""
    match = re.search(r'\(([^)]*)\)', statement)
    if match:
        columns_part = match.group(1)
        columns = columns_part.split(',')
        new_columns = []
        for col_def in columns:
            col_def = col_def.strip()
            col_name_match = re.match(r'"([^"]+)"', col_def)
            if col_name_match:
                col_name = col_name_match.group(1)
                new_col_name = column_mappings.get(col_name, snake_case(col_name))
                col_def = col_def.replace(f'"{col_name}"', f'"{new_col_name}"')
            new_columns.append(col_def)
        new_columns_part = ', '.join(new_columns)
        statement = statement.replace(columns_part, new_columns_part)
    return statement

# This function is expected to modify the header line of a CSV stream
# by replacing the original headers with new headers
# (e.g., snake_case or mapped names).
def modify_header_stream(stream, new_header_line):
    """Modify the header line of a CSV stream."""
    yield new_header_line  # Yield the new header line
    for line in stream:
        yield line.decode()  # Yield the remaining lines as-is

# This class is expected to wrap a generator and make it behave like a file object,
# # which is required for PostgreSQL's COPY command.
class GeneratorFile:
    """Wrap a generator to make it behave like a file object."""
    def __init__(self, generator):
        self.generator = generator
        self.iterator = iter(generator)

    def read(self, size=-1):
        try:
            return next(self.iterator)
        except StopIteration:
            return ''

    def readline(self):
        return self.read()

    def close(self):
        pass

def clean_and_convert_schema(schema, mdb_to_xopti, column_mappings):
    """Clean and adjust the schema for PostgreSQL compatibility."""
    statements = re.split(r'\s*;\s*', schema)
    cleaned_statements = []
    for stmt in statements:
        stmt = stmt.strip()
        if not stmt:
            continue
        # Replace table names
        for mdb_table, xopti_table in mdb_to_xopti.items():
            stmt = re.sub(r'"' + re.escape(mdb_table) + r'"', f'"{xopti_table}"', stmt)
        # Replace column names
        if stmt.lower().startswith('create table'):
            table_match = re.search(r'CREATE TABLE\s+"([^"]+)"', stmt, re.IGNORECASE)
            if table_match:
                table_name = table_match.group(1)
                stmt = replace_column_names_in_create_table(stmt, table_name, column_mappings[table_name])
            else:
                logger.warning(f"Could not find table name in CREATE TABLE statement: {stmt}")  
        cleaned_statements.append(stmt)
    return ';'.join(cleaned_statements) + ';'

def import_data_with_header_conversion(cursor, mdb_file, table, xopti_table, column_mappings):
    """Import data with header conversion."""
    process = subprocess.Popen(["mdb-export", "-b", "strip", "-H", mdb_file, table], stdout=subprocess.PIPE, bufsize=1)
    try:
        header_line = process.stdout.readline().decode().strip()
        headers = header_line.split(',')
        new_headers = [column_mappings.get(header.strip(), snake_case(header.strip())) for header in headers]
        new_header_line = ','.join(new_headers) + '\n'
        generator = modify_header_stream(process.stdout, new_header_line)
        file_like = GeneratorFile(generator)
        cursor.copy_expert(f"COPY \"{xopti_table}\" FROM STDIN WITH (FORMAT csv, HEADER true)", file_like)
    except Exception as e:
        process.kill()
        raise e
    finally:
        process.wait()
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, process.args)

def import_to_postgres(tables):
    """Import data from MDB to PostgreSQL."""
    with psycopg2.connect(
        host=PG_HOST,
        port=PG_PORT,
        database=PG_DB,
        user=PG_USER,
        password=PG_PASSWORD
    ) as conn:
        with conn.cursor() as cursor:
            row_counts = get_table_row_counts(MDB_FILE)
            mdb_to_xopti = {table: snake_case(table) for table in tables}
            column_mappings = {table: {col: snake_case(col) for col in get_column_names(MDB_FILE, table)} for table in tables}

            # Step 1: Clear existing tables
            for table in tables:
                xopti_table = mdb_to_xopti[table]
                cursor.execute(f"DROP TABLE IF EXISTS \"{xopti_table}\" CASCADE;")
                logger.info(f"Cleared table|table={xopti_table}")

            # Step 2: Generate and clean schema
            schema = run_subprocess(["mdb-schema", MDB_FILE, "postgres"])
            cleaned_schema = clean_and_convert_schema(schema, mdb_to_xopti, column_mappings)
            cursor.execute(cleaned_schema)
            conn.commit()
            logger.info("Recreated table structures|xOpti")

            # Step 3: Import data
            for table in tqdm(tables, desc="Importing tables", postfix={"current": ""}):
                tqdm.set_postfix({"current": table})
                xopti_table = mdb_to_xopti[table]
                logger.info(f"Starting import|table={xopti_table}")
                start_time = time()
                try:
                    import_data_with_header_conversion(cursor, MDB_FILE, table, xopti_table, column_mappings[table])
                except Exception as e:
                    logger.error(f"Error importing table {table}: {str(e)}")
                    continue
                elapsed_time = time() - start_time
                row_count = row_counts.get(table, 0)
                logger.info(f"Imported data|table={xopti_table}|rows={row_count}|time={elapsed_time:.2f}")
                conn.commit()

def main():
    if not os.path.exists(MDB_FILE):
        logger.error(f"MDB file not found|path={MDB_FILE}")
        return

    tables = get_mdb_tables(MDB_FILE)
    if not tables or tables == ['']:
        logger.error(f"No tables found|file={MDB_FILE}")
        return

    logger.info(f"Found tables|tables={','.join(tables)}")
    start_time = time()
    import_to_postgres(tables)
    total_time = time() - start_time
    logger.info(f"Import completed|total_time={total_time:.2f}")

if __name__ == "__main__":
    main()