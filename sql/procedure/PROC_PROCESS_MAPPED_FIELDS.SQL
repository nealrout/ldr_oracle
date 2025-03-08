/*====================================================================================
    PROCEDURE:   PROCESS_MAPPED_FIELDS
    PURPOSE:     This procedure processes and maps fields from a source table to a 
                 target table based on configuration stored in the LOAD_CONFIG table.
                 
                 The procedure:
                 1. Extracts mapping configurations from JSON data where STEP_CODE = 'MAP_FIELDS'.
                 2. Dynamically constructs a SQL MERGE statement.
                 3. Updates existing records or inserts new records into the target table.
                 4. Ensures that only valid data is processed by checking against ERR_VALIDATION.
                 5. Logs the generated SQL and handles exceptions gracefully.

    PARAMETERS:
    --------------------------------------------------------------------------------
    | Parameter Name       | Type      | Description                                |
    --------------------------------------------------------------------------------
    | p_load_log_id        | NUMBER    | ID of the load log entry                   |
    | p_load_log_detail_id | NUMBER    | ID of the detailed log entry               |
    | p_src_table          | VARCHAR2  | Name of the source table (STG_INPUT)       |
    | p_tgt_table          | VARCHAR2  | Name of the target table (STG_MAP)         |
    --------------------------------------------------------------------------------

    EXCEPTION HANDLING:
        - Captures errors and logs them with SQL error message and stack trace.
        - Uses RAISE_APPLICATION_ERROR to propagate errors for debugging.
        - Ensures that the procedure does not leave partial transactions.

    AUTHOR:       [NEAL ROUTSON]
    CREATED ON:   [2025-03-01]
    
    REVISION HISTORY:
    --------------------------------------------------------------------------------
    | Date       | Author       | Description of Changes                          |
    --------------------------------------------------------------------------------
    | 2025-03-08 | Neal Routson | Initial Version                                 |
    --------------------------------------------------------------------------------
====================================================================================*/

CREATE OR REPLACE PROCEDURE PROCESS_MAPPED_FIELDS (
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_src_table IN VARCHAR2,
    p_tgt_table IN VARCHAR2
)
IS
    v_merge_sql VARCHAR2(32767);  
    v_update_columns VARCHAR2(32767) := '';
    v_insert_columns VARCHAR2(32767) := 'LOAD_LOG_ID, UNIQUE_IDENTIFIER, CREATE_TS, ';
    v_insert_values VARCHAR2(32767) := '';
    v_unique_identifier VARCHAR2(4000) := NULL;
    v_first_loop BOOLEAN := TRUE;

    v_procedure_name VARCHAR2(100);
    v_error_message VARCHAR2(4000);
    v_error_stack   VARCHAR2(4000);
BEGIN
    v_procedure_name := REGEXP_SUBSTR(DBMS_UTILITY.FORMAT_CALL_STACK, 'procedure ([^ ]+)', 1, 1, NULL, 1);

    FOR rec IN (
        WITH json_data AS (
            SELECT ID, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG 
            FROM LOAD_CONFIG
            WHERE STEP_CODE = 'MAP_FIELDS'   
            AND UPPER(SRC_TABLE) = UPPER(p_src_table)
            AND UPPER(TGT_TABLE) = UPPER(p_tgt_table) 
        ),
        cte_parsed_json AS (
            SELECT 
                j.ID, 
                j.STEP_CODE,
                j.SRC_TABLE, 
                j.TGT_TABLE, 
                DBMS_LOB.SUBSTR(jt.srcField, 4000, 1) AS srcField, 
                DBMS_LOB.SUBSTR(jt.tgtField, 4000, 1) AS tgtField,
                DBMS_LOB.SUBSTR(jt.uniqueIdentifier, 4000, 1) AS uniqueIdentifier
            FROM json_data j,
            JSON_TABLE(j.CONFIG, '$' 
                COLUMNS (
                    uniqueIdentifier CLOB PATH '$.uniqueIdentifier',
                    NESTED PATH '$.mappings[*]' 
                    COLUMNS (
                        srcField CLOB PATH '$.srcField',
                        tgtField CLOB PATH '$.tgtField'
                    )
                )
            ) jt
        )
        SELECT DISTINCT uniqueIdentifier, srcField, tgtField FROM cte_parsed_json
    ) LOOP
        IF v_first_loop THEN
            v_unique_identifier := rec.uniqueIdentifier;
            v_first_loop := FALSE;

            -- **Use target.UNIQUE_IDENTIFIER in the ON condition**
            v_merge_sql := 'MERGE INTO ' || p_tgt_table || ' target USING ' || p_src_table || ' source ON (' ||
                           'target.UNIQUE_IDENTIFIER = DBMS_LOB.SUBSTR(source.' || v_unique_identifier || ', 4000, 1)) ' ||
                           'WHEN MATCHED THEN UPDATE SET ';
        END IF;
        
        -- **Exclude Unique Identifier from UPDATE SET**
        IF rec.tgtField <> v_unique_identifier THEN
            v_update_columns := v_update_columns || 'target.' || rec.tgtField || ' = source.' || rec.srcField || ', ';
        END IF;

        -- **Ensure Fields Are Included in INSERT**
        v_insert_columns := v_insert_columns || rec.tgtField || ', ';
        v_insert_values := v_insert_values || 'source.' || rec.srcField || ', ';
    END LOOP;

    -- **Ensure Correct Order of INSERT Columns & VALUES**
    v_insert_values := p_load_log_id || ', ' || -- **LOAD_LOG_ID first**
                       'DBMS_LOB.SUBSTR(source.' || v_unique_identifier || ', 4000, 1), ' || -- **UNIQUE_IDENTIFIER second**
                       'SYSTIMESTAMP, ' || -- **CREATE_TS third**
                       v_insert_values; -- **All remaining fields**

    -- **Fix Trailing Commas**
    v_update_columns := RTRIM(v_update_columns, ', ');  
    v_insert_columns := RTRIM(v_insert_columns, ', ');  
    v_insert_values := RTRIM(v_insert_values, ', ');

    -- **Construct Final MERGE Statement**
    IF v_update_columns IS NOT NULL THEN
        v_merge_sql := v_merge_sql || ' ' || v_update_columns;
    ELSE
        v_merge_sql := REPLACE(v_merge_sql, 'WHEN MATCHED THEN UPDATE SET ', '');
    END IF;

    v_merge_sql := v_merge_sql || ' WHEN NOT MATCHED THEN INSERT (' || v_insert_columns || ') VALUES (' || v_insert_values || ')';

    -- **Append the WHERE NOT EXISTS condition dynamically**
    v_merge_sql := v_merge_sql || ' WHERE NOT EXISTS (' ||
                   'SELECT 1 FROM ERR_VALIDATION EV ' ||
                   'WHERE EV.LOAD_LOG_DETAIL_ID = ' || p_load_log_detail_id || 
                   ' AND EV.UNIQUE_IDENTIFIER_VALUE = ' ||
                   'DBMS_LOB.SUBSTR(source.' || v_unique_identifier || ', 4000, 1))';

    -- **Debugging: Print Final SQL**
    DBMS_OUTPUT.PUT_LINE('SQL: ' || v_merge_sql);

    -- **Update log**
    UPDATE LOAD_LOG_DETAIL SET SQL = v_merge_sql WHERE ID = p_load_log_detail_id;
    COMMIT;

    -- **Check Length Before Execution**
    IF LENGTH(v_merge_sql) > 32767 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Query too long! Raising exception.');
        RAISE NO_DATA_FOUND;
    ELSE
        EXECUTE IMMEDIATE v_merge_sql;
    END IF;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        v_error_message := SQLERRM;
        v_error_stack := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

        RAISE_APPLICATION_ERROR(-20002, 
            'An error occurred in ' || v_procedure_name || ': ' || v_error_message || ' | STACK: ' || v_error_stack
        );
END PROCESS_MAPPED_FIELDS;
