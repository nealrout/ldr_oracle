CREATE OR REPLACE PROCEDURE VALIDATE_AND_INSERT_ERRORS (
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_src_table IN VARCHAR2,
    p_tgt_table IN VARCHAR2
) AS
    v_sql VARCHAR2(4000);
    v_unique_identifier VARCHAR2(4000);
    v_unique_identifier_value CLOB;
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
BEGIN
    -- **Step 1: Extract Validation Rules in One Query**
    SELECT DISTINCT 
        jt.uniqueIdentifier, jt.fieldName, jt.validation
    BULK COLLECT INTO v_validations
    FROM LOAD_CONFIG l,
         JSON_TABLE(l.CONFIG, '$' 
         COLUMNS (
            uniqueIdentifier CLOB PATH '$.uniqueIdentifier',
            NESTED PATH '$.validations[*]' 
            COLUMNS (
                fieldName VARCHAR2(255) PATH '$.fieldName',
                validation VARCHAR2(4000) PATH '$.validation'
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
        v_sql := 'SELECT ' || v_field_name || ', ' || v_unique_identifier || ', CREATE_TS
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
        -- **Error Handling: Rollback and Raise the Error**
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END VALIDATE_AND_INSERT_ERRORS;