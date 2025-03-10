/*====================================================================================
    PROCEDURE:   VALIDATE_AND_INSERT_ERRORS
    PURPOSE:     This procedure validates data from a source table based on rules
                 stored in the LOAD_CONFIG table and inserts any failed records
                 into the ERR_VALIDATION table.
                 
                 The procedure:
                 1. Extracts validation rules from JSON where STEP_CODE = 'VALIDATE'.
                 2. Dynamically constructs SQL to check for validation failures.
                 3. Loops through invalid records and inserts them into ERR_VALIDATION.
                 4. Logs SQL executions for debugging and error tracking.
                 5. Commits changes to ensure error records are recorded properly.

    PARAMETERS:
    --------------------------------------------------------------------------------
    | Parameter Name       | Type      | Description                                |
    --------------------------------------------------------------------------------
    | p_load_log_id        | NUMBER    | ID of the load log entry                   |
    | p_load_log_detail_id | NUMBER    | ID of the detailed log entry               |
    | p_src_table          | VARCHAR2  | Name of the source table (STG_INPUT)       |
    | p_tgt_table          | VARCHAR2  | Name of the target table (ERR_VALIDATION)  |
    --------------------------------------------------------------------------------

    EXCEPTION HANDLING:
        - Captures errors and logs them with SQL error message and stack trace.
        - Uses RAISE_APPLICATION_ERROR to propagate errors for debugging.
        - Ensures that the procedure does not leave partial transactions.

    AUTHOR:       [NEAL ROUTSON]
    CREATED ON:   [2025-03-01]
    
    REVISION HISTORY:
    ---------------------------------------------------------------------------------
    | Date       | Author       | Description of Changes                            |
    ---------------------------------------------------------------------------------
    | 2025-03-08 | Neal Routson | Initial Version                                   |
    ---------------------------------------------------------------------------------
====================================================================================*/
CREATE OR REPLACE PROCEDURE VALIDATE_AND_INSERT_ERRORS (
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_src_table IN VARCHAR2,
    p_tgt_table IN VARCHAR2
) AS
    v_sql VARCHAR2(4000);
    v_unique_identifier VARCHAR2(4000);
    v_unique_identifier_value VARCHAR2(4000);
    v_field_name VARCHAR2(255);
    v_validation VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
    
    TYPE rec_type IS RECORD (
        unique_identifier VARCHAR2(4000),
        field_name VARCHAR2(255),
        validation VARCHAR2(4000)
    );
    
    TYPE rec_table IS TABLE OF rec_type;
    v_validations rec_table;
    
    v_field_value VARCHAR2(4000);
    v_create_ts TIMESTAMP;

    v_procedure_name VARCHAR2(100);
    v_error_message VARCHAR2(4000);
    v_error_stack   VARCHAR2(4000);
BEGIN
    v_procedure_name := REGEXP_SUBSTR(DBMS_UTILITY.FORMAT_CALL_STACK, 'procedure ([^ ]+)', 1, 1, NULL, 1);

    SELECT DISTINCT 
        DBMS_LOB.SUBSTR(jt.uniqueIdentifier, 4000, 1), 
        DBMS_LOB.SUBSTR(jt.fieldName, 4000, 1), 
        DBMS_LOB.SUBSTR(jt.validation, 4000, 1)
    BULK COLLECT INTO v_validations
    FROM LOAD_CONFIG l,
         JSON_TABLE(l.CONFIG, '$' 
         COLUMNS (
            uniqueIdentifier CLOB PATH '$.uniqueIdentifier',
            NESTED PATH '$.validations[*]' 
            COLUMNS (
                fieldName CLOB PATH '$.fieldName',
                validation CLOB PATH '$.validation'
            )
         )) jt
    WHERE l.STEP_CODE = 'VALIDATE' 
      AND UPPER(SRC_TABLE) = UPPER(p_src_table) 
      AND UPPER(TGT_TABLE) = UPPER(p_tgt_table);

    -- **Step 2: Loop through validation rules**
    FOR i IN 1..v_validations.COUNT LOOP
        v_unique_identifier := v_validations(i).unique_identifier;
        v_field_name := v_validations(i).field_name;
        v_validation := v_validations(i).validation;

        -- **Replace STATIC_FIELD_NAME dynamically**
        v_validation := REPLACE(v_validation, 'STATIC_FIELD_NAME', v_field_name);

        -- **Step 3: Construct dynamic SQL to find invalid records**
        v_sql := 'SELECT DBMS_LOB.SUBSTR(' || v_field_name || ', 4000, 1), ' || 
                         'DBMS_LOB.SUBSTR(' || v_unique_identifier || ', 4000, 1), CREATE_TS
                  FROM ' || p_src_table || ' 
                  WHERE NOT (' || v_validation || ')';

        OPEN v_cursor FOR v_sql;
        
        LOOP
            FETCH v_cursor INTO v_field_value, v_unique_identifier_value, v_create_ts;
            EXIT WHEN v_cursor%NOTFOUND;

            -- **Step 4: Insert failed record into ERR_VALIDATION**
            INSERT INTO ERR_VALIDATION (
                LOAD_LOG_ID, LOAD_LOG_DETAIL_ID, SRC_TABLE, TGT_TABLE, UNIQUE_IDENTIFIER, UNIQUE_IDENTIFIER_VALUE,
                FIELD_NAME, VALIDATION, FIELD_VALUE, ERROR_CODE, ERROR_MESSAGE, CREATE_TS
            ) VALUES (
                p_load_log_id, p_load_log_detail_id, p_src_table, p_tgt_table, 
                v_unique_identifier, v_unique_identifier_value,
                v_field_name, v_validation, v_field_value, 
                'VALIDATION_ERROR', 'Validation Failed', v_create_ts
            );
        END LOOP;

        CLOSE v_cursor;
    END LOOP;
    
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        v_error_message := SQLERRM;
        v_error_stack := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;

        RAISE_APPLICATION_ERROR(-20002, 
            'An error occurred in ' || v_procedure_name || ': ' || v_error_message || ' | STACK: ' || v_error_stack
        );
END VALIDATE_AND_INSERT_ERRORS;
