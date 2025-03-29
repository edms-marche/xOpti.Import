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

# Load environment variables from .env file
load_dotenv()

# Get configuration from environment variables
MDB_FILE = os.getenv("MDB_FILE")
PG_HOST = os.getenv("PG_HOST")
PG_PORT = int(os.getenv("PG_PORT"))
PG_DB = os.getenv("PG_DB")
PG_USER = os.getenv("PG_USER")
PG_PASSWORD = os.getenv("PG_PASSWORD")
LOG_FILE = os.getenv("LOG_FILE", "import_log.csv")

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

# Custom formatter for console
console_handler = logger.handlers[1]
console_handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))

def snake_case(s):
    return '_'.join(
        sub('([A-Z][a-z]+)', r' \1',
        sub('([A-Z]+)', r' \1',
        s.replace('-', ' '))).split()).lower()

def get_mdb_tables(mdb_file):
    result = subprocess.run(["mdb-tables", "-1", mdb_file], capture_output=True, text=True, check=True)
    return result.stdout.strip().split("\n")

def get_table_row_counts(mdb_file):
    result = subprocess.run(["mdb-tables", "-r", mdb_file], capture_output=True, text=True, check=True)
    lines = result.stdout.strip().split("\n")
    row_counts = {}
    for line in lines:
        parts = line.split()
        if len(parts) == 2:
            table_name, count_str = parts
            row_counts[table_name] = int(count_str)
    return row_counts

def get_column_names(mdb_file, table):
    result = subprocess.run(["mdb-describe", mdb_file, table], capture_output=True, text=True, check=True)
    lines = result.stdout.strip().split("\n")
    columns = [line.split()[0] for line in lines]
    return columns

def guess_primary_key_column(table, column_names):
    for col in column_names:
        if col.lower() in ['id', 'code', 'pk', 'primarykey'] or 'id' in col.lower():
            return col
    return column_names[0] if column_names else None

def replace_table_names(schema, mdb_to_xopti):
    for mdb_table, xopti_table in mdb_to_xopti.items():
        schema = re.sub(r'"' + re.escape(mdb_table) + r'"', f'"{xopti_table}"', schema)
    return schema

def replace_column_names_in_create_table(statement, table, column_mappings):
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
                if col_name in column_mappings[table]:
                    new_col_name = f'"{column_mappings[table][col_name]}"'
                    col_def = re.sub(r'"' + re.escape(col_name) + r'"', new_col_name, col_def)
            new_columns.append(col_def)
        new_columns_part = ', '.join(new_columns)
        statement = statement.replace(match.group(0), f'({new_columns_part})')
    return statement

def replace_column_names_in_create_index(statement, table, column_mappings):
    pattern = r'ON\s+"' + re.escape(table) + r'"\(\s*([^)]*)\s*\)'
    match = re.search(pattern, statement, re.IGNORECASE)
    if match:
        columns_part = match.group(1)
        columns = columns_part.split(',')
        new_columns = []
        for col in columns:
            col = col.strip()
            if col in column_mappings[table]:
                new_col = f'"{column_mappings[table][col]}"'
                col = new_col
            new_columns.append(col)
        new_columns_part = ', '.join(new_columns)
        statement = re.sub(pattern, r'ON "{table}" (' + new_columns_part + ')', statement, flags=re.IGNORECASE)
    return statement

def fix_empty_primary_key(statement, table, column_mappings):
    match = re.match(r'alter\s+table\s+"([^"]+)"\s+add\s+constraint\s+"([^"]+)"\s+primary\s+key\s+\(\s*\);', statement, re.IGNORECASE)
    if match:
        table_name = match.group(1)
        constraint_name = match.group(2)
        # Guess the primary key column
        cols = get_column_names(MDB_FILE, table_name)
        pk_col = guess_primary_key_column(table_name, cols)
        if pk_col:
            new_stmt = f'alter table "{table_name}" add constraint "{constraint_name}" primary key ("{pk_col}");'
            return new_stmt
    return statement

def clean_and_convert_schema(schema, mdb_to_xopti, column_mappings):
    cleaned_schema = []
    statements = re.split(r'\s*;\s*', schema)
    for stmt in statements:
        stmt = stmt.strip()
        if not stmt:
            continue
        # Replace table names
        for mdb_table, xopti_table in mdb_to_xopti.items():
            stmt = re.sub(r'"' + re.escape(mdb_table) + r'"', f'"{xopti_table}"', stmt)
        
        # Replace column names in CREATE TABLE statements
        if stmt.lower().startswith('create table'):
            table_match = re.search(r'CREATE TABLE\s+"([^"]+)"', stmt, re.IGNORECASE)
            if table_match:
                mdb_table_name = table_match.group(1)
                stmt = replace_column_names_in_create_table(stmt, mdb_table_name, column_mappings[mdb_table_name])
        
        # Replace column names in CREATE INDEX statements
        elif stmt.lower().startswith('create index'):
            table_match = re.search(r'ON\s+"([^"]+)"', stmt, re.IGNORECASE)
            if table_match:
                mdb_table_name = table_match.group(1)
                stmt = replace_column_names_in_create_index(stmt, mdb_table_name, column_mappings[mdb_table_name])
        
        # Fix empty PRIMARY KEY constraints
        for table in mdb_to_xopti:
            stmt = fix_empty_primary_key(stmt, table, column_mappings[table])
        
        cleaned_schema.append(stmt)
    return ';'.join(cleaned_schema) + ';'

def get_schema(mdb_file):
    result = subprocess.run(["mdb schema", mdb_file, "postgres"], capture_output=True, text=True, check=True)
    return result.stdout

def modify_header_stream(process_stdout, new_header_line):
    yield new_header_line.encode()
    while True:
        chunk = process_stdout.read(1024)
        if not chunk:
            break
        yield chunk

class GeneratorFile(object):
    def __init__(self, generator):
        self.generator = generator
        self._buffer = b''
    def read(self, size=-1):
        if size < 0:
            return b''.join(self.generator)
        else:
            while len(self._buffer) < size:
                try:
                    self._buffer += next(self.generator)
                except StopIteration:
                    break
            data = self._buffer[:size]
            self._buffer = self._buffer[size:]
            return data

def import_data_with_header_conversion(cursor, mdb_file, table, xopti_table, column_mappings):
    process = subprocess.Popen(["mdb-export", "-b", "strip", "-H", mdb_file, table], stdout=subprocess.PIPE, bufsize=1)
    try:
        header_line = process.stdout.readline().decode().strip()
        headers = header_line.split(',')
        # Get the original column names from MDB
        mdb_cols = get_column_names(mdb_file, table)
        # Map original headers to snake_case
        new_headers = []
        for header in headers:
            header = header.strip()
            # Find the corresponding MDB column name
            # Assuming that mdb-export outputs columns in the same order as mdb-describe
            idx = headers.index(header)
            if idx < len(mdb_cols):
                mdb_col = mdb_cols[idx]
                xopti_col = column_mappings[table].get(mdb_col)
                if xopti_col:
                    new_headers.append(xopti_col)
                else:
                    new_headers.append(snake_case(header))
            else:
                new_headers.append(snake_case(header))
        new_header_line = ','.join(new_headers) + '\n'
        
        generator = modify_header_stream(process.stdout, new_header_line)
        file_like = GeneratorFile(generator)
        cursor.copy_expert(f"copy \"{xopti_table}\" from stdin with (format csv, header true)", file_like)
    except Exception as e:
        process.kill()
        raise e
    finally:
        process.wait()
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, process.args)

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
        # Get row counts
        row_counts = get_table_row_counts(MDB_FILE)

        # Convert MDB table names to xOpti snake_case names
        mdb_to_xopti = {table: snake_case(table) for table in tables}

        # Get column names and their mappings
        column_names = {table: get_column_names(MDB_FILE, table) for table in tables}
        column_mappings = {}
        for table, cols in column_names.items():
            column_mappings[table] = {col: snake_case(col) for col in cols}

        # Step 1: Clear existing tables
        for table in tables:
            xopti_table = mdb_to_xopti[table]
            cursor.execute(f"drop table if exists \"{xopti_table}\" cascade;")
            logger.info(f"Cleared table|table={xopti_table}")

        # Step 2: Generate and clean schema
        schema = get_schema(MDB_FILE)
        cleaned_schema = clean_and_convert_schema(schema, mdb_to_xopti, column_mappings)
        cursor.execute(cleaned_schema)
        conn.commit()
        logger.info("Recreated table structures|xOpti")

        # Step 3: Import data
        for table in tables:
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

    except Exception as e:
        logger.error(f"Error occurred|details={str(e)}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

def main():
    with open(LOG_FILE, "w") as f:
        f.write("timestamp|level|message|details\n")

    if not os.path.exists(MDB_FILE):
        logger.error(f"MDB file not found|path={MDB_FILE}")
        return

    tables = get_mdb_tables(MDB_FILE)
    if not tables or tables == ['']:
        logger.error("No tables found|file={MDB_FILE}")
        return

    logger.info(f"Found tables|tables={','.join(tables)}")
    start_time = time()
    import_to_postgres(tables)
    total_time = time() - start_time
    logger.info(f"Import completed|total_time={total_time:.2f}")

if __name__ == "__main__":
    main()