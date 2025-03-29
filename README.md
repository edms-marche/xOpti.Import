Below is a Python script designed to run in a Linux environment that imports data from your Microsoft Access MDB file (**SynergyV**) into your PostgreSQL database (**xOpti**), clearing existing records first and using the PostgreSQL **COPY** command for efficient data transfer. Since you’ve already used the "Access to PostgreSQL" tool from BullZip to perform an initial conversion, this script assumes you have the necessary tools (**mdbtools**) installed to extract data from the MDB file and a working PostgreSQL setup.

The script leverages **mdbtools** to export the MDB tables to CSV format, then uses PostgreSQL's **COPY** command via the **psycopg2** library for fast data loading. It clears the existing tables in **xOpti** before importing to ensure the database matches **SynergyV**. For performance with large datasets, **COPY** is one of the fastest methods available in PostgreSQL, though I’ll also discuss alternatives at the end.

### Prerequisites

1. **Linux Environment** : Ensure you’re running this on a Linux system.
2. **mdbtools** : Install via **sudo apt install mdbtools** (for Ubuntu/Debian) to handle MDB file extraction.
3. **Python Libraries** : Install **psycopg2** with **pip install psycopg2-binary**.
4. **PostgreSQL Access** : Ensure you have the credentials (host, database name, user, password) for **xOpti**.
5. **File Paths** : Update the script with the correct paths to **SynergyV.mdb** and your PostgreSQL connection details.

### Enhancement

Below is an updated version of the Python script that enhances logging with row counts for each table and uses a delimited format (CSV-like) for easy import into a spreadsheet. The script now logs key events with pipe (`|`) as the delimiter, including the number of rows imported per table, and writes this data to a structured log file (`import_log.csv`). Console output remains human-readable for real-time monitoring, while the file output is optimized for spreadsheet analysis.

### Updated Python Script

```python
#!/usr/bin/env python3
import subprocess
import os
import psycopg2
from io import StringIO
import logging
from time import time

# Configuration
MDB_FILE = "/path/to/SynergyV.mdb"  # Update with the actual path to SynergyV.mdb
PG_HOST = "localhost"              # PostgreSQL host
PG_DB = "xOpti"                    # PostgreSQL database name
PG_USER = "your_username"          # PostgreSQL username
PG_PASSWORD = "your_password"      # PostgreSQL password
LOG_FILE = "import_log.csv"        # Log file name (CSV format)

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s|%(levelname)s|%(message)s",  # Pipe-delimited for CSV
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()  # Console output remains readable
    ]
)
logger = logging.getLogger()

# Custom formatter for console (human-readable)
console_handler = logger.handlers[1]  # StreamHandler is the second handler
console_handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))

# Function to get list of tables from MDB file
def get_mdb_tables(mdb_file):
    result = subprocess.run(["mdb-tables", "-1", mdb_file], capture_output=True, text=True, check=True)
    return result.stdout.strip().split("\n")

# Function to export MDB table to CSV and count rows
def export_table_to_csv(mdb_file, table_name):
    result = subprocess.run(
        ["mdb-export", "-b", "strip", "-H", mdb_file, table_name],
        capture_output=True,
        text=True,
        check=True
    )
    csv_data = result.stdout
    row_count = len(csv_data.strip().split("\n")) - 1 if csv_data.strip() else 0  # Subtract 1 for header
    return csv_data, row_count

# Function to clear and import data into PostgreSQL
def import_to_postgres(tables):
    # Connect to PostgreSQL
    conn = psycopg2.connect(
        host=PG_HOST,
        database=PG_DB,
        user=PG_USER,
        password=PG_PASSWORD
    )
    cursor = conn.cursor()

    try:
        # Step 1: Clear existing tables
        for table in tables:
            cursor.execute(f"DROP TABLE IF EXISTS \"{table}\" CASCADE;")
            logger.info(f"Cleared table|{table}")

        # Step 2: Recreate table structures using mdb-schema
        start_time = time()
        schema = subprocess.run(
            ["mdb-schema", MDB_FILE, "postgres"],
            capture_output=True,
            text=True,
            check=True
        )
        cursor.execute(schema.stdout)
        conn.commit()
        elapsed_time = time() - start_time
        logger.info(f"Recreated table structures|xOpti|{elapsed_time:.2f}")

        # Step 3: Import data using COPY with timing and row counts
        for table in tables:
            logger.info(f"Starting import|table={table}")
            start_time = time()

            csv_data, row_count = export_table_to_csv(MDB_FILE, table)
            if not csv_data.strip():  # Skip empty tables
                logger.info(f"Skipping empty table|table={table}|rows=0")
                continue

            # Use StringIO to pass CSV data to COPY
            csv_buffer = StringIO(csv_data)
            cursor.copy_expert(
                f"COPY \"{table}\" FROM STDIN WITH (FORMAT csv, HEADER true)",
                csv_buffer
            )
            conn.commit()

            elapsed_time = time() - start_time
            logger.info(f"Imported data|table={table}|rows={row_count}|time={elapsed_time:.2f}")

    except Exception as e:
        logger.error(f"Error occurred|details={str(e)}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

def main():
    # Write CSV header to log file
    with open(LOG_FILE, "w") as f:
        f.write("timestamp|level|message|details\n")

    # Verify mdbtools is installed
    if subprocess.call(["which", "mdb-tools"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) != 0:
        logger.error("mdbtools not installed|Install with 'sudo apt install mdbtools'")
        return

    # Check if MDB file exists
    if not os.path.isfile(MDB_FILE):
        logger.error(f"MDB file not found|path={MDB_FILE}")
        return

    # Get list of tables
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
```

### Changes Made

1. **Logging Setup** :

* Added the **logging** module with a configuration that writes to both a file (**import_log.log**) and the console.
* Log levels used: **INFO** for general progress, **ERROR** for failures.

2. **Time Tracking** :

* Added **time()** calls to measure the duration of key steps:
  * Recreating the table structures.
  * Importing data for each table.
  * Total runtime of the entire process.
* Elapsed times are logged with two decimal places (e.g., **2.34 seconds**) for readability.

3. **Log Messages** :

* Replaced **print()** statements with **logger.info()** or **logger.error()** for consistency.
* Added specific messages to track the start and completion of each table’s import, including the time taken.

4. **Delimited Log Format**:
   - The log file uses a pipe (`|`) delimiter and a CSV-like structure with columns: `timestamp|level|message|details`.
   - The `details` column includes additional key-value pairs (e.g., `table=Table1|rows=100|time=0.29`) for structured data.
   - Console output retains a human-readable format using a custom formatter.
5. **Row Counts**:
   - Modified `export_table_to_csv()` to return both the CSV data and the row count (calculated by counting lines in the CSV output, minus the header).
   - Added row counts to the log for each imported table (e.g., `rows=100`).
6. **Log File Initialization**:
   - Added a header row to `import_log.csv` at the start of the script for spreadsheet compatibility.
7. **Enhanced Log Messages**:
   - Structured messages like `Imported data|table=Table1|rows=100|time=0.29` for easy parsing.
   - Kept console output readable while ensuring the log file is machine-friendly.

### Example Log Output (`import_log.csv`)

```
timestamp|level|message|details
2025-03-24 10:00:00,123|INFO|Found tables|tables=Table1,Table2,Table3
2025-03-24 10:00:00,150|INFO|Cleared table|table=Table1
2025-03-24 10:00:00,160|INFO|Cleared table|table=Table2
2025-03-24 10:00:00,170|INFO|Cleared table|table=Table3
2025-03-24 10:00:00,200|INFO|Recreated table structures|xOpti|time=0.03
2025-03-24 10:00:00,210|INFO|Starting import|table=Table1
2025-03-24 10:00:00,500|INFO|Imported data|table=Table1|rows=150|time=0.29
2025-03-24 10:00:00,510|INFO|Starting import|table=Table2
2025-03-24 10:00:01,000|INFO|Imported data|table=Table2|rows=2000|time=0.49
2025-03-24 10:00:01,010|INFO|Starting import|table=Table3
2025-03-24 10:00:01,200|INFO|Imported data|table=Table3|rows=50|time=0.19
2025-03-24 10:00:01,210|INFO|Import completed|total_time=1.09
```

### Console Output (Human-Readable)

```
2025-03-24 10:00:00,123 - INFO - Found tables: Table1,Table2,Table3
2025-03-24 10:00:00,150 - INFO - Cleared table: Table1
2025-03-24 10:00:00,160 - INFO - Cleared table: Table2
2025-03-24 10:00:00,170 - INFO - Cleared table: Table3
2025-03-24 10:00:00,200 - INFO - Recreated table structures: xOpti (time=0.03)
2025-03-24 10:00:00,210 - INFO - Starting import: table=Table1
2025-03-24 10:00:00,500 - INFO - Imported data: table=Table1|rows=150|time=0.29
2025-03-24 10:00:00,510 - INFO - Starting import: table=Table2
2025-03-24 10:00:01,000 - INFO - Imported data: table=Table2|rows=2000|time=0.49
2025-03-24 10:00:01,010 - INFO - Starting import: table=Table3
2025-03-24 10:00:01,200 - INFO - Imported data: table=Table3|rows=50|time=0.19
2025-03-24 10:00:01,210 - INFO - Import completed: total_time=1.09
```

### Usage

1. Save the script as `import_mdb_to_postgres.py`.
2. Update the configuration section (`MDB_FILE`, `PG_HOST`, `PG_DB`, `PG_USER`, `PG_PASSWORD`) with your values.
3. Optionally, change `LOG_FILE` to a different path or name (keep the `.csv` extension for spreadsheet compatibility).
4. Make it executable: `chmod +x import_mdb_to_postgres.py`.
5. Run it: `./import_mdb_to_postgres.py`.

### Spreadsheet Analysis

- Open `import_log.csv` in a spreadsheet tool (e.g., Excel, LibreOffice Calc, Google Sheets).
- Use the `|` delimiter to split columns.
- Filter or sort by `message` (e.g., "Imported data") and analyze `details` for `table`, `rows`, and `time` to identify performance bottlenecks or data volume trends.

This setup provides a robust way to track both timing and row counts, making it easy to analyze the import process. Let me know if you need further adjustments!
