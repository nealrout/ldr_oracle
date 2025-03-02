DECLARE
    v_count NUMBER;
    v_table_name VARCHAR2(30);
    v_sql VARCHAR2(32767);
BEGIN
    FOR i IN 1..10 LOOP
        -- Generate table name dynamically (STG_TRANSFORM_01 to STG_TRANSFORM_10)
        v_table_name := 'STG_TRANSFORM_' || LPAD(i, 2, '0');

        -- Check if the table already exists
        SELECT COUNT(*) INTO v_count FROM all_tables WHERE table_name = UPPER(v_table_name) AND owner = 'DAAS';

        -- Drop table if it exists
        IF v_count > 0 THEN
            EXECUTE IMMEDIATE 'DROP TABLE ' || v_table_name || ' CASCADE CONSTRAINTS PURGE';
        END IF;

        -- Start building the CREATE TABLE statement
        v_sql := 'CREATE TABLE ' || v_table_name || ' (
                    LOAD_LOG_ID NUMBER NOT NULL,
                    CREATE_TS TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, ';

        -- Generate 50 CLOB fields dynamically
        FOR j IN 1..50 LOOP
            v_sql := v_sql || 'FIELD_' || LPAD(j, 3, '0') || ' CLOB, ';
        END LOOP;

        -- Remove the trailing comma and close the statement
        v_sql := RTRIM(v_sql, ', ') || ')';

        -- Execute the CREATE TABLE statement
        EXECUTE IMMEDIATE v_sql;

        -- Print confirmation
        DBMS_OUTPUT.PUT_LINE('Created Table: ' || v_table_name);
    END LOOP;
END;
/
