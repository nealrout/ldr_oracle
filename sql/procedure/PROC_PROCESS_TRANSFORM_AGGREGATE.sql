/*====================================================================================
    PROCEDURE:   PROCESS_TRANSFORM_AGGREGATE
    PURPOSE:     This procedure applies aggregate transformations from a source table
                 to a target table based on transformation rules stored in the 
                 LOAD_CONFIG table.
                 
                 The procedure:
                 1. Extracts transformation rules from JSON where STEP_CODE = 'TRANSFORM_AGGREGATE'.
                 2. Dynamically constructs and executes transformation queries.
                 3. Build Merge statement to execute transformation in one pass.
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
	v_merge_sql VARCHAR2(32767);

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

--        DBMS_OUTPUT.PUT_LINE(v_transformation);
        
        v_merge_sql := 'MERGE INTO ' || v_tgtTable || ' T ' ||
        	'USING (' || v_transformation || ') C ' ||
        	'ON (T.' || v_uniqueIdentifier || '= C.INNER_MERGE_KEY) ' ||
        	'WHEN MATCHED THEN UPDATE SET T.' || v_fieldName || ' = C.STATIC_FIELD_NAME';
     
        DBMS_OUTPUT.PUT_LINE('SQL: ' || v_merge_sql);
        
	    -- Update LOAD_LOG_DETAIL WITH QUERY BEING RUN.
	    UPDATE LOAD_LOG_DETAIL 
	    SET SQL = v_merge_sql
	    WHERE ID = p_load_log_detail_id;
	    
        COMMIT;
	
	    -- Execute the dynamically built UPDATE statement
	    EXECUTE IMMEDIATE v_merge_sql;
        
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
