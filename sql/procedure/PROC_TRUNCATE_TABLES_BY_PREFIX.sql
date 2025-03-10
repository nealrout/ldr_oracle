/*====================================================================================
    PROCEDURE:   TRUNCATE_TABLES_BY_PREFIX
    PURPOSE:     This procedure truncates all tables whose names start with a given
                 prefix. It dynamically finds matching table names and executes a 
                 TRUNCATE statement for each one.
                 
                 The procedure:
                 1. Validates that the provided table prefix is not NULL or empty.
                 2. Searches for tables in the current schema that match the prefix.
                 3. Iterates over the matching tables and truncates them.
                 4. Logs each truncation operation using DBMS_OUTPUT.

    PARAMETERS:
    --------------------------------------------------------------------------------
    | Parameter Name  | Type      | Description                                     |
    --------------------------------------------------------------------------------
    | p_table_prefix  | VARCHAR2  | Prefix of the tables to be truncated            |
    --------------------------------------------------------------------------------

    EXCEPTION HANDLING:
        - If the prefix is NULL or empty, the procedure exits without truncating any tables.
        - Logs error messages using DBMS_OUTPUT for debugging.
        - Ensures that only valid table names are processed to avoid errors.

    AUTHOR:       [NEAL ROUTSON]
    CREATED ON:   [2025-03-01]
    
    REVISION HISTORY:
    ---------------------------------------------------------------------------------
    | Date       | Author       | Description of Changes                            |
    ---------------------------------------------------------------------------------
    | 2025-03-08 | Neal Routson | Initial Version                                   |
    ---------------------------------------------------------------------------------
====================================================================================*/

CREATE OR REPLACE PROCEDURE TRUNCATE_TABLES_BY_PREFIX (
    p_table_prefix IN VARCHAR2
)
IS
    v_table_name VARCHAR2(200);
    v_sql        VARCHAR2(500);
BEGIN
    -- **Check if the prefix is NULL or empty** and exit if it is
    IF p_table_prefix IS NULL OR TRIM(p_table_prefix) = '' THEN
        DBMS_OUTPUT.PUT_LINE('Error: Table prefix cannot be NULL or empty. No tables truncated.');
        RETURN;
    END IF;

    -- Loop through all tables that start with the given prefix
    FOR rec IN (
        SELECT table_name 
        FROM user_tables 
        WHERE table_name LIKE UPPER(p_table_prefix) || '%'
    ) LOOP
        v_table_name := rec.table_name;
        v_sql := 'TRUNCATE TABLE ' || v_table_name;
        
        -- Print the SQL statement before execution (for debugging)
        DBMS_OUTPUT.PUT_LINE('Executing: ' || v_sql);
        
        -- Execute the truncate command
        EXECUTE IMMEDIATE v_sql;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('All tables starting with ' || p_table_prefix || ' have been truncated.');
END TRUNCATE_TABLES_BY_PREFIX;
