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
