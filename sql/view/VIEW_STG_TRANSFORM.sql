DECLARE
    v_mv_name VARCHAR2(30);
    v_sql VARCHAR2(32767);
BEGIN
    FOR i IN 1..10 LOOP
        -- Generate Materialized View name dynamically (MV_TRANSFORM_01 to MV_TRANSFORM_10)
        v_mv_name := 'MV_TRANSFORM_' || LPAD(i, 2, '0');

        -- Drop Materialized View if it exists
        BEGIN
            EXECUTE IMMEDIATE 'DROP MATERIALIZED VIEW ' || v_mv_name;
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- Ignore errors if the view does not exist
        END;

        -- Start building the CREATE MATERIALIZED VIEW statement
        v_sql := 'CREATE MATERIALIZED VIEW ' || v_mv_name || ' AS SELECT 
                    LOAD_LOG_ID, 
                    CREATE_TS, ';

        -- Generate 50 Virtual Columns dynamically using DBMS_LOB.SUBSTR
        FOR j IN 1..50 LOOP
            v_sql := v_sql || 'DBMS_LOB.SUBSTR(FIELD_' || LPAD(j, 3, '0') || ', 4000, 1) AS FIELD_' || LPAD(j, 3, '0') || ', ';
        END LOOP;

        -- Remove the trailing comma and complete the statement
        v_sql := RTRIM(v_sql, ', ') || ' FROM STG_TRANSFORM_' || LPAD(i, 2, '0');

        -- Execute the CREATE MATERIALIZED VIEW statement
        EXECUTE IMMEDIATE v_sql;

        -- Print confirmation
        DBMS_OUTPUT.PUT_LINE('Created Materialized View: ' || v_mv_name);
    END LOOP;
END;
/
