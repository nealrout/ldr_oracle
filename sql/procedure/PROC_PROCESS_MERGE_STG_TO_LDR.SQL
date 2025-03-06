CREATE OR REPLACE PROCEDURE PROCESS_MERGE_STG_TO_LDR (
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_src_table IN VARCHAR2,
    p_tgt_table IN VARCHAR2
)
IS
    v_column_list VARCHAR2(32767);
    v_merge_sql VARCHAR2(32767);
    v_update_columns VARCHAR2(32767);
    v_insert_columns VARCHAR2(32767);
    v_insert_values VARCHAR2(32767);
    v_count NUMBER;
BEGIN
    -- Check if source table exists
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = UPPER(p_src_table);
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: Source table ' || p_src_table || ' does not exist.');
        RETURN;
    END IF;

    -- Check if target table exists
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = UPPER(p_tgt_table);
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: Target table ' || p_tgt_table || ' does not exist.');
        RETURN;
    END IF;

    -- Initialize column lists
    v_update_columns := '';
    v_insert_columns := 'LOAD_LOG_ID, UNIQUE_IDENTIFIER, CREATE_TS, ';
    v_insert_values := 'source.LOAD_LOG_ID, source.UNIQUE_IDENTIFIER, source.CREATE_TS, ';

    -- Loop through columns dynamically
    FOR col_rec IN (
        SELECT column_name
        FROM user_tab_columns
        WHERE table_name = UPPER(p_src_table)
        AND column_name NOT IN ('LOAD_LOG_ID', 'UNIQUE_IDENTIFIER', 'CREATE_TS')  -- Exclude primary keys
        ORDER BY column_id
    ) LOOP
        -- Check if the column has at least one non-null value
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || p_src_table || ' WHERE "' || col_rec.column_name || '" IS NOT NULL AND LOAD_LOG_ID = :log_id'
        INTO v_count USING p_load_log_id;

        -- If the column has at least one non-null value, include it in the merge
        IF v_count > 0 THEN
            v_update_columns := v_update_columns || 'target."' || col_rec.column_name || '" = source."' || col_rec.column_name || '", ';
            v_insert_columns := v_insert_columns || '"' || col_rec.column_name || '", ';
            v_insert_values := v_insert_values || 'source."' || col_rec.column_name || '", ';
        END IF;
    END LOOP;

    -- Remove trailing commas
    v_update_columns := RTRIM(v_update_columns, ', ');
    v_insert_columns := RTRIM(v_insert_columns, ', ');
    v_insert_values := RTRIM(v_insert_values, ', ');

    -- Build MERGE SQL statement
    v_merge_sql := 'MERGE INTO ' || p_tgt_table || ' target USING ' || p_src_table || ' source ' ||
                   'ON (target.UNIQUE_IDENTIFIER = source.UNIQUE_IDENTIFIER) ';

    -- Add UPDATE clause if there are columns to update
    IF v_update_columns IS NOT NULL THEN
        v_merge_sql := v_merge_sql || 'WHEN MATCHED THEN UPDATE SET ' || v_update_columns || ' ';
    END IF;

    -- Add INSERT clause
    v_merge_sql := v_merge_sql || 'WHEN NOT MATCHED THEN INSERT (' || v_insert_columns || ') VALUES (' || v_insert_values || ')';

    -- Add WHERE condition to filter by LOAD_LOG_ID
    v_merge_sql := v_merge_sql || ' WHERE source.LOAD_LOG_ID = ' || p_load_log_id;

    -- Hash PREVIOUS_HASH in LDR table.
    DBMS_OUTPUT.PUT_LINE('Hashing PREVIOUS_HASH in LDR table');
    UPDATE_HASHES_LDR (p_tgt_table =>p_tgt_table, p_pre_ldr => 1);

    DBMS_OUTPUT.PUT_LINE('SQL: ' || v_merge_sql);

    UPDATE LOAD_LOG_DETAIL SET SQL = v_merge_sql WHERE ID = p_load_log_detail_id;

    -- Execute the MERGE statement
    EXECUTE IMMEDIATE v_merge_sql;

    -- Hash NEW_HASH in LDR table, and update IS_CHANGED flag
    DBMS_OUTPUT.PUT_LINE('Hashing NEW_HASH in LDR table and updating IS_CHANGED flag');
    UPDATE_HASHES_LDR (p_tgt_table =>p_tgt_table, p_pre_ldr => 0);

    DBMS_OUTPUT.PUT_LINE('Merge completed successfully for ' || p_src_table || ' -> ' || p_tgt_table);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END PROCESS_MERGE_STG_TO_LDR;