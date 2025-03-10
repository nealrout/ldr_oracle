/*====================================================================================
    PROCEDURE:   PROCESS_TRANSFORM_INLINE
    PURPOSE:     This procedure applies inline transformations from a source table
                 to a target table based on transformation rules stored in the 
                 LOAD_CONFIG table.
                 
                 The procedure:
                 1. Extracts transformation rules from JSON where STEP_CODE = 'TRANSFORM_INLINE'.
                 2. Dynamically constructs a SQL MERGE statement to apply transformations.
                 3. Updates existing records if a match is found based on UNIQUE_IDENTIFIER.
                 4. Inserts new records if no match is found.
                 5. Logs the executed SQL queries into LOAD_LOG_DETAIL.
                 6. Ensures proper error handling and rollback in case of failure.

    PARAMETERS:
    --------------------------------------------------------------------------------
    | Parameter Name       | Type      | Description                                |
    --------------------------------------------------------------------------------
    | p_load_log_id        | NUMBER    | ID of the load log entry                   |
    | p_load_log_detail_id | NUMBER    | ID of the detailed log entry               |
    | p_src_table          | VARCHAR2  | Name of the source table (STG_MAP)         |
    | p_tgt_table          | VARCHAR2  | Name of the target table (TRANSFORM)       |
    --------------------------------------------------------------------------------

    EXCEPTION HANDLING:
        - Captures errors and logs them with SQL error message and stack trace.
        - Uses RAISE_APPLICATION_ERROR to propagate errors for debugging.
        - Ensures that the procedure does not leave partial transactions.

    AUTHOR:       [NEAL ROUTSON]
    CREATED ON:   [2025-03-01]
    
    REVISION HISTORY:
    --------------------------------------------------------------------------------
    | Date       | Author       | Description of Changes                           |
    --------------------------------------------------------------------------------
    | 2025-03-08 | Neal Routson | Initial Version                                  |
    --------------------------------------------------------------------------------
====================================================================================*/

CREATE OR REPLACE PROCEDURE PROCESS_TRANSFORM_INLINE (
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_src_table IN VARCHAR2,
    p_tgt_table IN VARCHAR2
)
IS
    v_merge_sql VARCHAR2(32767);  
    v_update_columns VARCHAR2(32767) := '';
    v_insert_columns VARCHAR2(32767) := 'LOAD_LOG_ID, CREATE_TS, ';
    v_insert_values VARCHAR2(32767) := p_load_log_id || ', SYSTIMESTAMP, ';
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
            WHERE STEP_CODE = 'TRANSFORM_INLINE'   
            AND UPPER(SRC_TABLE) = UPPER(p_src_table)
            AND UPPER(TGT_TABLE) = UPPER(p_tgt_table) 
        ),
        cte_parsed_json AS (
            SELECT 
                j.ID, 
                j.STEP_CODE,
                j.SRC_TABLE, 
                j.TGT_TABLE, 
                DBMS_LOB.SUBSTR(jt.fieldName, 4000, 1) AS fieldName, 
                DBMS_LOB.SUBSTR(jt.transformation, 4000, 1) AS transformation,
                DBMS_LOB.SUBSTR(jt.uniqueIdentifier, 4000, 1) AS uniqueIdentifier
            FROM json_data j,
            JSON_TABLE(j.CONFIG, '$' 
                COLUMNS (
                    uniqueIdentifier CLOB PATH '$.uniqueIdentifier',
                    NESTED PATH '$.transformations[*]' 
                    COLUMNS (
                        fieldName CLOB PATH '$.fieldName',
                        transformation CLOB PATH '$.transformation'
                    )
                )
            ) jt
        )
        SELECT DISTINCT uniqueIdentifier, fieldName, transformation FROM cte_parsed_json
    ) LOOP
        -- Assign unique identifier **only once** in the first iteration
        IF v_first_loop THEN
            v_unique_identifier := rec.uniqueIdentifier;
            v_first_loop := FALSE;

            -- **Initialize v_merge_sql only once**
            v_merge_sql := 'MERGE INTO ' || p_tgt_table || ' target USING ' || p_src_table || ' source '||
            	'ON (target.UNIQUE_IDENTIFIER = source.UNIQUE_IDENTIFIER) ' ||
				'WHEN MATCHED THEN UPDATE SET ';
        END IF;
        
        -- **Replace "STATIC_FIELD_NAME" with actual column name**
        DECLARE
            v_actual_transformation VARCHAR2(4000);
        BEGIN
            v_actual_transformation := REPLACE(rec.transformation, 'STATIC_FIELD_NAME', 'source.' || rec.fieldName);

            v_update_columns := v_update_columns || 'target.' || rec.fieldName || ' = ' || v_actual_transformation || ', ';

            -- **Ensure field is included in INSERT**
            v_insert_columns := v_insert_columns || rec.fieldName || ', ';
            v_insert_values := v_insert_values || v_actual_transformation || ', ';
            
            -- ADD UNIQUE_IDENTIFIER TO INSERT WITH A TRANSFORMATION IF THERE IS ONE.
            IF rec.fieldName = v_unique_identifier THEN
            	v_insert_columns := v_insert_columns || 'UNIQUE_IDENTIFIER' || ', ' ;
            	v_insert_values := v_insert_values || v_actual_transformation || ', ';
            END IF;
            
        END;
    END LOOP;

    -- **Fix trailing commas**
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
        COMMIT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        v_error_message := SQLERRM;
        v_error_stack := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

        RAISE_APPLICATION_ERROR(-20002, 
            'An error occurred in ' || v_procedure_name || ': ' || v_error_message || ' | STACK: ' || v_error_stack
        );
END PROCESS_TRANSFORM_INLINE;
