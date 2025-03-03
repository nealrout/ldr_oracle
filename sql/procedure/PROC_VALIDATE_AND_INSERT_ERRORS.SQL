CREATE OR REPLACE PROCEDURE VALIDATE_AND_INSERT_ERRORS (
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_src_table IN VARCHAR2,
    p_tgt_table IN VARCHAR2
) AS
    v_sql VARCHAR2(4000);
    v_fieldname VARCHAR2(255);
    v_validation VARCHAR2(4000);
    v_cursor SYS_REFCURSOR;
    
    TYPE rec_type IS RECORD (
        field_name VARCHAR2(255),
        validation VARCHAR2(4000)
    );
    
    TYPE rec_table IS TABLE OF rec_type;
    v_validations rec_table;
    
    v_field_value VARCHAR2(4000);
    v_create_ts TIMESTAMP;
    
BEGIN
    -- Extract validation rules from CONFIG dynamically
    SELECT FIELDNAME, VALIDATION 
    BULK COLLECT INTO v_validations
    FROM (
        SELECT jt.FIELDNAME, jt.VALIDATION
        FROM LOAD_CONFIG l,
        JSON_TABLE(l.CONFIG, '$' 
            COLUMNS (
                NESTED PATH '$.validations[*]' 
                COLUMNS (
                    FIELDNAME VARCHAR2(255) PATH '$.fieldName',
                    VALIDATION VARCHAR2(4000) PATH '$.validation'
                )
            )
        ) jt
        WHERE l.STEP_CODE = 'VALIDATE'
    );

    -- Loop through each validation rule and apply it
    FOR i IN 1..v_validations.COUNT LOOP
        v_fieldname := v_validations(i).field_name;
        v_validation := v_validations(i).validation;
        
        -- Construct dynamic SQL to find invalid records
        v_sql := 'SELECT ' || v_fieldname || ', CREATE_TS
                  FROM ' || p_src_table || ' 
                  WHERE NOT (' || v_validation || ')';
        
        OPEN v_cursor FOR v_sql;
        
        LOOP
            FETCH v_cursor INTO v_field_value, v_create_ts;
            EXIT WHEN v_cursor%NOTFOUND;
        
            -- Insert failed record into ERR_VALIDATION
            INSERT INTO ERR_VALIDATION (
                LOAD_LOG_ID, LOAD_LOG_DETAIL_ID, SRC_TABLE, TGT_TABLE, 
                FIELD_NAME, VALIDATION, FIELD_VALUE, ERROR_CODE, ERROR_MESSAGE, CREATE_TS
            ) VALUES (
                p_load_log_id, p_load_log_detail_id, p_src_table, p_tgt_table, 
                v_fieldname, v_validation, v_field_value, 
                'ERROR_CODE', 'Validation Failed', v_create_ts
            );
        END LOOP;
        
        CLOSE v_cursor;
    END LOOP;
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Error handling
        ROLLBACK;
        RAISE;
END VALIDATE_AND_INSERT_ERRORS;
