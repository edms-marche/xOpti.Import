To modify your script so that it empties the existing tables in the PostgreSQL database before importing new data from the MDB file, without dropping and recreating the tables (thus preserving the schema in xOpti), you need to adjust the `import_to_postgres` function. The current script drops tables using `DROP TABLE IF EXISTS` and recreates them, but you want to simply remove all data from the existing tables while keeping their structure, constraints, indexes, and other database objects intact. Here's how you can do it:

### Key Changes
1. **Replace Table Dropping with Truncation**: Instead of using `DROP TABLE IF EXISTS`, use `TRUNCATE TABLE` to remove all rows from the existing tables while preserving their schema.
2. **Handle Foreign Key Constraints**: Since tables might have foreign key relationships, use the `CASCADE` option with `TRUNCATE` to ensure that dependent tables are also truncated as needed.
3. **Remove Schema Recreation**: Since you're not dropping tables, skip the schema generation and execution steps (e.g., `mdb-schema` and `clean_and_convert_schema`), as the existing table structures in PostgreSQL will be reused.
4. **Preserve Data Import Logic**: Keep the data import process intact, ensuring that column names align with the existing snake_case names in the PostgreSQL tables.

### Assumptions
- The tables in the PostgreSQL database (xOpti) already exist with the correct schema, including snake_case table and column names that match the MDB file's structure after conversion.
- The schema hasn’t changed between imports (e.g., no new columns or data type changes in the MDB file), as this approach assumes the existing table structures are compatible with the incoming data.

### Modified Code
Below is the updated `import_to_postgres` function that empties the tables before importing data:

```python
def import_to_postgres(tables):
    with psycopg2.connect(
        host=PG_HOST,
        port=PG_PORT,
        database=PG_DB,
        user=PG_USER,
        password=PG_PASSWORD
    ) as conn:
        with conn.cursor() as cursor:
            # Get row counts and mappings
            row_counts = get_table_row_counts(MDB_FILE)
            mdb_to_xopti = {table: snake_case(table) for table in tables}
            column_mappings = {table: {col: snake_case(col) for col in get_column_names(MDB_FILE, table)} for table in tables}

            # Empty existing tables
            for table in tables:
                xopti_table = mdb_to_xopti[table]
                cursor.execute(f"TRUNCATE TABLE \"{xopti_table}\" CASCADE;")
                logger.info(f"Truncated table|table={xopti_table}")

            # Import new data
            for table in tqdm(tables, desc="Importing tables"):
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
```

### Explanation of Changes
- **Truncate Tables**:
  - The line `cursor.execute(f"TRUNCATE TABLE \"{xopti_table}\" CASCADE;")` replaces `DROP TABLE IF EXISTS`. The `CASCADE` option ensures that any foreign key constraints are handled by also truncating dependent tables if necessary. Since you're truncating all tables involved in the import, this approach safely clears all data.
  - The log message is updated from "Cleared table" to "Truncated table" for clarity.

- **Remove Schema Generation**:
  - The original code used `mdb-schema` to generate a schema and `clean_and_convert_schema` to prepare it for execution. Since you’re keeping the existing tables, these steps are removed.

- **Data Import**:
  - The import logic remains unchanged. The `import_data_with_header_conversion` function uses `column_mappings` to adjust the CSV headers to snake_case, which should match the existing column names in the PostgreSQL tables.

- **Transaction Management**:
  - In PostgreSQL, `TRUNCATE` is a DDL statement that auto-commits, so each table truncation is immediately committed. The subsequent data import is committed explicitly with `conn.commit()` after each table import, consistent with the original script.

### Why This Works
- **Preserves Schema**: `TRUNCATE TABLE` only removes data, leaving the table structure, constraints, indexes, and triggers intact, meeting your requirement to not modify xOpti’s schema.
- **Efficiency**: Truncating is faster than deleting rows (e.g., `DELETE FROM`) for large tables, and it resets auto-incrementing sequences, which is typically desired when re-importing data.
- **Handles Dependencies**: The `CASCADE` option ensures that foreign key constraints don’t prevent truncation, making the process robust even if tables are interrelated.

### Considerations
- **Table Existence**: If a table from the MDB file doesn’t exist in PostgreSQL, `TRUNCATE TABLE` will raise an error. The current code assumes all tables already exist. If this isn’t guaranteed, you could add a check (e.g., query `information_schema.tables`) and skip or handle missing tables, but this adds complexity beyond your stated goal.
- **Schema Mismatch**: If the MDB file’s schema has changed (e.g., new columns), the import might fail due to column mismatches. You’d need to alter the tables separately in that case, but you’ve indicated you just want to empty and import, so this is out of scope.
- **Other Tables**: This code only truncates tables corresponding to those in the MDB file (via `mdb_to_xopti`), leaving any unrelated tables in the database untouched.

### Final Notes
This modification achieves your goal of emptying the tables before importing new data without altering the existing schema in xOpti. Test the updated script with your specific MDB file and database to ensure the column mappings align and the import succeeds as expected. If you encounter issues like missing tables or schema mismatches, let me know, and we can refine the solution further!