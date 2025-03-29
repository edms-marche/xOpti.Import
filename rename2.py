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
        .replace('paltform', 'platform') \
        .replace('re_build', 'rebuild')

# Initialize variables
conn = None
cursor = None
db_host = "10.0.1.19"
db_port = 5436
db_name = "xOpti"
db_user = "marche"
db_pwd = "mc@24949981"      # Replace with your actual password
output_filename = "rename"

try:
    # Connect to xOpti
    conn = psycopg2.connect(
        host=db_host,
        port=db_port,
        database=db_name,
        user=db_user,
        password=db_pwd
    )
    cursor = conn.cursor()

    # Get all tables and views with their columns and types
    cursor.execute("""
        SELECT c.table_name, c.column_name, t.table_type
        FROM information_schema.columns c
        JOIN information_schema.tables t ON c.table_name = t.table_name AND c.table_schema = t.table_schema
        WHERE c.table_schema = 'public'
        AND t.table_type IN ('BASE TABLE', 'VIEW');
    """)
    relation_column_data = cursor.fetchall()

    # Get all indexes with their table names
    cursor.execute("""
        SELECT indexname, tablename
        FROM pg_indexes
        WHERE schemaname = 'public';
    """)
    index_data = cursor.fetchall()

    # Process relation and column data
    relations = {}
    for relation_name, column_name, relation_type in relation_column_data:
        if relation_name not in relations:
            relations[relation_name] = {'type': relation_type, 'columns': []}
        relations[relation_name]['columns'].append(column_name)

    rename_commands = []

    # Process each relation and its columns
    for relation_name, info in relations.items():
        old_relation_name = relation_name
        new_relation_name = snake_case(old_relation_name)
        relation_type = info['type']

        # Rename the relation if necessary
        if old_relation_name != new_relation_name:
            if relation_type == 'BASE TABLE':
                rename_commands.append(f'ALTER TABLE "{old_relation_name}" RENAME TO "{new_relation_name}";')
            elif relation_type == 'VIEW':
                rename_commands.append(f'ALTER VIEW "{old_relation_name}" RENAME TO "{new_relation_name}";')

        # Rename columns if necessary
        for old_column_name in info['columns']:
            new_column_name = snake_case(old_column_name)
            if old_column_name != new_column_name:
                if relation_type == 'BASE TABLE':
                    rename_commands.append(f'ALTER TABLE "{new_relation_name}" RENAME COLUMN "{old_column_name}" TO "{new_column_name}";')
                elif relation_type == 'VIEW':
                    rename_commands.append(f'ALTER VIEW "{new_relation_name}" RENAME COLUMN "{old_column_name}" TO "{new_column_name}";')

    # Process each index
    for old_index_name, table_name in index_data:
        new_index_name = snake_case(old_index_name)
        if old_index_name != new_index_name:
            rename_commands.append(f'ALTER INDEX "{old_index_name}" RENAME TO "{new_index_name}";')

    # Sort the rename commands: tables, then indexes, then views; relation renames before column renames
    def sort_key(cmd):
        # Extract the command type and relation name
        if 'ALTER TABLE' in cmd:
            type_priority = 0  # Tables first
        elif 'ALTER INDEX' in cmd:
            type_priority = 1  # Indexes second
        elif 'ALTER VIEW' in cmd:
            type_priority = 2  # Views third
        else:
            type_priority = 3  # Fallback

        # Determine if it's a relation rename or column rename
        if 'RENAME COLUMN' in cmd:
            command_priority = 1  # Column renames second
            relation_name = cmd.split('"')[1].lower()  # New name for column renames
        else:
            command_priority = 0  # Relation/index renames first
            relation_name = cmd.split('"')[1].lower()  # Old name for relation/index renames

        return (type_priority, command_priority, relation_name)

    rename_commands = sorted(rename_commands, key=sort_key)

    # Write commands to a SQL file with a header
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{output_filename}_{timestamp}.sql"
    with open(filename, "w") as f:
        f.write("-- This script renames tables, indexes, views, and their columns to snake_case.\n")
        f.write("-- Note: Renaming views may affect dependent views or other objects.\n")
        f.write("-- You may need to recreate or update dependent views after execution.\n\n")
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