/*====================================================================================
    PROCEDURE:   UPDATE_HASHES_LDR
    PURPOSE:     This procedure updates hash values for a given target table in the 
                 loader (LDR) stage. It dynamically determines which columns to hash
                 and updates either the PREVIOUS_HASH or NEW_HASH column.
                 
                 The procedure:
                 1. Validates that the target table exists.
                 2. Extracts column names used for hashing from the LOAD_CONFIG table.
                 3. Computes SHA256 hash values for the selected columns.
                 4. Updates the appropriate hash column (PREVIOUS_HASH or NEW_HASH).
                 5. If updating NEW_HASH, compares it with PREVIOUS_HASH and sets IS_CHANGED.
                 6. Logs SQL executions using DBMS_OUTPUT.

    PARAMETERS:
    --------------------------------------------------------------------------------
    | Parameter Name  | Type      | Description                                     |
    --------------------------------------------------------------------------------
    | p_tgt_table     | VARCHAR2  | Name of the target table to update hashes for   |
    | p_pre_ldr       | NUMBER    | Flag (1 = Update PREVIOUS_HASH, 0 = Update NEW_HASH) |
    --------------------------------------------------------------------------------

    EXCEPTION HANDLING:
        - If the target table does not exist, logs an error and exits.
        - Captures errors and logs them with SQL error message and stack trace.
        - Uses RAISE_APPLICATION_ERROR to propagate errors for debugging.
        - Ensures that only valid columns are included in hashing to avoid execution errors.

    AUTHOR:       [NEAL ROUTSON]
    CREATED ON:   [2025-03-01]
    
    REVISION HISTORY:
    ---------------------------------------------------------------------------------
    | Date       | Author       | Description of Changes                            |
    ---------------------------------------------------------------------------------
    | 2025-03-08 | Neal Routson | Initial Version                                   |
    ---------------------------------------------------------------------------------
====================================================================================*/
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

    v_procedure_name VARCHAR2(100);
    v_error_message VARCHAR2(4000);
    v_error_stack   VARCHAR2(4000);
BEGIN
    v_procedure_name := REGEXP_SUBSTR(DBMS_UTILITY.FORMAT_CALL_STACK, 'procedure ([^ ]+)', 1, 1, NULL, 1);

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
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Hash update completed successfully for ' || p_tgt_table);
EXCEPTION
    WHEN OTHERS THEN
        v_error_message := SQLERRM;
        v_error_stack := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

        RAISE_APPLICATION_ERROR(-20002, 
            'An error occurred in ' || v_procedure_name || ': ' || v_error_message || ' | STACK: ' || v_error_stack
        );
END UPDATE_HASHES_LDR;
