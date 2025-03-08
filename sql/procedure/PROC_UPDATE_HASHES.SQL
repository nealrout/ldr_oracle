CREATE OR REPLACE PROCEDURE UPDATE_HASHES_LDR (
    p_tgt_table IN VARCHAR2,
    p_pre_ldr IN NUMBER
)
IS
    v_hash_columns VARCHAR2(32767);
    v_update_hash_sql VARCHAR2(32767);
    v_compare_sql VARCHAR2(32767);
    v_hash_column VARCHAR2(50);
    v_count NUMBER;
BEGIN
    -- Validate table existence
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = UPPER(p_tgt_table);
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: Target table ' || p_tgt_table || ' does not exist.');
        RETURN;
    END IF;

    -- Retrieve columns used for hashing dynamically
    v_hash_columns := '';
    FOR hash_rec IN (
        WITH json_data AS (
            SELECT CONFIG 
            FROM LOAD_CONFIG
            WHERE STEP_CODE = 'LDR'
            AND UPPER(TGT_TABLE) = UPPER(p_tgt_table)
        ),
        cte_parsed_json AS (
            SELECT jt.hashColumn  
            FROM json_data j,
                 JSON_TABLE(j.CONFIG, '$.hashColumns[*]' 
                 COLUMNS (hashColumn VARCHAR2(100) PATH '$')
                 ) jt
        )
        SELECT DISTINCT hashColumn FROM cte_parsed_json
    ) LOOP
        v_hash_columns := v_hash_columns || 'NVL("' || hash_rec.hashColumn || '", '''') || ';
    END LOOP;

    -- Remove last concatenation operator
    v_hash_columns := RTRIM(v_hash_columns, ' || ');

    -- Determine which hash column to update
    IF p_pre_ldr = 1 THEN
        v_hash_column := 'PREVIOUS_HASH';
    ELSE
        v_hash_column := 'NEW_HASH';
    END IF;

    -- Step 1: Update the relevant hash column (PREVIOUS_HASH or NEW_HASH)
    v_update_hash_sql := 'UPDATE ' || p_tgt_table || ' ' ||
                         'SET ' || v_hash_column || ' = STANDARD_HASH(' || v_hash_columns || ', ''SHA256'')';

    -- Execute the hash update
    DBMS_OUTPUT.PUT_LINE('Executing HASH Update: ' || v_update_hash_sql);
    EXECUTE IMMEDIATE v_update_hash_sql;

    -- Step 2: If updating NEW_HASH, compare with PREVIOUS_HASH and set IS_CHANGED
    IF p_pre_ldr = 0 THEN
        v_compare_sql := 'UPDATE ' || p_tgt_table || ' ' ||
                         'SET IS_CHANGED = CASE ' ||
                         'WHEN PREVIOUS_HASH IS NULL OR PREVIOUS_HASH <> NEW_HASH THEN 1 ELSE IS_CHANGED END';

        DBMS_OUTPUT.PUT_LINE('Executing Hash Comparison: ' || v_compare_sql);
        EXECUTE IMMEDIATE v_compare_sql;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Hash update completed successfully for ' || p_tgt_table);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred in UPDATE_HASHES_LDR: ' || SQLERRM);
        RAISE_APPLICATION_ERROR(-20002, 'An error occurred in UPDATE_HASHES_LDR: ' || SQLERRM);
END UPDATE_HASHES_LDR;
