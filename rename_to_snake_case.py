import logging
import psycopg2
from re import sub
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def snake_case(s):
    return '_'.join(
        sub('([A-Z][a-z]+)', r' \1',
        sub('([A-Z]+)', r' \1',
        s.replace('-', ' '))).split()).lower() \
        .replace('rigth', 'right') \
        .replace('dateof', 'date_of') \
        .replace('leve_l', 'level') \
        .replace('retailmark_down', 'retail_markdown') \
        .replace('retail_mark_down', 'retail_markdown') \
        .replace('paltform', 'platform')

# Initialize variables
conn = None
cursor = None

try:
    # Connect to xOpti
    conn = psycopg2.connect(
        host="10.0.1.19",
        port=5436,
        database="xOpti",
        user="marche",
        password="mc@24949981"  # Replace with your actual password
    )
    cursor = conn.cursor()

    # Get all tables and columns
    cursor.execute("""
        SELECT table_name, column_name
        FROM information_schema.columns
        WHERE table_schema = 'public';
    """)
    table_column_data = cursor.fetchall()

    # Process table and column data
    table_columns = {}
    for table_name, column_name in table_column_data:
        if table_name not in table_columns:
            table_columns[table_name] = []
        table_columns[table_name].append(column_name)

    rename_commands = []

    # Process each table and its columns
    for table_name, columns in table_columns.items():
        old_table_name = table_name
        new_table_name = snake_case(old_table_name)
        if old_table_name != new_table_name:
            rename_commands.append(f'ALTER TABLE "{old_table_name}" RENAME TO "{new_table_name}";')

        for old_column_name in columns:
            new_column_name = snake_case(old_column_name)
            # Skip columns that are already in snake_case
            if old_column_name != new_column_name:
                rename_commands.append(f'ALTER TABLE "{new_table_name}" RENAME COLUMN "{old_column_name}" TO "{new_column_name}";')

    # Sort the rename commands by table name
    rename_commands = sorted(rename_commands, key=lambda cmd: cmd.split('"')[1].lower())

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"rename_to_snake_case_{timestamp}.sql"
    with open(filename, "w") as f:
        for cmd in rename_commands:
            f.write(cmd + "\n")

    dry_run = True  # Set to False to execute commands

    if dry_run:
        print("\n".join(rename_commands))
    else:
        for cmd in rename_commands:
            cursor.execute(cmd)
        conn.commit()

    logger.info(f"Renaming SQL commands generated in '{filename}'")

except psycopg2.Error as e:
    logger.error(f"Database error: {e}")
finally:
    # Safely close cursor and connection
    if cursor:
        cursor.close()
    if conn:
        conn.close()