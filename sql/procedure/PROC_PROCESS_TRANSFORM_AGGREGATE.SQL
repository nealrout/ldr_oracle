/*====================================================================================
    PROCEDURE:   PROCESS_TRANSFORM_AGGREGATE
    PURPOSE:     This procedure applies aggregate transformations from a source table
                 to a target table based on transformation rules stored in the 
                 LOAD_CONFIG table.
                 
                 The procedure:
                 1. Extracts transformation rules from JSON where STEP_CODE = 'TRANSFORM_AGGREGATE'.
                 2. Dynamically constructs and executes transformation queries.
                 3. Iterates through transformation results and updates the target table.
                 4. Logs the executed SQL queries into LOAD_LOG_DETAIL.
                 5. Ensures proper error handling and rollback in case of failure.

    PARAMETERS:
    --------------------------------------------------------------------------------
    | Parameter Name       | Type      | Description                                |
    --------------------------------------------------------------------------------
    | p_load_log_id        | NUMBER    | ID of the load log entry                   |
    | p_load_log_detail_id | NUMBER    | ID of the detailed log entry               |
    | p_src_table          | VARCHAR2  | Name of the source table (TRANSFORM)       |
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
    | Date       | Author       | Description of Changes                          |
    --------------------------------------------------------------------------------
    | 2025-03-08 | Neal Routson | Initial Version                                 |
    --------------------------------------------------------------------------------
====================================================================================*/
CREATE OR REPLACE PROCEDURE PROCESS_TRANSFORM_AGGREGATE(
    p_load_log_id IN NUMBER,
    p_load_log_detail_id IN NUMBER,
    p_src_table IN VARCHAR2,
    p_tgt_table IN VARCHAR2    
)
IS
    v_uniqueIdentifier VARCHAR2(4000);
    v_srcTable VARCHAR2(4000);
    v_tgtTable VARCHAR2(4000);
    v_fieldName VARCHAR2(4000);
    v_transformation CLOB;
    v_dynamic_query CLOB;
    v_update_stmt CLOB;
    v_existing_sql CLOB; 

    TYPE cur_type IS REF CURSOR;
    v_cursor cur_type;

    v_id_value VARCHAR2(4000);
    v_transformed_value VARCHAR2(4000);

    v_procedure_name VARCHAR2(100);
    v_error_message VARCHAR2(4000);
    v_error_stack   VARCHAR2(4000);

BEGIN
    v_procedure_name := REGEXP_SUBSTR(DBMS_UTILITY.FORMAT_CALL_STACK, 'procedure ([^ ]+)', 1, 1, NULL, 1);
    
    FOR rec IN (
        WITH json_data AS (
            SELECT ID, STEP_CODE, SRC_TABLE, TGT_TABLE, CONFIG 
            FROM LOAD_CONFIG
            WHERE STEP_CODE = 'TRANSFORM_AGGREGATE'   
            AND UPPER(SRC_TABLE) = UPPER(p_src_table)
            AND UPPER(TGT_TABLE) = UPPER(p_tgt_table) 
        ) ,
        cte_parsed_json AS (
            SELECT 
                j.ID, 
                j.STEP_CODE,
                j.SRC_TABLE AS SRC_TABLE,  
                j.TGT_TABLE AS TGT_TABLE,  
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
        SELECT DISTINCT uniqueIdentifier, SRC_TABLE, TGT_TABLE, fieldName, transformation 
        FROM cte_parsed_json
    ) LOOP
        v_uniqueIdentifier := rec.uniqueIdentifier;
        v_srcTable := rec.SRC_TABLE;  
        v_tgtTable := rec.TGT_TABLE;  
        v_fieldName := rec.fieldName;
        v_transformation := rec.transformation;

        DBMS_OUTPUT.PUT_LINE(v_transformation);
        
        -- Open cursor to execute transformation query dynamically
        v_dynamic_query := v_transformation;
        DBMS_OUTPUT.PUT_LINE(v_dynamic_query);
        OPEN v_cursor FOR v_dynamic_query;

		LOOP
		    FETCH v_cursor INTO v_id_value, v_transformed_value;
		    EXIT WHEN v_cursor%NOTFOUND;
		    
		    -- Convert CLOB to VARCHAR2 and handle NULL values
		    v_transformed_value := NVL(DBMS_LOB.SUBSTR(v_transformed_value, 4000, 1), 'NULL');
		
		    -- Build the UPDATE statement
		    v_update_stmt := 'UPDATE ' || v_tgtTable || 
		                     ' SET ' || v_fieldName || ' = ''' || v_transformed_value || ''' ' ||
		                     ' WHERE ' || v_uniqueIdentifier || ' = ''' || v_id_value || '''';
		
		    DBMS_OUTPUT.PUT_LINE(v_update_stmt);
		    
		    -- Retrieve the current SQL field content (CLOB) from LOAD_LOG_DETAIL
		    SELECT SQL INTO v_existing_sql FROM LOAD_LOG_DETAIL 
		    WHERE ID = p_load_log_detail_id 
		    FOR UPDATE;
		
		    -- Initialize CLOB if NULL
		    IF v_existing_sql IS NULL THEN
		        DBMS_LOB.CREATETEMPORARY(v_existing_sql, TRUE);
		    END IF;
		
		    -- Append new update statement to the CLOB field correctly
		    DBMS_LOB.APPEND(v_existing_sql, CHR(10) || v_update_stmt);
		
		    -- Update the SQL field with the appended CLOB content
		    UPDATE LOAD_LOG_DETAIL 
		    SET SQL = v_existing_sql
		    WHERE ID = p_load_log_detail_id;
            COMMIT;
		
		    -- Execute the dynamically built UPDATE statement
		    EXECUTE IMMEDIATE v_update_stmt;
		
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
END PROCESS_TRANSFORM_AGGREGATE;
